---
name: session-insights
description: Full session analysis pipeline. Describe what you want to find in natural language and get a synthesized report. Requires ccrider MCP.
argument-hint: <prompt describing what to search> [--project NAME] [--after DATE] [--limit N]
---

# Session Insights

End-to-end pipeline: search sessions by natural language prompt, analyze all matches, synthesize findings.

## Usage

```
/phx:session-insights "all my Elixir Phoenix sessions"
/phx:session-insights "sessions where I debugged LiveView"
/phx:session-insights --project my_app
/phx:session-insights "Oban worker problems" --after 2026-01-15
/phx:session-insights "sessions with test failures" --limit 10
```

## Requirements

Requires **ccrider MCP**. If not available, tell the user:

> ccrider MCP is required. See: <https://github.com/neilberkman/ccrider>

## Pipeline

### Step 1: Parse intent from `$ARGUMENTS`

Extract from `$ARGUMENTS`:

- **Prompt** (the non-flag text): Natural language description of what to find
- **`--project NAME`**: Filter by project (match substring in path)
- **`--after DATE`**: Only sessions after this date (ISO format)
- **`--limit N`**: Max sessions to analyze (default: 15)

If no prompt given, default to: "all Elixir and Phoenix development sessions"

### Step 2: Translate prompt to search queries

Based on the user's prompt, generate **2-5 ccrider search queries** that cover the intent. Think about what terms would appear in sessions matching the description.

Examples:

| User Prompt                        | Queries to Run                                         |
| ---------------------------------- | ------------------------------------------------------ |
| "all my Elixir sessions"           | `mix compile`, `\.ex`, `Phoenix`, `Ecto`               |
| "LiveView debugging"               | `LiveView`, `_live.ex`, `assign_async`, `handle_event` |
| "Oban worker problems"             | `Oban`, `worker`, `perform`, `queue`                   |
| "sessions where I used the plugin" | `/phx:`, `elixir-phoenix:`, `Iron Law`                 |
| "database work"                    | `Ecto`, `migration`, `Repo.`, `schema`                 |
| "project my_app"                   | (use --project filter, no query needed)                |
| "test failures"                    | `mix test`, `test failed`, `assertion`, `ExUnit`       |

Run each query with `mcp__ccrider__search_sessions`, passing `--project` and `--after` filters if provided.

### Step 3: Merge and deduplicate

Combine results from all queries. Deduplicate by session ID. Sort by date (most recent first).

Report to user:

> Found **{N} unique sessions** matching "{prompt}" (from {Q} searches).
> Projects: {list of unique project names}
> Date range: {earliest} to {latest}

If more than `--limit` sessions found, take the most recent N.

If 0 sessions found, suggest broader search terms and stop.

### Step 4: Confirm with user

Show the session list as a compact table:

```
| #  | ID       | Project | Date       | Msgs | Summary                    |
|----|----------|---------|------------|------|----------------------------|
| 1  | 90a74843 | my_app   | 2026-02-09 | 30   | Fix gettext translations   |
```

Ask:

> "Analyze all {N} sessions? Or enter specific numbers (e.g., 1,3,5) to select a subset."

### Step 5: Fetch transcripts

For each confirmed session:

1. Call `mcp__ccrider__get_session_messages(session_id: id)`
2. If >200 messages, use `last_n: 150` and note the truncation
3. Write transcript to `.claude/session-analysis/{short-id}-transcript.md`

Format each transcript file:

```markdown
# Session: {short-id}

Project: {project}
Date: {date}
Messages: {count}

## Messages

### User (seq 1)

{content}

### Assistant (seq 2)

{content}
```

### Step 6: Analyze sessions

Locate the analysis template by searching for it:

```
Glob: **/analyze-session/references/analysis-template.md
```

Read the template contents. If not found, use the analysis questions inline from this skill's instructions.

**Strategy by session count:**

- **1-2 sessions**: Analyze directly in context
- **3-6 sessions**: Spawn **sonnet** subagents (one per session). Each reads transcript + template, writes report.
- **7+ sessions**: Spawn **haiku** subagents for speed

Subagent prompt:

> Read the analysis template at {template_path}.
> Read the session transcript at {transcript_path}.
> Apply the template to analyze this session.
> Write your report (under 200 lines) to {report_path}.

Write reports to `.claude/session-analysis/{short-id}-report.md`.

### Step 7: Synthesize

After all reports are written, read them all and produce a synthesis:

`.claude/session-analysis/insights-{date}.md`

Structure:

```markdown
# Session Insights: {prompt}

Date: {date}
Sessions analyzed: {N}
Projects: {list}

## Key Findings

### Most Common Friction Patterns

1. {pattern} — seen in {N} sessions
2. {pattern} — seen in {N} sessions

### Plugin Skills You Should Try

| Skill              | Why      | Sessions Where It Would Help |
| ------------------ | -------- | ---------------------------- |
| `/phx:investigate` | {reason} | {short-ids}                  |
| `/phx:plan`        | {reason} | {short-ids}                  |

### Plugin Improvement Opportunities

Aggregate findings from individual reports section 5. Group by type:

**Missing automation:**

- {concrete automation opportunity} — seen in {N} sessions

**Missing skills or agents:**

- {what should exist} — {evidence from sessions}

**Iron Law candidates:**

- {pattern that caused bugs} — should be caught automatically

**Auto-loading gaps:**

- {file pattern where skill should load but doesn't}

### Workflow Patterns

- {observation about how developers work}
- {observation about tool usage}
- {sessions with plugin vs without — what difference did it make?}

## Per-Session Summaries

### {short-id} — {project} ({date})

**Goal**: {1-line}
**Friction**: {key pain point}
**Plugin opportunity**: {top improvement suggestion}

(repeat for each session)
```

### Step 8: Present results

Show the user the Key Findings section directly in the conversation. Tell them:

> Full report: `.claude/session-analysis/insights-{date}.md`
> Per-session reports: `.claude/session-analysis/{id}-report.md`

## Iron Laws

1. **ALWAYS confirm before analyzing** — show the session list, get user approval
2. **NEVER skip the synthesis** — individual reports are useful but the cross-session patterns are the real value
3. **Respect limits** — default 15 sessions max to keep analysis manageable
