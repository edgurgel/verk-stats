# VerkStats [![Build Status](https://travis-ci.org/edgurgel/verk-stats.svg?branch=master)](https://travis-ci.org/edgurgel/verk-stats)

Application that generate metrics about [Verk](https://github.com/edgurgel/verk) jobs & queues through a `sink` (logs, statsd)

## Installation

The package can be installed by adding `verk_stats` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:verk_stats, "~> 1.0"}
  ]
end
```

## Metrics

* `jobs.start` - `counter` - When a job was started
* `jobs.success` - `timing` - How long a job took to finish successfully.
* `jobs.success.total_fime` - `timing` - How long a job took to finish successfully counting from the time it was enqueued.
* `jobs.failure` - `timing` - How long it took for a job to finish unsuccessfully.

Every metric will have tags `"worker:NameOfWorker"` & `"queue:NameOfTheQueue"`

## Usage

Add `VerkStats` to your supervision tree after `Verk.Supervisor` has been started.

Example using `LoggerSink` as sink.

```elixir
defmodule VerkExample do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [supervisor(Verk.Supervisor, []), {VerkStats, VerkStats.LoggerSink}]

    opts = [strategy: :one_for_one, name: VerkExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

The `LoggerSink` will log all metrics. Here's an example of a sink using [`Statix`](https://github.com/lexmag/statix)(StatsD client):

```elixir
defmodule StatixSink do
  @behaviour VerkStats.Sink
  use Statix

  def collect(:counter, key, value, tags) do
    increment(key, value, tags: tags)
    :ok
  end

  def collect(:timing, key, value, tags) do
    timing(key, value, tags: tags)
    :ok
  end
end
```
