# Oban Pro Reference

Oban Pro extends Oban with advanced worker types, workflows, and batches.

> **Official docs**: <https://hexdocs.pm/oban_pro/> — Always check for the latest API.
> Use `hexdocs-fetcher` skill or Tidewave `get_docs` to fetch current documentation.

## Critical Difference: `process/1` not `perform/1`

```elixir
defmodule MyApp.Workers.ImportWorker do
  use Oban.Pro.Worker,
    queue: :imports,
    max_attempts: 5,
    unique: [period: 60, states: :incomplete]

  @impl Oban.Pro.Worker
  def process(%Oban.Job{args: %{"import_id" => import_id}}) do
    :ok
  end
end
```

## Key Features (consult official docs for current API)

### Structured Jobs — Compile-time arg validation

```elixir
use Oban.Pro.Worker,
  structured: [
    keys: [:user_id, :action, :metadata],
    required: [:user_id, :action]
  ]
```

### Recorded Jobs — Capture output for retrieval

```elixir
use Oban.Pro.Worker, recorded: true

# Later: {:ok, result} = Oban.Pro.Worker.fetch_recorded(job)
```

### Encrypted Jobs — AES-256-CTR for args at rest

```elixir
use Oban.Pro.Worker,
  encrypted: [key: {MyApp.Config, :oban_encryption_key, []}]
```

**Iron Law**: Encryption breaks uniqueness on `args` (encrypted args differ each time). Use `meta` for unique constraints with encrypted workers.

## Workflows

Use `Oban.Pro.Workers.Workflow` (NOT `Oban.Pro.Worker` or `Oban.Pro.Workflow`).

```elixir
Oban.Pro.Workers.Workflow.new_workflow()
|> Oban.Pro.Workers.Workflow.add(:extract, ExtractWorker.new(%{data_id: 1}))
|> Oban.Pro.Workers.Workflow.add(:transform, TransformWorker.new(%{}), deps: [:extract])
|> Oban.Pro.Workers.Workflow.add(:load, LoadWorker.new(%{}), deps: [:transform])
|> Oban.insert_all()
```

## Batches

Use `Oban.Pro.Workers.Batch`. Requires `Oban.Pro.Plugins.BatchManager` in config.

Callbacks: `handle_attempted`, `handle_completed`, `handle_discarded`, `handle_exhausted`.

## Official Documentation

For complete and up-to-date API reference, patterns, and configuration:

- **Oban Pro**: <https://hexdocs.pm/oban_pro/>
- **Oban Pro Workers**: <https://hexdocs.pm/oban_pro/Oban.Pro.Worker.html>
- **Workflows**: <https://hexdocs.pm/oban_pro/Oban.Pro.Workers.Workflow.html>
- **Batches**: <https://hexdocs.pm/oban_pro/Oban.Pro.Workers.Batch.html>
- **Oban Web (dashboard)**: <https://hexdocs.pm/oban_web/>
