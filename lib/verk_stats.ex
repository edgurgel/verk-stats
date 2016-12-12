defmodule VerkStats do
  @moduledoc """
  A GenStage consumer that generate metrics to the defined sink

  The default sink simply logs everything
  """
  use GenStage
  alias Verk.Events.{JobFailed, JobStarted, JobFinished}

  @doc """
  Start GenStage consumer that generates metrics using a `sink`
  """
  def start_link(sink), do: GenStage.start_link(__MODULE__, sink)

  @job_events [JobFailed, JobStarted, JobFinished]

  @doc false
  def init(sink) do
    filter = fn event -> event.__struct__ in @job_events end
    {:consumer, sink, subscribe_to: [{Verk.EventProducer, selector: filter}]}
  end

  @doc false
  def handle_events(events, _from, sink) do
    Enum.each(events, &handle_event(&1, sink))
    {:noreply, [], sink}
  end

  @doc false
  defp handle_event(%JobStarted{job: job}, sink) do
    :ok = sink.collect(:counter, "jobs.start", 1, tags(job))
  end

  defp handle_event(
         %JobFinished{job: job, started_at: started_at, finished_at: finished_at},
         sink
       ) do
    tags = tags(job)

    :ok =
      sink.collect(
        :timing,
        "jobs.success",
        DateTime.diff(finished_at, started_at, :milliseconds),
        tags
      )

    enqueued_at = DateTime.from_unix!(trunc(job.enqueued_at))

    :ok =
      sink.collect(
        :timing,
        "jobs.success.total_time",
        DateTime.diff(finished_at, enqueued_at, :milliseconds),
        tags
      )

    {:ok, sink}
  end

  defp handle_event(%JobFailed{job: job, started_at: started_at, failed_at: failed_at}, sink) do
    :ok =
      sink.collect(
        :timing,
        "jobs.failure",
        DateTime.diff(failed_at, started_at, :milliseconds),
        tags(job)
      )

    {:ok, sink}
  end

  defp tags(job), do: ["worker:#{job.class}", "queue:#{job.queue}"]
end
