defmodule ExPidController.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_pid_controller,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A discrete PID controller for feedback control loops in Elixir, useful for robotics, automation, and simulation",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tyler/ex_pid_controller"}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
