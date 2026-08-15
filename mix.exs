defmodule AdocFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :adoc_formatter,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: AdocFormatter.CLI],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:unicode_string, "~> 2.3"}
    ]
  end
end
