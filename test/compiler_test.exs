defmodule ExStatic.Test.Compiler do
  use ExUnit.Case

  test "basic compilation" do
    # compile it
    {:ok, m, c} = ExStatic.Compiler.compile(basedir, "test.html")

    # load it
    {:module, ^m} = :code.load_binary(m, String.to_char_list("test.html"), c)

    # check contents
    contents = File.read!(Path.join(basedir, "test.html"))
    assert {:ok, ^contents} = ExStatic.contents("test.html")
    assert ^contents = ExStatic.contents!("test.html")

    # check size
    size = String.length(contents)
    assert {:ok, ^size} = ExStatic.size("test.html")
    assert ^size = ExStatic.size!("test.html")

    # check gzip
    gzip_contents = :zlib.gzip(contents)
    assert {:ok, ^gzip_contents} = ExStatic.gzip_contents("test.html")
    assert ^gzip_contents = ExStatic.gzip_contents!("test.html")

    # check gzip size
    size = String.length(gzip_contents)
    assert {:ok, ^size} = ExStatic.gzip_size("test.html")
    assert ^size = ExStatic.gzip_size!("test.html")
    
  end

  test "write compiled beam file and accessor methods" do
    :ok = ExStatic.Compiler.compile_to_disk(basedir, "test2.html")

    assert true = ExStatic.exists?("test2.html")

    assert "<h3>hello</h3>\n" = ExStatic.contents!("test2.html")

    assert "text/html" = ExStatic.content_type!("test2.html")
    assert ExStatic.ctime!("test2.html") > 0
    assert ExStatic.mtime!("test2.html") > 0

  end

  test "proper errors" do 
    assert {:error, :nofile, _} = ExStatic.contents("alkdsfjlkdsjflds.html")
    assert {:error, :nofile, _} = ExStatic.size("alkdsfjlkdsjflds.html")
  end

  defp basedir do
    Path.expand("fixtures", __DIR__)
  end
  
end
