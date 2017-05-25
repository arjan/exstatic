defmodule ExStatic do

  require Record
  Record.defrecordp :file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl")

  @default_path "priv/static"

  epoch = {{1970, 1, 1}, {0, 0, 0}}
  @epoch :calendar.datetime_to_gregorian_seconds(epoch)

  defmacro __using__(opts) do
    path = cond do
      opts[:path] != nil ->
        Path.dirname(__CALLER__.file) |> Path.join(opts[:path])
      true ->
        @default_path
    end
    if not File.exists?(path) do
      raise RuntimeError, "#{__CALLER__.module}: Path does not exists: #{path}"
    end

    all = get_files(path)
    |> Enum.map(fn file ->
      {file, File.read!(Path.join(path, file))}
    end)

    [
      # contents functions
      for {file, contents} <- all do
        quote do
          def contents(unquote(file)) do
            unquote(contents)
          end
        end
      end,

      # size functions
      for {file, contents} <- all do
        quote do
          def size(unquote(file)) do
            unquote(String.length(contents))
          end
        end
      end,

      # gzip_contents functions
      for {file, contents} <- all do
        quote do
          def gzip_contents(unquote(file)) do
            unquote(:zlib.gzip(contents))
          end
        end
      end,

      # gzip_size functions
      for {file, contents} <- all do
        quote do
          def gzip_size(unquote(file)) do
            unquote(String.length(:zlib.gzip(contents)))
          end
        end
      end,

      # content_type functions
      for {file, _contents} <- all do
        quote do
          def content_type(unquote(file)) do
            unquote(MIME.from_path(file))
          end
        end
      end,

      # mtime functions
      for {file, _contents} <- all do
        {:ok, file_info(mtime: mtime)} = :prim_file.read_file_info(Path.join(path, file))
        {:ok, mtime} =
          (:calendar.datetime_to_gregorian_seconds(mtime) - @epoch)
          |> DateTime.from_unix

        quote do
          def mtime(unquote(file)) do
            unquote(Macro.escape(mtime))
          end
        end
      end,

      # exists? functions
      for {file, _} <- all do
        quote do
          def exists?(unquote(file)), do: true
        end
      end,

      quote do
        def exists?(_), do: false
      end

    ]
    |> List.flatten
  end

  defp get_files(input_path) do
    input_path
    |> Path.join("**")
    |> Path.wildcard
    |> Enum.filter(&(!File.dir?(&1)))
    |> Enum.map(&(Path.relative_to(&1, input_path)))
    # |> Enum.filter(&(!already_compiled(input_path, &1)))
  end

end
