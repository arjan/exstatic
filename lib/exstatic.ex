defmodule ExStatic.Macro do
  defmacro file_accessor(name) do
    quote do
      def unquote(name)(filepath) do
        try do
          mod = String.to_existing_atom(ExStatic.Compiler.modulename(filepath))
          apply(mod, unquote(name), [])
        rescue
          ArgumentError -> {:error, :nofile, filepath}
        end
      end
    end
  end
end

defmodule ExStatic do

  import ExStatic.Macro

  # Do we exist? (always returns true)
  file_accessor :exists?

  # Return the contents of the file as a binary string.
  file_accessor :contents

  # Return the gzipped contents of the file
  file_accessor :gzip_contents

  # Return the size of the file, in bytes
  file_accessor :size

  # Return the size of the gzipped file
  file_accessor :gzip_size

  # Return the content type
  file_accessor :content_type

  # Return the ctime
  file_accessor :ctime

  # Return the ctime
  file_accessor :mtime
  
end

