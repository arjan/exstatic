defmodule Mix.Tasks.Exstatic.Compile do
  use Mix.Task

  @default_input_path "priv/static"
  
  @shortdoc "Compiles static files into Erlang code"

  @moduledoc """

  """
  def run(args) do
    input_path  = List.first(args) || @default_input_path
    :ok = ExStatic.compile_all(input_path)
  end

end
