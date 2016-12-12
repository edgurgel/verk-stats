defmodule VerkStats.Mixfile do
  use Mix.Project

  @description """
    Application to track metrics for Verk queues & jobs
  """

  def project do
    [
      app: :verk_stats,
      version: "1.0.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      name: "Verk Stats",
      description: @description,
      package: package(),
      deps: deps()
    ]
  end

  defp deps() do
    [{:verk, "~> 1.4"}]
  end

  defp package() do
    [
      maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/edgurgel/verk-stats"}
    ]
  end
end
