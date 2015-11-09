defmodule Exstatic.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :exstatic,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     description: description,
     name: "ExStatic"]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
        {:plug, "~> 1.0"}
    ]
  end

  defp description do
    """
    Serve static files from memory in the Phoenix Framework.

    This extension compiles all of a project's static assets
    (e.g. Javascript, HTML, images, etc) into Erlang modules and loads
    them into the Erlang VM, with the purpose of serving them fast and
    without a dependency on a filesystem.
    """
  end
  
  defp package do
    [
        files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
        maintainers: ["Arjan Scherpenisse"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/arjan/exstatic"}
    ]
  end
  
end
