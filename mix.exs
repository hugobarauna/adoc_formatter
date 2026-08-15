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

  # Port 40404 rather than the usual 4000, so this does not fight with whatever
  # Phoenix app happens to be running. Override with TIDEWAVE_PORT, but keep
  # your MCP client config pointed at the same port if you do.
  defp aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: {Tidewave, toolbar: false}, port: String.to_integer(System.get_env(\"TIDEWAVE_PORT\") || \"40404\")) end)'"
    ]
  end
end
