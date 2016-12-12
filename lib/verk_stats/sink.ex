defmodule VerkStats.Sink do
  @moduledoc """
  Examples:

  sink.collect(:counter, "jobs.start", 1, worker: "Example", queue: "default")
  """

  @type collect_type :: :counter | :timing

  @callback collect(collect_type, iodata, term, [String.t()]) :: :ok
end
