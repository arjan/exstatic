defmodule ExStatic.Plug do
  @moduledoc """
  A plug for serving static assets from in-memory BEAM bytecode

  It has two options on initialization:

  * `module:` - the module with the statically compiled files (`use ExStatic`); required
  * `:at` - the request path to reach for static assets.
  It must be a string. Defaults to "/"

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

  """

  @behaviour Plug
  @allowed_methods ~w(GET HEAD)

  import Plug.Conn
  alias Plug.Conn

  def init(opts) do
    at = opts[:at] || "/"
    module = Keyword.fetch!(opts, :module)
    gzip  = Keyword.get(opts, :gzip, true)

    qs_cache = Keyword.get(opts, :cache_control_for_vsn_requests, "public, max-age=31536000")
    et_cache = Keyword.get(opts, :cache_control_for_etags, "public")

    {Plug.Router.Utils.split(at), module, gzip, qs_cache, et_cache}
  end

  def call(conn = %Conn{method: meth}, {at, module, gzip, qs_cache, et_cache}) when meth in @allowed_methods do
    segments = subset(at, conn.path_info) |> Enum.map(&URI.decode/1)
    case segments do
      [] -> conn
      _ ->
        filepath = segments |> Path.join
        case module.exists?(filepath) do
          true ->
            serve_static(conn, module, filepath, gzip, qs_cache, et_cache)
          false ->
            conn
        end
    end
  end

  def call(conn, _opts) do
    conn
  end

  defp serve_static(conn, module, filepath, gzip, qs_cache, et_cache) do
    case put_cache_header(conn, module, qs_cache, et_cache, filepath) do
      {:stale, conn} ->
        content_type = module.content_type(filepath)

        conn
        |> put_resp_header("content-type", content_type)
        |> put_resp_header("x-static", "true")
        |> serve_content(module, filepath, gzip && gzip?(conn))
        |> halt
      {:fresh, conn} ->
        conn
        |> send_resp(304, "")
        |> halt
    end
  end

  defp serve_content(conn, module, filepath, false) do
    conn
    |> put_resp_header("content-length", Integer.to_string(module.size(filepath)))
    |> resp(200, module.contents(filepath))
  end

  defp serve_content(conn, module, filepath, true) do
    conn
    |> put_resp_header("content-encoding", "gzip")
    |> put_resp_header("content-length", Integer.to_string(module.gzip_size(filepath)))
    |> resp(200, module.gzip_contents(filepath))
  end

  defp put_cache_header(%Conn{query_string: "vsn=" <> _} = conn, _module, qs_cache, _et_cache, _filepath)
  when is_binary(qs_cache) do
    {:stale, put_resp_header(conn, "cache-control", qs_cache)}
  end

  defp put_cache_header(conn, module, _qs_cache, et_cache, filepath) when is_binary(et_cache) do
    etag = etag_for_path(module, filepath)

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

  defp etag_for_path(module, filepath) do
    size = module.size(filepath)
    mtime = module.mtime(filepath)
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
