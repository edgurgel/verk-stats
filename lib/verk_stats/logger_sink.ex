defmodule VerkStats.LoggerSink do
  @behaviour VerkStats.Sink
  @moduledoc """
  Default VerkStats sink. It logs the stats using Logger
  """

  require Logger

  @doc false
  def collect(type, key, term, tags) do
    Logger.info("Verk Stats - #{type} - #{key} - #{term} - #{inspect(tags)}")
  end
end
