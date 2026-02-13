---
name: analyze-sessions
description: Analyze Claude Code sessions to find plugin improvement opportunities. Development-only tool for plugin contributors.
argument-hint: <count> [--project <name>] [--synthesize]
disable-model-invocation: true
---

# Session Analysis Pipeline

Analyze Claude Code sessions to discover plugin improvement opportunities using a structured pipeline.

## Usage

```
/analyze-sessions 20                          # Analyze top 20 unanalyzed sessions
/analyze-sessions 50 --project some-project   # Filter to one project
/analyze-sessions 30 --synthesize             # Also produce synthesis report
```

## Arguments

Parse `$ARGUMENTS` for:

- **count** (required): Number of sessions to analyze (first positional arg)
- **--project NAME**: Filter sessions to a specific project
- **--synthesize**: After analysis, condense and produce updated improvement report

## Pipeline

### Step 1: Discover Sessions

Find all JSONL session files under `~/.claude/projects/*/`. Filter by `--project` if specified. Sort by file size descending (proxy for session richness).

Exclude already-analyzed sessions by checking `{SKILL_DIR}/references/session-index.json`.

### Step 2: Select Top N

Take top N unanalyzed sessions by size. Tell the user:

> "Found {total} unanalyzed sessions. Selecting top {N} by size."

### Step 3: Extract

Run the extraction script to produce structured JSON per session:

```bash
python3 {SKILL_DIR}/references/extract-session.py <session.jsonl> <output.json>
```

Write extracts to `scratchpad/session-extracts/`.

For batch mode, create a sessions list JSON first:

```json
[{ "file": "/path/to/session.jsonl", "project": "name", "session_id": "id" }]
```

Then: `python3 {SKILL_DIR}/references/extract-session.py --batch sessions.json scratchpad/session-extracts/`

### Step 4: Analyze

Spawn subagents using the template at `{SKILL_DIR}/references/analysis-template.md`.

**Agent strategy by session size (total tool calls):**

- **>100 tools**: Individual sonnet agent
- **30-100 tools**: Individual haiku agent
- **<30 tools**: Batch groups of 5, single sonnet agent

Each agent reads the extracted JSON + template, writes a report to `scratchpad/session-reports/`.

### Step 5: Condense (if --synthesize)

Run condensation to aggregate reports:

```bash
python3 {SKILL_DIR}/references/condense.py scratchpad/session-reports/ scratchpad/condensed.md
```

### Step 6: Synthesize (if --synthesize)

Spawn an **Opus** agent to:

1. Read `scratchpad/condensed.md`
2. Read existing report at `.claude/UPDATED_PLUGIN_REPORT_137_SESSIONS.md`
3. Produce updated report with new evidence counts

### Step 7: Update Index

Append newly analyzed session IDs to `{SKILL_DIR}/references/session-index.json`.

## Output Locations

| Artifact           | Path                                                |
| ------------------ | --------------------------------------------------- |
| Extracted JSON     | `scratchpad/session-extracts/`                      |
| Analysis reports   | `scratchpad/session-reports/`                       |
| Condensed findings | `scratchpad/condensed.md`                           |
| Synthesis report   | `.claude/UPDATED_PLUGIN_REPORT_{total}_SESSIONS.md` |

## Reference

- Existing report: `.claude/UPDATED_PLUGIN_REPORT_137_SESSIONS.md`
- Memory notes: `.claude/projects/.../memory/MEMORY.md` (Session Analysis Pipeline section)
