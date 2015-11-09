ExStatic
========

Serve static files from memory in the Phoenix Framework.

This extension compiles all of a project's static assets
(e.g. Javascript, HTML, images, etc) into Erlang modules and loads
them into the Erlang VM, with the purpose of serving them fast and
without a dependency on a filesystem.

The assumption is that there are not that many static files and they
are not that big. There are no size checks done -- take care that your
VM settings allow the kind of memory usage.

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

Initial tests show that the performance is about a 70% increase
compared to the vanilla `Plug.Static`.



How it works
------------

Static files are compiled to the plain data and also to a gzip
version. Furthermore, file metadata is also compiled into accessor
functions.

The module names are checksums of the original filenames (relative to
the static base path, e.g. `priv/static`):
`ExStatic.Compiled.66AGY7SLJZNP4MCP256LHNA6UWRMTGUY.beam`.

Each module compiles several functions, exposing the file contents and its metadata.
These functions are also accessible from the `ExStatic` module:

    ExStatic.contents("robots.txt")
    ExStatic.gzip_contents("robots.txt")
    ExStatic.size("robots.txt")
    ExStatic.gzip_size("robots.txt")
    ExStatic.content_type("robots.txt")
    ExStatic.ctime("robots.txt")
    ExStatic.mtime("robots.txt")

All of these functions also exist in assertion-mode:

    ExStatic.mtime!("robots.txt")

Whenever a file is not found, the function crashes (the `!` variant);
or `{:error, :nofile, filename}` is returned (the normal variant).

Furthermore, there is a `ExStatic.exists?` function returning a
boolean to check whether a given file exists.

