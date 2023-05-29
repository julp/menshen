defmodule Menshen.MixProject do
  use Mix.Project

  def project do
    [
      app: :menshen,
      version: "0.0.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: ~W[logger]a,
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.13"},
      {:phoenix, "~> 1.6", optional: true},
    ]
  end
end
