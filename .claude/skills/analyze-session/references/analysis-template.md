# Session Analysis Template

Analyze this Claude Code session transcript and produce a report with two goals:

1. **Help the developer** — identify friction and suggest plugin skills that would help
2. **Improve the plugin** — identify patterns, gaps, and missing automation opportunities

## Available Plugin Skills

The developer may or may not have used these commands:

### Workflow

| Command | Purpose |
|---------|---------|
| `/phx:plan` | Plan features with specialist agents, produces checkbox plan |
| `/phx:plan --existing` | Enhance existing plan with deeper research |
| `/phx:work` | Execute plan with progress tracking and verification |
| `/phx:review` | Multi-agent code review (4 parallel agents) |
| `/phx:full` | Autonomous plan, work, review, compound cycle |
| `/phx:compound` | Capture solved problem as reusable knowledge |
| `/phx:triage` | Interactive triage of review findings |
| `/phx:document` | Generate @moduledoc, @doc, README, ADRs |
| `/phx:learn` | Capture lessons learned after a fix or correction |

### Utility

| Command | Purpose |
|---------|---------|
| `/phx:intro` | Interactive plugin tutorial |
| `/phx:init` | Initialize plugin in a project |
| `/phx:quick` | Fast implementation, skip ceremony |
| `/phx:investigate` | Structured bug debugging (4-track parallel) |
| `/phx:research` | Research Elixir topics on the web |
| `/phx:verify` | Run compile + format + credo + test |
| `/phx:trace` | Build call trees to trace function flow |
| `/phx:boundaries` | Validate context boundaries with xref |

### Analysis

| Command | Purpose |
|---------|---------|
| `/ecto:n1-check` | Detect N+1 query patterns |
| `/lv:assigns` | Audit LiveView socket assigns for memory |
| `/phx:techdebt` | Find and report technical debt |
| `/phx:audit` | Full project health audit (5 parallel agents) |
| `/phx:challenge` | Rigorous review before merging |
| `/phx:perf` | Performance analysis and optimization |

Auto-loaded skills: `ecto-patterns`, `liveview-patterns`, `oban`, `security`, `testing`, `phoenix-contexts`, `elixir-idioms`, `deploy`, `tidewave-integration`

Auto-verification hooks: `mix compile --warnings-as-errors` and `mix format` run after every file edit.

## Analysis Questions

### 1. Session Summary

- What was the developer trying to accomplish?
- Was it a single task or multiple tasks?
- Did they succeed? Fully, partially, or not at all?
- Was this an Elixir/Phoenix session? What domains were touched (LiveView, Ecto, Oban, etc.)?

### 2. How They Worked

- Did they plan before coding or dive straight in?
- Was there an iterative cycle (edit, test, fix, test)?
- How many iterations before things worked?
- Did they use any `/phx:*` commands? Which ones?
- Did they use subagents, Tidewave, or other MCP tools?
- What was their tool mix? (Read-heavy = exploration, Edit-heavy = implementation, Bash-heavy = debugging)

### 3. Friction Points

Identify moments where the developer got stuck. Look for:

- **Error loops**: Same command repeated 3+ times with failures
- **Approach changes**: Abandoned one approach, started another
- **Manual repetition**: Same type of action done repeatedly (could be automated)
- **Long debugging**: Many reads/greps without finding the issue
- **Scope creep**: Task expanded beyond original intent
- **Missing context**: Developer had to manually look up docs, patterns, or conventions

For each friction point, cite the specific messages or patterns you see.

### 4. Plugin Skills That Would Help

For each friction point found, suggest a specific plugin skill:

| Friction Pattern | Suggested Skill | Why It Helps |
|-----------------|-----------------|--------------|
| Debugging spiral (3+ failed attempts) | `/phx:investigate` | Structured 4-track analysis prevents guessing |
| Large feature built ad-hoc | `/phx:plan` + `/phx:work` | Checkbox plan keeps scope focused |
| Quality issues found late | `/phx:verify` | Catches compile/format/credo/test issues early |
| Code review missed issues | `/phx:review` or `/phx:challenge` | Multi-agent review catches more |
| Too many review findings to process | `/phx:triage` | Interactive prioritization of findings |
| Quick fix that grew complex | `/phx:quick` | Enforces fast, focused changes |
| N+1 queries or slow DB | `/ecto:n1-check` | Detects query patterns automatically |
| Performance issues | `/phx:perf` | Structured performance analysis |
| Context boundary confusion | `/phx:boundaries` | Validates with mix xref |
| Same bug pattern recurring | `/phx:learn` + `/phx:compound` | Captures knowledge to prevent recurrence |
| Manual doc lookup for Elixir libs | `/phx:research` | Searches web + HexDocs efficiently |

Only suggest skills that genuinely match the friction. Don't force-fit.

### 5. Plugin Improvement Opportunities

This is the most important section for plugin development. Look for:

- **Missing automation**: Manual steps repeated across sessions that a hook or skill could handle (e.g., always running the same mix commands, always checking the same files)
- **Missing Iron Laws**: Code patterns that caused bugs but the plugin doesn't catch (e.g., a common Ecto mistake that should be a rule)
- **Missing skills**: Workflow patterns the plugin doesn't support (e.g., dependency updates, PR review responses, deployment checklists)
- **Missing agents**: Analysis tasks that would benefit from a specialist agent (e.g., a specific type of code review not covered)
- **Auto-loading gaps**: File patterns where relevant skills should load but don't
- **Workflow friction WITH the plugin**: If plugin commands were used, did they work smoothly? Were there false starts, retries, or confusion?
- **Tool integration gaps**: MCP tools or external services the developer used manually that could be integrated

Be specific: "Developer manually ran `mix deps.update` 5 times with different flags" not "dependency management could be improved."

### 6. Efficiency Assessment

Rate the session:

- **Smooth** — Minimal friction, good flow
- **Some friction** — Got stuck 1-2 times but recovered
- **High friction** — Multiple stuck points, significant time lost
- **Abandoned** — Goal not achieved, session ended without resolution

Estimate: what percentage of effort could have been saved with the right plugin skills?

## Output Format

Write a markdown report with these sections. Be **concrete** — cite actual messages, commands, and patterns from the transcript. Don't be generic.

Keep the report under 200 lines. Focus on actionable insights.
