defmodule Kudzu.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:gen_stage, "~> 0.14"},
      {:csv, "~> 2.3"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.5"},
      {
        :briefly,
        git: "https://github.com/CargoSense/briefly",
        ref: "2526e9674a4e6996137e066a1295ea60962712b8"
        # "~> 0.4" https://github.com/CargoSense/briefly/issues/17
      },
    ]
  end
end
