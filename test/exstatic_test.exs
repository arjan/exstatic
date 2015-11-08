defmodule ExStaticTest do
  use ExUnit.Case

  test "basic compilation" do
    # compile it
    {:ok, m, c} = ExStatic.Compiler.compile(basedir, "test.html")

    # load it
    {:module, ^m} = :code.load_binary(m, String.to_char_list("test.html"), c)

    # check contents
    contents = File.read!(Path.join(basedir, "test.html"))
    assert ^contents = ExStatic.contents("test.html")

    # check size
    size = String.length(contents)
    assert ^size = ExStatic.size("test.html")

    # check gzip
    gzip_contents = :zlib.gzip(contents)
    assert ^gzip_contents = ExStatic.gzip_contents("test.html")

    # check gzip size
    size = String.length(gzip_contents)
    assert ^size = ExStatic.gzip_size("test.html")
    
  end

  test "write compiled beam file" do
    :ok = ExStatic.Compiler.compile_to_disk(basedir, "test2.html")

    assert "<h3>hello</h3>\n" = ExStatic.contents("test2.html")

    ## FIXME assert "text/html" = ExStatic.content_type("test2.html")
  end

  test "proper errors" do 
    assert {:error, :nofile} = ExStatic.contents("alkdsfjlkdsjflds.html")
    assert {:error, :nofile} = ExStatic.size("alkdsfjlkdsjflds.html")
  end

  test "mix exstatic.compile" do
    Mix.Tasks.Exstatic.Compile.run(["test/fixtures/priv"])
  end
  
  defp basedir do
    Path.expand("fixtures", __DIR__)
  end
  
end
