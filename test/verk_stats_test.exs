defmodule VerkStatsTest do
  use ExUnit.Case
  doctest VerkStats
  alias Verk.Job
  alias Verk.Events.{JobFailed, JobStarted, JobFinished}

  defmodule TestSink do
    @behaviour VerkStats.Sink

    def collect(type, key, term, tags) do
      test_process = Application.get_env(:verk_stats, :test_sink)
      send(test_process, {type, key, term, tags})
      :ok
    end
  end

  setup_all do
    {:ok, _pid} = Verk.EventProducer.start_link()
    :ok
  end

  setup do
    Application.put_env(:verk_stats, :test_sink, self())
    {:ok, _pid} = VerkStats.start_link(TestSink)
    :ok
  end

  test "job started stats" do
    job = %Job{queue: "test_queue", class: "DummyWorker", args: [1, 2, 3]}

    event = %JobStarted{job: job, started_at: DateTime.utc_now()}
    :ok = Verk.EventProducer.async_notify(event)

    assert_receive {:counter, "jobs.start", 1, ["worker:DummyWorker", "queue:test_queue"]}
    refute_received _any
  end

  test "job succeeded stats" do
    now = DateTime.utc_now()
    unix_now = now |> DateTime.to_unix(:milliseconds)

    enqueued_at = unix_now / 1000
    started_at = DateTime.from_unix!(unix_now + 5000, :milliseconds)
    finished_at = DateTime.from_unix!(unix_now + 10000, :milliseconds)

    job = %Job{
      queue: "test_queue",
      class: "DummyWorker",
      args: [1, 2, 3],
      enqueued_at: enqueued_at
    }

    event = %JobFinished{job: job, started_at: started_at, finished_at: finished_at}
    :ok = Verk.EventProducer.async_notify(event)

    assert_receive {:timing, "jobs.success", 5000, ["worker:DummyWorker", "queue:test_queue"]}

    assert_receive {:timing, "jobs.success.total_time", latency,
                    ["worker:DummyWorker", "queue:test_queue"]}

    assert_in_delta latency, 10_000, 1_000
    refute_received _any
  end

  test "job failure stats" do
    now = DateTime.utc_now()
    unix_now = now |> DateTime.to_unix(:milliseconds)

    started_at = now
    finished_at = DateTime.from_unix!(unix_now + 7000, :milliseconds)
    job = %Job{queue: "test_queue", class: "DummyWorker", args: [1, 2, 3]}
    event = %JobFailed{job: job, started_at: started_at, failed_at: finished_at}
    :ok = Verk.EventProducer.async_notify(event)

    assert_receive {:timing, "jobs.failure", 7000, ["worker:DummyWorker", "queue:test_queue"]}
    refute_received _any
  end
end
