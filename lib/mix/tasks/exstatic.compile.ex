defmodule Mix.Tasks.Exstatic.Compile do
  use Mix.Task

  @default_input_path "priv/static"
  
  @shortdoc "Compiles static files into Erlang code"

  @moduledoc """

  """
  def run(args) do
    input_path  = List.first(args) || @default_input_path
    case ExStatic.Compiler.compile_all(input_path) do
      :ok -> :ok
      {:error, :invalid_path} ->
        Kernel.raise Mix.Error, mix: true, message: "Invalid / non-existing static path"
    end
  end

end
