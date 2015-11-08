defmodule Exstatic.Mixfile do
  use Mix.Project

  def project do
    [app: :exstatic,
     version: "0.1.0",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
     {:plug, "~> 1.0"}
    ]
  end
end
