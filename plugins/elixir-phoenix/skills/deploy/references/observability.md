# Observability Reference

## Telemetry Metrics

```elixir
defmodule MyAppWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg), do: Supervisor.start_link(__MODULE__, arg, name: __MODULE__)

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      counter("phoenix.router_dispatch.stop.duration"),

      # Database
      summary("my_app.repo.query.total_time", unit: {:native, :millisecond}),
      summary("my_app.repo.query.queue_time", unit: {:native, :millisecond}),

      # VM
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.system_counts.process_count")
    ]
  end

  defp periodic_measurements do
    [
      {MyApp.Telemetry, :measure_users, []}
    ]
  end
end
```

## Custom Telemetry Events (Span Pattern)

Wrap operations in spans emitting start/stop/exception events:

```elixir
defmodule MyApp.Telemetry do
  @prefix [:my_app, :external_api, :call]

  def span(fun) do
    start_time = System.monotonic_time()
    :telemetry.execute(@prefix ++ [:start], %{
      system_time: System.system_time()
    }, %{})

    try do
      result = fun.()
      duration = System.monotonic_time() - start_time
      :telemetry.execute(@prefix ++ [:stop], %{
        duration: duration
      }, %{})
      result
    catch
      kind, reason ->
        duration = System.monotonic_time() - start_time
        :telemetry.execute(@prefix ++ [:exception], %{
          duration: duration
        }, %{kind: kind, reason: reason})
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end
end
```

### Route-Level Metrics with Tag Values

```elixir
summary("phoenix.router_dispatch.stop.duration",
  tags: [:method, :route],
  tag_values: &get_and_put_http_method/1,
  unit: {:native, :millisecond}
)

defp get_and_put_http_method(%{conn: %{method: method}} = meta) do
  Map.put(meta, :method, method)
end
```

### Libraries with Built-in Telemetry

Phoenix, Ecto, Oban, Plug, Tesla, Broadway, Absinthe, and Ash
all emit telemetry events. Use LiveDashboard to visualize them.

## Structured Logging

```elixir
# config/prod.exs
config :logger, :console,
  format: {LoggerJSON.Formatters.BasicLogger, :format},
  metadata: [:request_id, :user_id]

# Or use logger_json
config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.BasicLogger,
  metadata: [:request_id, :user_id, :file, :line]
```

## Sentry Error Tracking

```elixir
# In endpoint.ex - BEFORE Phoenix.Endpoint
plug Sentry.PlugCapture

# After Plug.Parsers
plug Sentry.PlugContext
```

## Production Checklist

### Configuration

- [ ] All secrets from environment variables in runtime.exs
- [ ] `server: true` in endpoint config
- [ ] SSL verification for database connections
- [ ] Pool size configured via env var
- [ ] PHX_HOST set correctly

### Health & Monitoring

- [ ] Health check endpoints: /health/startup, /health/liveness, /health/readiness
- [ ] Telemetry metrics configured
- [ ] Structured logging (JSON)
- [ ] Error tracking (Sentry/AppSignal)

### Deployment

- [ ] Graceful shutdown period ≥ 60 seconds
- [ ] preStop hook with sleep (Kubernetes)
- [ ] Rolling deployment with maxUnavailable: 0
- [ ] Migration command in deploy process

### Security

- [ ] Running as non-root user
- [ ] Force HTTPS
- [ ] SECRET_KEY_BASE is 64+ bytes
- [ ] Sensitive env vars as secrets

### BEAM-Specific

- [ ] No CPU limits (memory limits only)
- [ ] Clustering configured if needed
- [ ] Distribution ports open (4369, 4370-4372)
- [ ] vm.args tuned for workload
