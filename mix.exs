defmodule McpPrBitbucketElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcp_pr_bitbucket_elixir,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: MCPBitbucketPr.CLI],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:dotenvy, "~> 0.8"}
    ]
  end
end
