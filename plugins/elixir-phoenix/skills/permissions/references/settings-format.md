# Claude Code Settings Permission Format

How to correctly write permissions to Claude Code settings files.

## Settings File Hierarchy

Claude Code reads settings from multiple locations (in priority order):

| File | Scope | Use Case |
|------|-------|----------|
| `~/.claude/settings.json` | Global (all projects) | Commands safe everywhere |
| `.claude/settings.json` | Project (checked in) | Team-shared project permissions |
| `.claude/settings.local.json` | Project (gitignored) | Personal project permissions |

## Permission Format

Permissions live under the `permissions` key with `allow` and `deny` arrays:

```json
{
  "permissions": {
    "allow": [
      "Bash(mix test*)",
      "Bash(mix compile*)",
      "Bash(git status)"
    ],
    "deny": [
      "Bash(rm -rf*)",
      "Bash(sudo*)"
    ]
  }
}
```

## Pattern Syntax

Each permission entry follows `Tool(pattern)` format. Two notations exist:

### Colon separator (standard — used by Claude Code UI)

When a user clicks "Allow always" in Claude Code, the entry is saved
with `:` separating the command prefix from the wildcard:

| Pattern | Matches |
|---------|---------|
| `Bash(git:*)` | `git diff`, `git add`, `git status`, etc. |
| `Bash(mix test:*)` | `mix test`, `mix test test/foo_test.exs`, etc. |
| `Bash(mix format)` | Exact match: only `mix format` (no args) |
| `Bash(python3:*)` | `python3 -c "..."`, `python3 script.py`, etc. |

### Space separator (also works)

Patterns can also use a space instead of `:` — both are equivalent:

| Pattern | Matches |
|---------|---------|
| `Bash(mix test*)` | Same as `Bash(mix test:*)` |
| `Bash(git diff*)` | Same as `Bash(git diff:*)` |

### Rules

- `*` is a glob wildcard (matches any characters)
- `:` before `*` acts as a space separator for matching
- Place `*` at the end to match commands with any arguments
- Exact strings (no `*`) match only that exact command
- Patterns are case-sensitive
- `deny` takes priority over `allow`
- When writing new entries, use `:` format for consistency with Claude Code UI

## Recommended Permission Sets

### Minimal (Read-Only Developer)

```json
{
  "permissions": {
    "allow": [
      "Bash(ls*)",
      "Bash(cat*)",
      "Bash(grep*)",
      "Bash(mix compile*)",
      "Bash(mix test*)",
      "Bash(git status)",
      "Bash(git log*)",
      "Bash(git diff*)"
    ]
  }
}
```

### Standard Elixir Developer

```json
{
  "permissions": {
    "allow": [
      "Bash(ls*)",
      "Bash(cat*)",
      "Bash(grep*)",
      "Bash(head*)",
      "Bash(tail*)",
      "Bash(wc*)",
      "Bash(find*)",
      "Bash(mix compile*)",
      "Bash(mix test*)",
      "Bash(mix format*)",
      "Bash(mix credo*)",
      "Bash(mix deps.get*)",
      "Bash(mix ecto.migrate*)",
      "Bash(mix ecto.rollback*)",
      "Bash(mix ecto.gen.migration*)",
      "Bash(mix phx.routes*)",
      "Bash(mix hex.audit*)",
      "Bash(mix deps.audit*)",
      "Bash(mix xref*)",
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git show*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git push)",
      "Bash(git branch)"
    ]
  }
}
```

### Full-Trust Developer

Adds git write operations and generators:

```json
{
  "permissions": {
    "allow": [
      "Bash(mix *)",
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(ls*)",
      "Bash(cat*)",
      "Bash(grep*)",
      "Bash(find*)",
      "Bash(mkdir*)",
      "Bash(cp*)"
    ],
    "deny": [
      "Bash(mix ecto.reset*)",
      "Bash(mix ecto.drop*)",
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf*)",
      "Bash(sudo*)"
    ]
  }
}
```

## Merging Strategy

When the permission analyzer writes to settings:

1. **Read** current contents of the target settings file
2. **Parse** existing `permissions.allow` array
3. **Append** new entries (skip duplicates)
4. **Never remove** existing entries
5. **Write** merged result back

```
existing:  ["Bash(mix test*)", "Bash(git status)"]
new:       ["Bash(mix test*)", "Bash(mix compile*)", "Bash(mix format*)"]
merged:    ["Bash(mix test*)", "Bash(git status)", "Bash(mix compile*)", "Bash(mix format*)"]
```

## Project vs Global Placement

| Command Type | Recommended Location |
|-------------|---------------------|
| Universal tools (`ls`, `grep`, `cat`) | `~/.claude/settings.json` (global) |
| Elixir-specific (`mix test`, `mix compile`) | `.claude/settings.json` (project) |
| Personal preferences | `.claude/settings.local.json` (local) |

The analyzer should default to `.claude/settings.json` (project-level)
for Elixir commands and suggest global placement for universal tools.
