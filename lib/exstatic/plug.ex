defmodule ExStatic.Plug do
  @moduledoc """
  A plug for serving static assets from exstatic-compiled BEAM files.

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

  defmodule InvalidPathError do
    defexception message: "invalid path for static asset", plug_status: 400
  end

  def init(opts) do
    at    = Keyword.fetch!(opts, :at)
    only  = Keyword.get(opts, :only, nil)
    gzip  = Keyword.get(opts, :gzip, false)
    {Plug.Router.Utils.split(at), gzip, only}
  end

  def call(conn = %Conn{method: meth}, {at, gzip, only})
  when meth in @allowed_methods do
    # subset/2 returns the segments in `conn.path_info` without the
    # segments at the beginning that are shared with `at`.
    segments = subset(at, conn.path_info) |> Enum.map(&URI.decode/1)

    cond do
      not allowed?(only, segments) ->
        conn
      invalid_path?(segments) ->
        raise InvalidPathError
      true ->
        filepath = segments |> Path.join
        serve_static(conn, filepath)
    end
    end

  def call(conn, _opts) do
    conn
  end

  defp allowed?(_only, []),   do: false
  defp allowed?(nil, _list),  do: true
  defp allowed?(only, [h|_]), do: h in only

  defp serve_static(conn, filepath) do
    conn
    |> put_resp_header("content-type", "text/html") # ExStatic.content_type(filepath))
    |> put_resp_header("content-length", Integer.to_string(ExStatic.size(filepath)))
    |> put_resp_header("x-static", "true")
    |> resp(200, ExStatic.contents(filepath))
    |> halt
  end

  defp serve_static({:error, conn}, _segments, _qs_cache, _et_cache) do
    conn
  end

  defp invalid_path?([h|_]) when h in [".", "..", ""], do: true
  defp invalid_path?([h|t]), do: String.contains?(h, ["/", "\\", ":"]) or invalid_path?(t)
  defp invalid_path?([]), do: false

  defp subset([h|expected], [h|actual]),
  do: subset(expected, actual)
  defp subset([], actual),
  do: actual
  defp subset(_, _),
  do: []
  
end
