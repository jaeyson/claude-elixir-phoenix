# Migration Template

Convention-aware Ecto migration scaffold.

## Standard Template

```elixir
defmodule {App}.Repo.Migrations.{Name} do
  use Ecto.Migration

  def change do
    # TODO: Add migration steps
  end
end
```

## Add Column Pattern

```elixir
def change do
  alter table(:{table}) do
    add :{column}, :{type}, null: false, default: "{default}"
  end

  # Add index if column will be queried frequently
  create index(:{table}, [:{column}])
end
```

## Create Table Pattern

```elixir
def change do
  create table(:{table}) do
    add :name, :string, null: false
    add :email, :citext, null: false
    # Iron Law #4: Never :float for money
    add :amount_cents, :integer, null: false, default: 0
    add :user_id, references(:users, on_delete: :delete_all), null: false

    timestamps(type: :utc_datetime)
  end

  create unique_index(:{table}, [:email])
  create index(:{table}, [:user_id])
end
```

## Large Table Index Pattern

```elixir
# For tables with 100k+ rows, create indexes concurrently
# Requires separate up/down instead of change

@disable_ddl_transaction true
@disable_migration_lock true

def up do
  create_if_not_exists index(:{table}, [:{column}], concurrently: true)
end

def down do
  drop_if_exists index(:{table}, [:{column}])
end
```

## Gotchas

- Always use `null: false` unless the column is genuinely optional
- Use `:citext` for case-insensitive text (email, username) — requires `citext` extension
- Use `references(..., on_delete: :delete_all)` or `:nilify_all` — never leave default `:nothing` without reason
- Reversible migrations: `change` auto-reverses `add`, `create`; use `up`/`down` for `execute` or data migrations
