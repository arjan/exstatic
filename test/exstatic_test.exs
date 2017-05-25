defmodule ExStatic.Test.Compiler do
  use ExUnit.Case

  defmodule StaticFiles do
    use ExStatic, path: "fixtures/"
  end

  test "generate accessors" do
    contents = File.read!("./test/fixtures/test.html")
    gzip_contents = :zlib.gzip(contents)

    assert StaticFiles.exists?("test.html")
    assert StaticFiles.contents("test.html") == contents
    assert StaticFiles.size("test.html") == String.length(contents)
    assert StaticFiles.gzip_contents("test.html") == gzip_contents
    assert StaticFiles.gzip_size("test.html") == String.length(gzip_contents)
    assert StaticFiles.content_type("test.html") == "text/html"
    assert %DateTime{} = StaticFiles.mtime("test.html")

  end

end
