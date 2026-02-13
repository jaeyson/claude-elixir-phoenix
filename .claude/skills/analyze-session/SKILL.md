---
name: analyze-session
description: Analyze a Claude Code session for workflow patterns, friction points, and plugin skill suggestions. Requires ccrider MCP.
argument-hint: <session-id> | --last | --from-find
---

# Analyze Session

Deep-dive into a Claude Code session to find patterns, friction, and where plugin skills could help.

## Usage

```
/phx:analyze-session 90a74843              # Analyze by ID (short or full)
/phx:analyze-session --last                # Analyze most recent session
/phx:analyze-session --from-find           # Analyze sessions saved by /phx:find-sessions
```

## Requirements

Requires **ccrider MCP**. If not available, tell the user:

> ccrider MCP is required. See: <https://github.com/neilberkman/ccrider>

## Steps

### 1. Determine session(s) to analyze

Parse `$ARGUMENTS`:

- **Session ID** (8+ hex chars): Use directly. If short (8 chars), call `mcp__ccrider__list_recent_sessions(limit: 50)` and find the session whose ID starts with the given prefix.
- **`--last`**: Call `mcp__ccrider__list_recent_sessions(limit: 1)`, use that session. Exclude the current session if possible.
- **`--from-find`**: Read `.claude/sessions-to-analyze.md`, extract session IDs from the `## Session IDs` section.
- **No args**: Show usage and stop.

### 2. Fetch session messages

For each session, call `mcp__ccrider__get_session_messages(session_id: id)`.

If the transcript is very large (>200 messages), use `last_n: 150` to get the most recent portion and note that the analysis covers the tail of the session.

### 3. Write transcript

Create `.claude/session-analysis/` if it doesn't exist.

Write each transcript to `.claude/session-analysis/{short-id}-transcript.md`:

```markdown
# Session Transcript: {short-id}
Project: {project}
Date: {date}
Messages: {count}

## Messages

### User (seq 1)
{content}

### Assistant (seq 2)
{content}

...
```

### 4. Analyze

Read the analysis template at `{SKILL_DIR}/references/analysis-template.md`.

**Strategy by session count:**

- **1 session**: Analyze directly — read the transcript and apply the template
- **2-3 sessions**: Spawn **sonnet** subagents, one per session. Each subagent reads the transcript file + template.
- **4+ sessions**: Spawn **haiku** subagents for speed.

Each subagent prompt:

```
Read the analysis template at {template_path}.
Read the session transcript at {transcript_path}.
Apply the template to produce a report.
Write the report to {report_path}.
```

### 5. Write report

Save each report to `.claude/session-analysis/{short-id}-report.md`.

### 6. Present results

Show the user a summary for each analyzed session:

```markdown
## Session: {short-id} ({project}, {date})

**Goal**: {1-line summary}
**Outcome**: Achieved / Partially / Not achieved
**Key friction**: {top 1-2 pain points}
**Plugin suggestions**: {top 2-3 /phx:* commands that would help}
```

If multiple sessions, add a cross-session summary:

```markdown
## Patterns Across Sessions

- **Most common friction**: {pattern}
- **Top plugin skill to try**: `/phx:{command}` — {why}
- **Workflow suggestion**: {recommendation}
```
