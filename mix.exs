defmodule AdocFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :adoc_formatter,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: AdocFormatter.CLI],
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Build the escript in :prod so dev-only deps (tidewave, bandit) stay out of it.
  def cli do
    [preferred_envs: ["escript.build": :prod]]
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
      {:unicode_string, "~> 2.3"},
      {:tidewave, "~> 0.8", only: :dev},
      {:bandit, "~> 1.0", only: :dev}
    ]
  end

  defp aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: {Tidewave, toolbar: false}, port: 4000) end)'"
    ]
  end
end
