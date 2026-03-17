# Worker Template

Convention-aware Oban worker scaffold with Iron Law compliance.

## Template

```elixir
defmodule {App}.Workers.{Name} do
  @moduledoc """
  {Description}

  ## Args

  - `"id"` - The record ID to process (string key, Iron Law #8)

  ## Idempotency

  This worker is idempotent (Iron Law #7). Re-running with the same
  args produces the same result without side effects.
  """

  use Oban.Worker,
    queue: :{queue},
    max_attempts: 3,
    unique: [period: 60, fields: [:args, :queue]]

  # Iron Law #8: Args use STRING keys, not atoms
  # Iron Law #9: Never store structs — store IDs
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    # Iron Law #7: Must be idempotent
    case process(id) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp process(id) do
    # TODO: Implement processing logic
    # 1. Fetch current state (idempotency: check if already processed)
    # 2. Perform work
    # 3. Return result
    {:ok, id}
  end
end
```

## Enqueue Pattern

```elixir
# In context module:
def enqueue_{job_name}(record) do
  # Iron Law #9: Store ID, not struct
  %{"id" => record.id}
  |> {App}.Workers.{Name}.new()
  |> Oban.insert()
end
```

## Test Template

```elixir
defmodule {App}.Workers.{Name}Test do
  use {App}.DataCase
  use Oban.Testing, repo: {App}.Repo

  alias {App}.Workers.{Name}

  describe "perform/1" do
    test "processes successfully" do
      # TODO: Setup test data
      assert :ok = perform_job({Name}, %{"id" => 1})
    end

    test "is idempotent (safe to retry)" do
      # TODO: Run twice, verify same result
      assert :ok = perform_job({Name}, %{"id" => 1})
      assert :ok = perform_job({Name}, %{"id" => 1})
    end

    test "returns error for missing record" do
      assert {:error, _} = perform_job({Name}, %{"id" => -1})
    end
  end
end
```

## Queue Configuration Reminder

Add to `config/config.exs` if queue doesn't exist:

```elixir
config :my_app, Oban,
  queues: [{queue}: 10]
```
