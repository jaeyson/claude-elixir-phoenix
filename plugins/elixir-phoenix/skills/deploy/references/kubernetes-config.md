# Kubernetes Configuration Reference

## Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0  # Zero downtime
      maxSurge: 1
  template:
    spec:
      terminationGracePeriodSeconds: 60  # Match BEAM shutdown
      containers:
      - name: my-app
        image: my-app:latest
        ports:
        - containerPort: 4000
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: secret-key-base
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            # NO CPU LIMIT - BEAM scheduler issues
        startupProbe:
          httpGet:
            path: /health/startup
            port: 4000
          periodSeconds: 3
          failureThreshold: 10
        livenessProbe:
          httpGet:
            path: /health/liveness
            port: 4000
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 6
        readinessProbe:
          httpGet:
            path: /health/readiness
            port: 4000
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
        lifecycle:
          preStop:
            exec:
              command: ["sleep", "15"]  # Allow LB to drain
```

## Health Check Plug

```elixir
defmodule MyAppWeb.HealthCheckPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(%{path_info: ["health", "startup"]} = conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"status":"ok"}))
    |> halt()
  end

  def call(%{path_info: ["health", "liveness"]} = conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"status":"ok"}))
    |> halt()
  end

  def call(%{path_info: ["health", "readiness"]} = conn, _opts) do
    case check_dependencies() do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, ~s({"status":"ok"}))
        |> halt()

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(503, Jason.encode!(%{status: "error", reason: reason}))
        |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp check_dependencies do
    case Ecto.Adapters.SQL.query(MyApp.Repo, "SELECT 1", []) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, "database_unavailable"}
    end
  end
end

# Add to endpoint.ex BEFORE router
plug MyAppWeb.HealthCheckPlug
```

## BEAM-Specific Considerations

- **NO CPU LIMITS** — BEAM scheduler has issues with cgroups CPU limits
- **Memory limits OK** — Set appropriate limits
- **terminationGracePeriodSeconds** — At least 60 seconds for connection draining
- **preStop hook** — Sleep 15s to allow load balancer to drain connections
- **Distribution ports** — Open 4369, 4370-4372 if clustering
