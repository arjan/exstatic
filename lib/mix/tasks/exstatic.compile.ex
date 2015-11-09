defmodule Mix.Tasks.Exstatic.Compile do
  use Mix.Task

  @default_input_path "priv/static"
  
  @shortdoc "Compiles static files into Erlang code"

  @moduledoc """

  """
  def run(args) do
    input_path  = List.first(args) || @default_input_path
    case ExStatic.Compiler.compile_all(input_path) do
      {:ok, count} ->
        Mix.shell.info "Compiled #{count} static files in #{input_path} to bytecode"
        :ok
      {:error, :invalid_path} ->
        Mix.raise "Invalid static path: #{input_path}"
    end
  end

end
