defmodule ExStatic.Test.Mix do
  use ExUnit.Case

  test "mix exstatic.compile" do
    assert :ok = Mix.Tasks.Exstatic.Compile.run(["test/fixtures/priv"])
  end

  test "mix exstatic.compile with invalid path" do
    assert %Mix.Error{} = catch_error(Mix.Tasks.Exstatic.Compile.run(["un/existing/path"]))
  end
  
end
