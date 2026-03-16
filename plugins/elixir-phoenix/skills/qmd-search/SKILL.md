---
name: qmd-search
description: >-
  Search compound knowledge semantically using QMD MCP. Use when searching
  .claude/solutions/ for previously solved problems, known patterns, or
  related issues. Prefer over grep -rl when QMD MCP is available.
  DO NOT load for: general file search, codebase grep, non-solution searches.
user-invocable: false
---

# QMD Search — Semantic Compound Knowledge

Search `.claude/solutions/` and `.claude/plans/` semantically using
QMD's hybrid search (BM25 + vectors + reranking) via MCP.

## When to Use

**Prefer QMD over grep** for solution discovery when available:

| Task | Without QMD | With QMD |
|------|-------------|----------|
| Find past fix | `grep -rl "KEYWORD" .claude/solutions/` | `mcp__qmd__query("N+1 query LiveView")` |
| Related solutions | Manual tag/file scanning | `mcp__qmd__query("preload association")` |
| Duplicate check | Grep exact symptoms | `mcp__qmd__query("timeout on dashboard mount")` |

## Iron Laws

1. **QMD is read-only** — never run `qmd collection add`, `qmd embed`,
   or `qmd update` automatically. Only suggest commands for user to run
2. **Fall back to grep** — if QMD MCP unavailable, use standard grep
3. **Scope searches** — use collection filter for focused results
4. **Trust but verify** — read the matched file after QMD returns it

## MCP Tool Reference

QMD exposes 4 tools via MCP:

### `mcp__qmd__query` (primary — use this)

Hybrid search: lexical + semantic + reranking.

```
mcp__qmd__query({
  query: "association not loaded timeout",
  collection: "solutions",   // optional: scope to collection
  limit: 5                   // default 10
})
```

### `mcp__qmd__get`

Retrieve a specific document by path or ID.

```
mcp__qmd__get({ path: "ecto-issues/preload-fix-20251201.md" })
```

### `mcp__qmd__multi_get`

Batch retrieve by glob pattern.

```
mcp__qmd__multi_get({ pattern: "liveview-issues/*.md" })
```

### `mcp__qmd__status`

Check index health and collection metadata.

## Search Patterns

### Before Investigating a Bug

```
mcp__qmd__query({ query: "<error message or symptom>" })
```

If match found: read the solution, present to user, ask
"Apply this fix, or investigate fresh?"

### Before Creating a Solution (Duplicate Check)

```
mcp__qmd__query({ query: "<root cause description>" })
```

If match found: update existing vs create new.

### During Planning (Known Risks)

```
mcp__qmd__query({ query: "<feature area> common issues" })
```

Surface relevant solutions as known risks in discovery.

## Detection

QMD availability is detected at session start by `detect-qmd.sh`.
When available, Claude receives:

> QMD MCP available — prefer mcp__qmd__query over grep for .claude/solutions/

## Setup

See `references/setup-guide.md` for installation and indexing.

## References

- `references/setup-guide.md` — Installation, collections, MCP config
- `references/search-patterns.md` — Advanced query patterns
