# Plugin Tutorial Content

Content for each section of the `/phx:intro` tutorial.
Present ONE section at a time with AskUserQuestion between sections.

---

## Section 1: Welcome

### What This Plugin Does

This plugin adds **specialist Elixir/Phoenix agents**, **auto-loaded knowledge**, and **Iron Laws** to Claude Code. It turns a general-purpose AI into an opinionated Elixir pair programmer.

### The Core Concept

Everything revolves around a 4-phase workflow cycle:

```text
/phx:plan  -->  /phx:work  -->  /phx:review  -->  /phx:compound
   |               |                |                   |
   v               v                v                   v
 Research &    Execute with     Parallel agent     Capture what
 plan tasks    verification     code review        you learned
```

Each phase reads from the previous phase's output. Plans become checkboxes. Checkboxes track progress. Reviews catch mistakes. Compound knowledge makes future work faster.

### What You Get

| Feature | What It Does |
|---------|-------------|
| 20 specialist agents | Ecto, LiveView, security, OTP, Oban, deployment experts |
| 36 skills | Commands for every phase of development |
| 20 Iron Laws | Non-negotiable rules enforced automatically |
| Auto-loaded references | Context-aware docs loaded when you edit relevant files |
| Tidewave integration | Runtime debugging when Tidewave MCP is connected |

---

## Section 2: Core Workflow Commands

### The Full Cycle

For features that need planning and review:

```bash
# 1. Plan — spawns research agents, outputs checkbox plan
/phx:plan Add user avatars with S3 upload

# 2. Work — executes plan, checks off tasks, runs mix compile
/phx:work .claude/plans/user-avatars/plan.md

# 3. Review — parallel agents check Elixir idioms, security, tests
/phx:review

# 4. Compound — capture what you learned for future reference
/phx:compound Fixed S3 upload timeout with multipart streaming
```

### Shortcuts

Not everything needs the full cycle:

| Command | When to Use | Time |
|---------|------------|------|
| `/phx:quick` | Bug fixes, small features (<100 lines) | ~2 min |
| `/phx:full` | New features, autonomous plan-work-review | ~10 min |
| `/phx:investigate` | Debugging — checks obvious things first | ~3 min |

### Decision Guide

```text
Is it a bug?
  Yes --> /phx:investigate
  No  --> Is it < 100 lines?
            Yes --> /phx:quick
            No  --> Do you want full autonomy?
                      Yes --> /phx:full
                      No  --> /phx:plan then /phx:work
```

### Deepening an Existing Plan

Already have a plan but want to add research or refine tasks?

```bash
/phx:plan --existing .claude/plans/user-avatars/plan.md
```

This spawns specialist agents to analyze your existing plan and enhance it with research findings.

---

## Section 3: Knowledge & Safety Net

### Auto-Loaded Knowledge

The plugin loads relevant reference docs based on what you're editing:

| You're editing... | Plugin loads... |
|-------------------|----------------|
| `*_live.ex` | LiveView patterns, async/streams, components |
| `*_test.exs` | ExUnit patterns, Mox, factory patterns |
| `migrations/*` | Migration patterns, safe operations |
| `*auth*`, `*session*` | Security patterns, authorization rules |
| `router.ex` | Routing patterns, plug patterns, scopes |
| `*_worker.ex` | Oban patterns, idempotency rules |

This means you don't need to explicitly load anything — open a LiveView file and the plugin already knows the patterns.

### Iron Laws (20 Rules, Always Enforced)

Iron Laws are non-negotiable rules that every agent enforces. If your code violates one, the plugin stops and explains before proceeding.

**Examples:**

| Law | Why |
|-----|-----|
| No DB queries in disconnected mount | Would run twice, waste resources |
| Use streams for lists >100 items | Regular assigns = O(n) memory per user |
| No `:float` for money | Floating point math loses precision |
| Pin values with `^` in Ecto queries | Prevents SQL injection |
| Jobs must be idempotent | Oban retries on failure |
| No `String.to_atom` with user input | Atom table exhaustion DoS |
| Authorize in EVERY `handle_event` | Mount auth alone is insufficient |

### Analysis & Verification Commands

| Command | What It Does |
|---------|-------------|
| `/phx:verify` | Full check: compile, format, credo, test, dialyzer |
| `/phx:audit` | 5-agent project health audit with scores |
| `/ecto:n1-check` | Detect N+1 query patterns |
| `/lv:assigns` | Audit LiveView socket assigns for memory |
| `/phx:boundaries` | Check Phoenix context boundary violations |
| `/phx:perf` | Performance analysis (Ecto, LiveView, OTP) |

### Tidewave Integration

When Tidewave MCP is connected to your running Phoenix app:

```bash
# Get docs for your exact dependency versions
mcp__tidewave__get_docs "Ecto.Query"

# Execute code in your running app
mcp__tidewave__project_eval "MyApp.Repo.aggregate(User, :count)"

# Query your dev database directly
mcp__tidewave__execute_sql_query "SELECT count(*) FROM users"
```

The plugin automatically prefers Tidewave tools over alternatives when available.

---

## Section 4: Cheat Sheet & Next Steps

### Command Reference

**Workflow (use in order):**

| Command | Phase |
|---------|-------|
| `/phx:plan <feature>` | Plan with research agents |
| `/phx:plan --existing <file>` | Enhance existing plan |
| `/phx:work <plan file>` | Execute plan with verification |
| `/phx:review` | Parallel agent code review |
| `/phx:triage` | Interactive review finding triage |
| `/phx:compound` | Capture solved problem |

**Standalone:**

| Command | Purpose |
|---------|---------|
| `/phx:quick <task>` | Fast implementation, skip ceremony |
| `/phx:full <feature>` | Autonomous plan-work-review cycle |
| `/phx:investigate <bug>` | Structured bug investigation |
| `/phx:verify` | Run all quality checks |
| `/phx:research <topic>` | Research an Elixir topic |

**Analysis:**

| Command | Purpose |
|---------|---------|
| `/phx:audit` | Full project health audit |
| `/phx:perf` | Performance analysis |
| `/ecto:n1-check` | N+1 query detection |
| `/lv:assigns` | LiveView memory audit |
| `/phx:boundaries` | Context boundary check |
| `/phx:techdebt` | Technical debt analysis |

**Knowledge:**

| Command | Purpose |
|---------|---------|
| `/phx:examples` | Practical walkthroughs |
| `/phx:learn` | Capture a lesson from a fix |
| `/phx:challenge` | Rigorous review mode |

### 3 Tips for Getting the Most Out of the Plugin

1. **Start with `/phx:plan` for any feature that touches multiple files.** The research agents catch architectural issues early, before you've written code that needs rewriting.

2. **Let Iron Laws stop you.** When the plugin flags a violation, read the explanation.
   These rules exist because the Elixir community learned them the hard way
   (atom exhaustion in prod, N+1 queries at scale, double-mount in LiveView).

3. **Use `/phx:compound` after solving hard bugs.** The solution gets indexed and searchable. Next time you hit something similar, the plugin finds your past solution automatically.

### Next Steps

- Try `/phx:plan` with your next feature to see the full workflow
- Run `/phx:verify` to see your project's current health
- Run `/phx:audit` for a comprehensive project assessment
- Check `/phx:examples` for detailed walkthroughs
