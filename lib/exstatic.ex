defmodule ExStatic do

  def contents(filepath) do
    try do
      String.to_existing_atom(modulename(filepath)).contents()
    rescue
      ArgumentError -> {:error, :nofile}
    end
  end

  def size(filepath) do
    try do 
      String.to_existing_atom(modulename(filepath)).size()
    rescue
      ArgumentError -> {:error, :nofile}
    end
  end

  def compile_all(input_path) do
    if File.exists?(input_path) do

      input_path
      |> filter_files
      |> Enum.map(fn(f) -> :ok = compile_to_disk(input_path, f) end)
      :ok
    else
      {:error, :invalid_path}
    end
  end

  defp filter_files(input_path) do
    input_path
    |> Path.join("**")
    |> Path.wildcard
    |> Enum.filter(&(!File.dir?(&1)))
    |> Enum.map(&(Path.relative_to(&1, input_path)))
    #    |> Enum.map(&(map_file(&1, input_path)))
  end

  
  def compile_to_disk(basedir, filepath) do
    {:ok, _m, c} = ExStatic.compile(basedir, filepath)
    beamfile = modulename(filepath) <> ".beam"
    :ok = File.write!(hd(Mix.Project.load_paths) |> Path.join(beamfile), c)

    # also make it available in current runtime
    {:module, _} = :code.load_file(modulename(filepath) |> String.to_atom)
    :ok
  end    
  
  def compile(basedir, filepath) do
    contents = Path.join(basedir, filepath) |> File.read!
    modname = modulename(filepath) |> String.to_atom

    f = forms(modname, contents)
    :compile.forms(f)
  end
  
  defp scan({:done,{:ok,t,n},s},res) do
    scan(:erl_scan.tokens([],s,n),[t|res])
  end

  defp scan(_,res) do
    :lists.reverse(res)
  end

  defp modulename(filepath) do
    "ExStatic.Compiled." <> (:crypto.hash(:sha, filepath) |> Base.encode32)
  end

  defp forms(modname, contents) do
    size = String.length(contents)
    [{:attribute, 1, :module, modname},
     {:attribute, 3, :export, [contents: 0, size: 0]},
     {:function, 5, :size, 0, [{:clause, 5, [], [], [{:integer, 6, size}]}]},
     {:function, 8, :contents, 0,
      [{:clause, 8, [], [],
        [{:bin, 9,
          for ch <- String.to_char_list(contents) do
            {:bin_element, 9, {:integer, 9, ch}, :default, :default}
          end
         }]}]}]
  end


  def parse_forms(basedir, filepath) do
    contents = Path.join(basedir, filepath) |> File.read!

    tokens = :erl_scan.tokens([],String.to_char_list(contents),1)
    scan(tokens,[])
    |> Enum.map fn(x) ->
      {:ok, y} = :erl_parse.parse_form(x)
      y
    end
  end
  
end
