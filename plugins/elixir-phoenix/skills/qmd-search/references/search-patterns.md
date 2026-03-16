# QMD Search Patterns

## Integration Points

These are the exact places where QMD replaces grep in the workflow.

### 1. `/phx:investigate` — Step 0: Consult Compound Docs

**Before (grep):**

```bash
grep -rl "KEYWORD" .claude/solutions/ 2>/dev/null
```

**After (QMD):**

```
mcp__qmd__query({ query: "<error message or symptom description>" })
```

QMD advantage: finds solutions by semantic similarity, not just
keyword match. "association not loaded" matches a solution tagged
with "preload" even without that exact phrase.

### 2. `/phx:compound` — Phase 2: Duplicate Detection

**Before (grep):**

```bash
grep -rl "NotLoaded\|timeout\|N+1" .claude/solutions/ 2>/dev/null
```

**After (QMD):**

```
mcp__qmd__query({ query: "<root cause description>", limit: 5 })
```

Read top results, compare root causes to decide:
update existing vs create new vs skip.

### 3. `/phx:work` — Step 2: Check Context

**Before (grep):**

```bash
grep -rl "KEYWORD" .claude/solutions/ 2>/dev/null
```

**After (QMD):**

```
mcp__qmd__query({ query: "<task description from plan>" })
```

Surface known pitfalls and proven patterns before implementing.

### 4. `/phx:plan` — Risk Discovery

```
mcp__qmd__query({ query: "<feature area> errors issues" })
```

Include matched solutions as "Known Risks" in plan output.

### 5. `planning-orchestrator` — Phase 1b: Runtime Context

```
mcp__qmd__query({ query: "<feature keywords>" })
```

Pass known patterns to research agents to avoid re-solving.

### 6. `error-critic.sh` — Debugging Loop Escalation

When 3+ failures detected, suggest:

```
mcp__qmd__query({ query: "<consolidated error message>" })
```

## Advanced Patterns

### Searching by Frontmatter Fields

QMD indexes full file content including YAML frontmatter:

```
# Find all critical severity solutions
mcp__qmd__query({ query: "severity: critical" })

# Find solutions for a specific module
mcp__qmd__query({ query: "module: Accounts" })

# Find by problem type
mcp__qmd__query({ query: "problem_type: runtime_error ecto" })
```

### Cross-Referencing Related Solutions

After finding a solution, check for related ones:

```
# Read the solution
mcp__qmd__get({ path: "ecto-issues/preload-fix-20251201.md" })

# Search for related by tags from that solution
mcp__qmd__query({ query: "preload association belongs_to" })
```

### Searching Plans and Research

```
# Find past research on a topic
mcp__qmd__query({ query: "OAuth implementation", collection: "plans" })

# Find plans that hit blockers
mcp__qmd__query({ query: "BLOCKER DEAD-END", collection: "plans" })
```

### Batch Retrieval for Category Review

```
# Get all LiveView solutions
mcp__qmd__multi_get({ pattern: "liveview-issues/*.md" })

# Get recent solutions (read metadata)
mcp__qmd__multi_get({ pattern: "*/2026*.md" })
```

## Fallback Behavior

When QMD MCP is not available, all integration points fall back
to the original grep pattern:

```bash
grep -rl "KEYWORD" .claude/solutions/ 2>/dev/null
```

The detection happens at session start. Skills check for QMD
availability before choosing the search method:

```
IF QMD MCP detected at session start:
  → Use mcp__qmd__query for solution search
ELSE:
  → Use grep -rl (existing behavior)
```

No code changes needed in the project — the plugin adapts
automatically based on what's available.
