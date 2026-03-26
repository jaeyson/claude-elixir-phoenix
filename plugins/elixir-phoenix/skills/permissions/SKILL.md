---
name: phx:permissions
description: Analyze recent Claude Code sessions and recommend safe Bash permissions for Elixir mix test, credo, and deploy commands in settings.json. Use when too many permission prompts slow workflow, after 5+ prompts in a session, or when user says "fix permissions", "reduce prompts", "allow commands", "permission fatigue", "optimize permissions", "mix command blocked", "bash permission denied", "allowedTools", "stop asking permission", "auto-allow mix", or "too many mix prompts".
argument-hint: "[--days=14] [--dry-run]"
---

# Permission Analyzer

Scan recent session transcripts to find Bash commands you keep approving,
cross-reference with current `settings.json`, and recommend adding the missing ones.

**Primary goal**: Discover MISSING permissions from actual usage.
**Secondary goal**: Clean up redundant/garbage entries.

## Usage

`/phx:permissions [--days=14] [--dry-run]` — Scans session JSONL files, finds uncovered Bash commands, classifies risk, and recommends `settings.json` changes. Use `--dry-run` to preview without writing.

## Arguments

`$ARGUMENTS` — `--days=N` (default: 14), `--dry-run` (preview only).

## Iron Laws

1. **NEVER auto-allow RED** — `rm`, `sudo`, `kill`, `curl|sh`, `mix ecto.reset`, `git push --force`, `chmod 777`
2. **Evidence-based only** — Only recommend commands actually approved in sessions
3. **Show before writing** — Present full diff, get explicit confirmation
4. **Preserve existing** — Merge, never overwrite

## Risk Classification

| Level | Examples | Action |
|-------|----------|--------|
| GREEN | `ls`, `cat`, `grep`, `tail`, `which`, `mkdir`, `cd`, `mix test/compile/credo/format`, `git status/log/diff` | Auto-recommend |
| YELLOW | `git add/commit/push`, `mix ecto.migrate`, `mix deps.get`, `npm install`, `docker build/run`, `source`, `mise exec` | Recommend with note |
| RED | `rm -rf`, `sudo`, `kill`, `curl|sh`,`mix ecto.reset/drop`,`git push --force`,`git reset --hard` | Never recommend |

## Workflow

### Step 1: Extract Bash Commands from Session JSONL Files

Run the extraction script from `${CLAUDE_SKILL_DIR}/references/extraction-script.md`.
This scans all project JSONL files from the last N days, checks each Bash command
against current `settings.json` patterns, and reports uncovered commands with counts.

**IMPORTANT**: Run this FIRST. Do NOT skip to settings cleanup.

### Step 2: Classify and Recommend

For each uncovered command from Step 1 output:

1. **Classify** as GREEN / YELLOW / RED per table above
2. **Generate permission pattern**: normalize to `Bash(base_command:*)` format
   - `mkdir -p` (94x) → `Bash(mkdir:*)`
   - `mise exec` (39x) → `Bash(mise:*)`
   - `tail -5` (20x) → `Bash(tail:*)`
3. **Check for redundancy**: skip if a broader existing pattern covers it
4. **Also scan for garbage** in current settings: `Bash(done)`, `Bash(fi)`,
   `Bash(__NEW_LINE_*)`, partial heredocs, entries covered by broader patterns

Present a combined table:

```
## Permission Recommendations (last N days)

### ADD — Missing permissions (from session scan)
| Pattern to Add | Times Used | Risk | Example |
|...

### REMOVE — Redundant/garbage entries
| Entry | Reason |
|...

### RED — Require manual approval (not adding)
| Command | Count | Risk |
|...
```

### Step 3: Apply (unless `--dry-run`)

After user confirms, merge into `~/.claude/settings.json` under `permissions.allow`.
Remove any garbage entries the user approved for removal.

## References

- `${CLAUDE_SKILL_DIR}/references/risk-classification.md` — Full classification rules
- `${CLAUDE_SKILL_DIR}/references/settings-format.md` — Permission pattern format
