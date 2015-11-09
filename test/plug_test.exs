defmodule ExStatic.Test.Plug do
  use ExUnit.Case
  use Plug.Test

  setup do
    Mix.Tasks.Exstatic.Compile.run(["test/fixtures/priv"])
  end    

  test "Pass through non-existing files" do
    conn = conn(:get, "/doesnotexist")
    assert ^conn = serve(conn, [at: "/"])
  end

  test "Pass through invalid req method POST" do
    conn = conn(:post, "/a.html")
    assert ^conn = serve(conn, [at: "/"])
  end

  test "Pass through when serve at wrong path" do
    conn = conn(:get, "/a.html")
    assert ^conn = serve(conn, [at: "/foo"])
  end

  test "Serve valid file" do
    conn = conn(:get, "/a.html")
    conn = serve(conn, [at: "/"])
    assert 200 = conn.status
    assert "text/html" = conn |> header("content-type")
    assert "2" = conn |> header("content-length")
    assert "true" = conn |> header("x-static")
  end

  test "Serve valid file w/ HEAD request" do
    conn = conn(:head, "/a.html")
    conn = serve(conn, [at: "/"])
    assert 200 = conn.status
  end

  test "Serve file at other path" do
    conn = conn(:get, "/foo/a.html")
    conn = serve(conn, [at: "/foo/"])
    assert 200 = conn.status
  end

  test "Serve valid file gzipped" do
    conn = conn(:get, "/a.html") |> put_req_header("accept-encoding", "gzip")
    conn = serve(conn, [at: "/"])
    assert 200 = conn.status
    assert "text/html" = conn |> header("content-type")
    assert "gzip" = conn |> header("content-encoding")
    assert "22" = conn |> header("content-length")
    assert "true" = conn |> header("x-static")
  end

  test "Serve normal file when requesting gzip but configured not to serve gzip" do
    conn = conn(:get, "/a.html") |> put_req_header("accept-encoding", "gzip")
    conn = serve(conn, [at: "/", gzip: false])
    assert 200 = conn.status
    assert :undefined = conn |> header("content-encoding")
    assert "2" = conn |> header("content-length")
  end

  test "Serve file with Etag caching" do
    # do one request to get the etag
    etag = serve(conn(:get, "/a.html"), [at: "/"]) |> header("etag")

    # send with header to check if server returns the 304
    conn = conn(:get, "/a.html") |> put_req_header("if-none-match", etag)
    conn = serve(conn, [at: "/"])
    assert 304 = conn.status
  end
  
  defp serve(conn, opts) do
    ExStatic.Plug.call(conn, ExStatic.Plug.init(opts))
  end

  def header(conn, k) do
    :proplists.get_value(k, conn.resp_headers)
  end

end
