defmodule ExStatic.Plug do
  @moduledoc """
  A plug for serving static assets from in-memory BEAM bytecode

  It requires two options on initialization:

    * `:at` - the request path to reach for static assets.
      It must be a string.

  If a static asset cannot be found, `Plug.Static` simply forwards
  the connection to the rest of the pipeline.

  ## Cache mechanisms

  `Plug.Static` uses etags for HTTP caching. This means browsers/clients
  should cache assets on the first request and validate the cache on
  following requests, not downloading the static asset once again if it
  has not changed. The cache-control for etags is specified by the
  `cache_control_for_etags` option and defaults to "public".

  However, `Plug.Static` also support direct cache control by using
  versioned query strings. If the request query string starts with
  "?vsn=", `Plug.Static` assumes the application is versioning assets
  and does not set the `ETag` header, meaning the cache behaviour will
  be specified solely by the `cache_control_for_vsn_requests` config,
  which defaults to "public, max-age=31536000".

  ## Options

    * `:gzip` - given a request for `FILE`, serves `FILE.gz` if it exists
      in the static directory and if the `accept-encoding` ehader is set
      to allow gzipped content (defaults to `false`)

    * `:cache_control_for_etags` - sets cache header for requests
      that use etags. Defaults to "public".

    * `:cache_control_for_vsn_requests` - sets cache header for requests
      starting with "?vsn=" in the query string. Defaults to
      "public, max-age=31536000"

    * `:only` - filter which paths to lookup. This is useful to avoid
      file system traversals on every request when the plug is mounted
      at "/"

  ## Examples

  This plug can be mounted in a `Plug.Builder` pipeline as follow:

      defmodule MyPlug do
        use Plug.Builder

        plug ExStatic.Plug, at: "/public"
        plug :not_found

        def not_found(conn, _) do
          Plug.Conn.send_resp(conn, 404, "not found")
        end
      end

  """

  @behaviour Plug
  @allowed_methods ~w(GET HEAD)

  import Plug.Conn
  alias Plug.Conn

  require Record
  Record.defrecordp :file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl")

  defmodule InvalidPathError do
    defexception message: "invalid path for static asset", plug_status: 400
  end

  def init(opts) do
    at    = Keyword.fetch!(opts, :at)
    gzip  = Keyword.get(opts, :gzip, true)
    only  = Keyword.get(opts, :only, nil)

    qs_cache = Keyword.get(opts, :cache_control_for_vsn_requests, "public, max-age=31536000")
    et_cache = Keyword.get(opts, :cache_control_for_etags, "public")

    {Plug.Router.Utils.split(at), gzip, qs_cache, et_cache, only}
  end

  def call(conn = %Conn{method: meth}, {at, gzip, qs_cache, et_cache, only})
      when meth in @allowed_methods do
    # subset/2 returns the segments in `conn.path_info` without the
    # segments at the beginning that are shared with `at`.
    segments = subset(at, conn.path_info) |> Enum.map(&URI.decode/1)

    cond do
      not allowed?(only, segments) ->
        conn
      true ->
        filepath = segments |> Path.join
        serve_static(conn, ExStatic.exists?(filepath), filepath, gzip, qs_cache, et_cache)
    end
  end

  def call(conn, _opts) do
    conn
  end

  defp allowed?(_only, []),   do: false
  defp allowed?(nil, _list),  do: true
  defp allowed?(only, [h|_]), do: h in only
  
  defp serve_static(conn, true, filepath, gzip, qs_cache, et_cache) do
    case put_cache_header(conn, qs_cache, et_cache, file_info) do
      {:stale, conn} ->
        content_type = ExStatic.content_type(filepath)

        conn
        |> put_resp_header("content-type", content_type)
        |> put_resp_header("x-static", "true")
        |> serve_content(filepath, gzip && gzip?(conn))
        |> halt
      {:fresh, conn} ->
        conn
        |> send_resp(304, "")
        |> halt
    end
  end

  defp serve_static(conn, {:error, :nofile, _}, _filepath, _gzip, _qs_cache, _et_cache) do
    conn
  end
  
  defp serve_content(conn, filepath, false) do
    conn
    |> put_resp_header("content-length", Integer.to_string(ExStatic.size(filepath)))
    |> resp(200, ExStatic.contents(filepath))
  end

  defp serve_content(conn, filepath, true) do
    conn
    |> put_resp_header("content-encoding", "gzip")
    |> put_resp_header("content-length", Integer.to_string(ExStatic.gzip_size(filepath)))
    |> resp(200, ExStatic.gzip_contents(filepath))
  end

  defp put_cache_header(%Conn{query_string: "vsn=" <> _} = conn, qs_cache, _et_cache, _file_info)
      when is_binary(qs_cache) do
    {:stale, put_resp_header(conn, "cache-control", qs_cache)}
  end

  defp put_cache_header(conn, _qs_cache, et_cache, filepath) when is_binary(et_cache) do
    etag = etag_for_path(filepath)

    conn =
      conn
      |> put_resp_header("cache-control", et_cache)
      |> put_resp_header("etag", etag)

    if etag in get_req_header(conn, "if-none-match") do
      {:fresh, conn}
    else
      {:stale, conn}
    end
  end

  defp put_cache_header(conn, _, _, _) do
    {:stale, conn}
  end

  defp etag_for_path(filepath) do
    size = ExStatic.size(filepath)
    mtime = ExStatic.mtime(filepath)
    {size, mtime} |> :erlang.phash2() |> Integer.to_string(16)
  end

  defp gzip?(conn) do
    gzip_header? = &String.contains?(&1, ["gzip", "*"])
    Enum.any? get_req_header(conn, "accept-encoding"), fn accept ->
      accept |> Plug.Conn.Utils.list() |> Enum.any?(gzip_header?)
    end
  end

  defp subset([h|expected], [h|actual]),
    do: subset(expected, actual)
  defp subset([], actual),
    do: actual
  defp subset(_, _),
    do: []

end
