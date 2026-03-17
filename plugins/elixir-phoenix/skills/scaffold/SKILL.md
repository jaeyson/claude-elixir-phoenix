---
name: phx:scaffold
description: Generate scaffolded Elixir/Phoenix code from embedded templates — LiveView modules, context modules, Oban workers, and Ecto migrations. Use when the user says "create a new LiveView", "add a context", "new worker", "scaffold", or "generate" and wants project-convention-aware code that includes Iron Law compliance, proper structure, and test stubs. Goes beyond mix phx.gen.* by applying plugin patterns.
argument-hint: <type> <name> [fields...]
---

# Scaffold — Convention-Aware Code Generation

Generate new Phoenix modules with Iron Laws and project patterns baked in.

## Usage

```
/phx:scaffold live_view Users.IndexLive
/phx:scaffold context Accounts user:string email:string
/phx:scaffold worker DailyDigestWorker
/phx:scaffold migration add_status_to_orders status:string
```

## Arguments

`$ARGUMENTS` = `<type> <name> [fields...]`

Types: `live_view`, `context`, `worker`, `migration`

## Iron Laws

1. **Match project conventions** — Scan existing code for naming patterns, directory structure, and module prefixes before generating
2. **Never duplicate** — Check if module already exists; if so, suggest edit instead
3. **Include test stub** — Every generated module gets a corresponding test file
4. **Apply Iron Laws inline** — Generated code must comply (e.g., `assign_async` in LiveView mount, string keys in Oban args)

## Workflow

### Step 1: Detect Project Conventions

Before generating, scan the project:

```
1. Find app name from mix.exs (:app field)
2. Check lib/ structure (flat vs nested contexts)
3. Scan existing files of same type for patterns:
   - LiveView: mount pattern, handle_event style, component imports
   - Context: function naming, Repo usage, preload patterns
   - Worker: queue names, args patterns, error handling
   - Migration: naming conventions, index patterns
4. Check for shared test helpers and factories
```

### Step 2: Generate from Template

Use the embedded templates below, customized with detected conventions.

### Step 3: Verify

Run `mix compile --warnings-as-errors` on the generated file.

## Templates

### LiveView

See `references/live-view-template.md` for the full template.

Key Iron Law compliance:

- `assign_async` for data loading (Iron Law #1)
- Authorization in every `handle_event` (Iron Law #11)
- `connected?/1` check before PubSub subscribe (Iron Law #3)

### Context

See `references/context-template.md` for the full template.

Key Iron Law compliance:

- Pinned values in queries (Iron Law #5)
- Separate queries for `has_many` (Iron Law #6)
- Wrap third-party APIs (Iron Law #20)

### Worker

See `references/worker-template.md` for the full template.

Key Iron Law compliance:

- String keys in args (Iron Law #8)
- Idempotent perform/1 (Iron Law #7)
- No struct storage (Iron Law #9)

### Migration

See `references/migration-template.md` for the full template.

Key patterns:

- Reversible migrations with `up`/`down` for complex changes
- Index creation with `create_if_not_exists`
- Concurrent index on large tables

## Output

For each scaffold, generate:

1. **Source file** in the appropriate `lib/` directory
2. **Test file** in the matching `test/` directory
3. **Summary** of what was generated and any manual steps needed
