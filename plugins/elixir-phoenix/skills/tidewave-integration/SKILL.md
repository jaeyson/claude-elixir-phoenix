---
name: tidewave-integration
description: "Tidewave MCP runtime tools for Phoenix development. Load when evaluating Elixir code in a running app, inspecting live process state, checking application logs, querying the dev database via SQL, introspecting Ecto schemas at runtime, or looking up exact-version hex library docs. Enables runtime debugging, smoke testing, and live state inspection."
user-invocable: false
---

# Tidewave MCP Integration

Runtime intelligence for Phoenix apps via MCP. Prefer Tidewave tools over Bash when available.

## Iron Laws — Never Violate These

1. **DEV ONLY** — Never use Tidewave tools in production contexts. Avoid on shared dev servers with production data copies
2. **PREFER TIDEWAVE OVER BASH** — `mcp__tidewave__get_docs` > `web_fetch`, `execute_sql_query` > `psql`
3. **CHECK AVAILABILITY FIRST** — Use `/mcp` command or detect `mcp__tidewave__` tools
4. **SQL IS READ-HEAVY** — Use `execute_sql_query` for SELECT, be careful with mutations
5. **EXACT VERSIONS** — `get_docs` returns docs for YOUR mix.lock versions, not latest

## Quick Reference

| Task | Tidewave Tool | Fallback |
|------|---------------|----------|
| Get docs | `mcp__tidewave__get_docs Module.func/3` | `web_fetch hexdocs.pm/...` |
| Run code | `mcp__tidewave__project_eval` | `mix run -e "code"` |
| SQL query | `mcp__tidewave__execute_sql_query` | `psql $DATABASE_URL` |
| Find source | `mcp__tidewave__get_source_location` | `grep -rn "defmodule"` |
| Inspect DOM | `mcp__Tidewave-Web__browser_eval` | Manual browser inspection |
| List schemas | `mcp__tidewave__get_ecto_schemas` | Read `lib/*/schemas/` |
| Read logs | `mcp__tidewave__get_logs level: :error` | `tail -f log/dev.log` |

## Detection

```bash
# Check endpoint
curl -s http://localhost:4000/tidewave/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}'
```

Or use `/mcp` in Claude Code to see connected servers.

## Essential Patterns

### Test Function Immediately

```elixir
# mcp__tidewave__project_eval
MyApp.Accounts.create_user(%{email: "test@example.com"})
```

### Verify Migration

```sql
-- mcp__tidewave__execute_sql_query
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'users';
```

### Debug LiveView (with PID from browser)

```elixir
# mcp__tidewave__project_eval
pid = pid("0.1234.0")
:sys.get_state(pid) |> Map.get(:socket) |> Map.get(:assigns) |> Map.keys()
```

## Setup Requirements

```elixir
# mix.exs
{:tidewave, "~> 0.1", only: :dev}

# endpoint.ex (in dev block)
plug Tidewave

# config/dev.exs (for LiveView source mapping)
config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true
```

## Proactive Runtime Checks

Don't just use Tidewave reactively. **Query runtime state at
workflow checkpoints** automatically:

- **After code edits**: `get_logs level: :error` (catch runtime crashes)
- **After features complete**: `project_eval` smoke test (behavioral check)
- **Before planning**: `get_ecto_schemas` + routes eval (concrete context)
- **When investigating**: Auto-capture errors before asking user
- **LiveView UI bugs**: `browser_eval` to inspect DOM state before editing components

See `references/proactive-patterns.md` for full integration points.

## Gotchas

- **`project_eval` runs in the app process** — Long-running evals block the endpoint. Never eval `Repo.all` on large tables or infinite loops. Use timeouts
- **`execute_sql_query` bypasses Ecto** — Raw SQL won't trigger Ecto callbacks, validations, or virtual fields. Results may differ from what your app returns
- **Tidewave disappears on crash** — If the Phoenix app crashes, all Tidewave tools become unavailable. Check `/mcp` after unexpected errors
- **`get_docs` returns YOUR version** — This is a feature, not a bug. But if you're debugging a version upgrade, the docs reflect the OLD version in `mix.lock`, not the version you're upgrading to
- **Browser eval needs Chrome/Chromium** — `browser_eval` requires a Chromium-based browser with DevTools protocol. Firefox and Safari won't work

## References

For detailed patterns, see:

- `references/proactive-patterns.md` - Push-like runtime patterns at workflow checkpoints
- `references/tool-examples.md` - Complete tool usage examples
- `references/validation-checklist.md` - Runtime validation patterns
