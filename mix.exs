defmodule XmlBuilder.Mixfile do
  use Mix.Project

  @source_url "https://github.com/joshnuss/xml_builder"

  def project do
    [
      app: :xml_builder,
      version: "2.4.0",
      elixir: "~> 1.12",
      deps: deps(),
      docs: docs(),
      package: [
        maintainers: ["Joshua Nussbaum"],
        licenses: ["MIT"],
        links: %{GitHub: @source_url}
      ],
      description: "XML builder for Elixir"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:credo, "~> 1.7.5", only: [:dev, :test], runtime: false},
      {:ex_doc, github: "elixir-lang/ex_doc", only: :dev}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
