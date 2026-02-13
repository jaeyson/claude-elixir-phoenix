# Session Analysis Template

You are analyzing a Claude Code session transcript (pre-extracted as JSON) from a Phoenix/Elixir developer.
Your goal is to produce a structured report that helps improve an Elixir/Phoenix Claude Code plugin.

## Context

The developer has a plugin (`elixir-phoenix`) with these commands:

- `/phx:plan` — Plan features with specialist agents
- `/phx:work` — Execute plan with checkboxes
- `/phx:review` — Multi-agent code review
- `/phx:investigate` — Bug debugging
- `/phx:audit` — Project health audit
- `/phx:verify` — Run mix compile/test/credo
- `/phx:full` — Complete autonomous cycle
- `/phx:quick` — Fast implementation, skip ceremony

The plugin also has auto-loading skills (ecto-patterns, liveview-patterns, oban, security, testing, etc.)
and specialist agents that can be spawned.

## Your Task

Read the extracted session JSON and produce a report answering these questions:

### 1. Session Purpose

What was the developer trying to accomplish? Categorize:

- Bug fix, feature implementation, refactoring, debugging, deployment, review, exploration, etc.
- Was this a single task or multiple tasks in one session?

### 2. Development Patterns

How did the developer work?

- Did they plan before coding or dive straight in?
- Did they use iterative fix cycles (edit -> test -> fix -> test)?
- Did they use subagents or work solo?
- What was their debugging approach?
- Did they use Tidewave MCP tools (project_eval, browser_eval, execute_sql_query)?

### 3. Tool Usage Analysis

- Which tools dominated? (Read-heavy = exploration, Edit-heavy = implementation, Bash-heavy = debugging)
- Were there patterns of tool switching that suggest friction?
- Did they use any MCP integrations (Tidewave, Linear, etc.)?

### 4. Plugin Usage (if any /phx: commands present)

- Which commands were used?
- Did the plugin workflow help or hinder?
- Were there false starts, retries, or abandoned workflows?
- What did the plugin do well? What failed?

### 5. Pain Points & Friction

- Where did the developer seem stuck? (repeated similar commands, error -> retry loops)
- Were there errors? What caused them?
- Did the developer have to do manual work that could be automated?
- Did they abandon approaches and try different ones?

### 6. Plugin Opportunities

Based on this session, what could the plugin do better?

- Missing automation (things done manually that should be a command)
- Missing patterns (Elixir patterns the plugin should know about)
- Missing agents (specialist analysis that would have helped)
- Workflow improvements (steps that could be streamlined)

### 7. Key Files & Domains

- What Phoenix contexts/domains were touched?
- What file types dominated? (LiveView, Ecto, tests, etc.)
- Were there cross-cutting concerns (auth, real-time, etc.)?

## Output Format

Write your report as structured markdown. Be concrete and specific — cite actual commands,
file paths, and patterns from the session data. Don't be generic.

Keep the report under 300 lines. Focus on actionable insights.

Write the report to the path specified in your prompt.
