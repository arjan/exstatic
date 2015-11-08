ExStatic
========

Serve static files from memory in the Phoenix Framework.

This extension compiles all your static files into Erlang modules and
loads them into the Erlang VM. The assumption is that there are not
that many static files and they are not that big. There are no size
checks done -- take care that your VM settings allow the kind of
memory usage.

Usage
-----

Add `exstatic` to your deps:

     {:exstatic, git: "https://github.com/arjan/exstatic.git"},

Then, compile your static files (by default it looks in `priv/static`):

     mix exstatic.compile

Now, tell your endpoint to serve the compiled files.

    defmodule MyApp.Endpoint do
      use Phoenix.Endpoint, otp_app: :myapp
      
      # Serve at "/" the static files from ExStatic compiled files
      plug ExStatic.Plug,
        at: "/"

Remember, whenever you change your files, you need to run `mix
exstatic.compile` again.


Performance
-----------

Initial tests show that the performance is ~2x that of the regular
`Plug.Static`.



How it works
------------

Static files are compiled to the plain data and also to a gzip
version. Furthermore, file metadata is also compiled into accessor
functions.

The module names are checksums of the original filenames (relative to
the static base path, e.g. `priv/static`):
`ExStatic.Compiled.66AGY7SLJZNP4MCP256LHNA6UWRMTGUY.beam`.

Each module exposes several functions: `contents/0`, `size/0`, `mime/0` etc.
