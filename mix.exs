defmodule LogisticMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :logistic_map,
      version: "1.1.0",
      elixir: "~> 1.6",
      compilers: [:rustler] ++ Mix.compilers,
      rustler_crates: rustler_crates(),
      description: "Benchmark of Logistic Map using integer calculation and `Flow`.",
      package: [
        maintainers: ["Susumu Yamazaki"],
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/zeam-vm/logistic_map"}
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp rustler_crates() do
    [logistic_map: [
      path: "native/logistic_map",
      # mode: (if Mix.env == :prod, do: :release, else: :debug)
      mode: :release
    ]]
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
      {:flow, "~> 0.12"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:rustler, "~> 0.16.0"}
    ]
  end
end
