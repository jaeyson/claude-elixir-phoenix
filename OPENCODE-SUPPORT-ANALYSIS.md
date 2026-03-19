# Deep Analysis: Adding OpenCode Support to the Elixir/Phoenix Plugin

## Executive Summary

OpenCode (opencode.ai, 45k+ GitHub stars, 650k+ monthly users) is an open-source AI coding agent with a plugin architecture that shares **significant structural overlap** with Claude Code — but diverges in critical areas. This analysis maps every plugin feature to its OpenCode equivalent, identifies gaps, and proposes a concrete implementation strategy.

**Bottom line**: ~60% of the plugin content (agents, skills, SKILL.md files) can be shared with minimal adaptation. The remaining ~40% (hooks, plugin manifest, distribution) requires an OpenCode-native implementation layer. A **dual-target build** approach is recommended.

---

## 1. Feature-by-Feature Compatibility Matrix

| Plugin Feature | Claude Code | OpenCode | Compatibility | Effort |
|---|---|---|---|---|
| **Plugin manifest** | `.claude-plugin/plugin.json` | `opencode.json` config | Different format | Medium |
| **Marketplace** | `marketplace.json` | npm packages or local dirs | Completely different | High |
| **Agent definitions** | Markdown + YAML frontmatter | Markdown + YAML frontmatter | ~70% compatible | Medium |
| **Skills** | `SKILL.md` + `references/` | `SKILL.md` (no `references/`) | ~80% compatible | Low |
| **Hooks** | `hooks.json` + shell scripts | JS/TS plugin modules | Completely different | High |
| **Custom commands** | Skills with `user-invocable: true` | `.md` files in `commands/` | Different structure | Medium |
| **Model selection** | `opus`/`sonnet`/`haiku` | `provider/model-id` | Mapping needed | Low |
| **Tool permissions** | `disallowedTools` + `permissionMode` | `permission` object (ask/allow/deny) | Different schema | Medium |
| **Subagent spawning** | `Agent()` tool, `run_in_background` | `task` permission + `@` mentions | Similar concept, different API | Medium |
| **MCP support** | Native | Native (in `opencode.json`) | Compatible | Low |
| **Context compaction** | `PreCompact` hook + `systemMessage` | Plugin `compaction` hook | Different mechanism | Medium |
| **Memory/persistence** | `memory: project` field | No direct equivalent | Gap | High |
| **Skill auto-loading** | `skills:` field in agent frontmatter | No equivalent (agents call `skill` tool) | Gap | Medium |
| **Project instructions** | `CLAUDE.md` | `AGENTS.md` (falls back to `CLAUDE.md`) | Compatible | None |

---

## 2. Deep Dive: What Changes Per Component

### 2.1 Agents (20 agents — Medium effort)

**What's shared**: The markdown body (system prompt content) is 100% reusable. Iron Laws, domain expertise, review patterns — all portable.

**What changes in frontmatter**:

```yaml
# Claude Code (current)
---
name: elixir-reviewer
description: "Specialist Elixir code reviewer..."
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
permissionMode: bypassPermissions
model: sonnet
memory: project
skills:
  - elixir-idioms
  - phoenix-contexts
---

# OpenCode (target)
---
description: "Specialist Elixir code reviewer..."
mode: subagent
model: anthropic/claude-sonnet-4-6
permission:
  edit: deny
  write: deny
  bash:
    "*": allow
  task:
    "*": deny
---
```

**Key differences**:

| Field | Claude Code | OpenCode | Migration |
|-------|------------|----------|-----------|
| `name` | In frontmatter | Derived from filename | Remove from frontmatter |
| `tools` / `disallowedTools` | Allowlist/blocklist | `permission` object with ask/allow/deny | Rewrite per agent |
| `permissionMode` | `bypassPermissions` | No equivalent — use `allow` on all needed permissions | Permission object per agent |
| `model` | `sonnet`/`opus`/`haiku` | `anthropic/claude-sonnet-4-6` etc. | Model name mapping |
| `memory: project` | Cross-session learning | No equivalent | **Gap** — needs workaround |
| `skills:` | Auto-loads SKILL.md into context | Not supported — agent must call `skill` tool | Inline critical content or add instructions to call skills |
| `maxTurns` | Limits iterations | `steps` field | Rename |
| N/A | N/A | `mode: primary\|subagent` | New required field |
| N/A | N/A | `temperature`, `top_p` | Optional tuning |

**Critical gap — `skills:` auto-loading**: In Claude Code, the `skills:` field preloads skill content into the agent's system prompt. OpenCode has no equivalent — agents must explicitly call the `skill` tool at runtime. This means:
- Iron Laws won't be automatically available to agents
- Domain knowledge requires an explicit tool call before use
- Mitigation: Inline critical Iron Laws directly in agent prompts, or add "Before starting, load these skills: elixir-idioms, phoenix-contexts" to agent instructions

**Critical gap — `memory: project`**: Only 3 agents use this (orchestrators). OpenCode has no cross-session persistence for agents. Mitigation: Use filesystem-based state (scratchpad.md already exists) and instruct agents to read/write it.

### 2.2 Skills (38 skills — Low effort)

**Great news**: OpenCode's skill system is nearly identical to Claude Code's.

| Aspect | Claude Code | OpenCode | Compatible? |
|--------|------------|----------|-------------|
| File structure | `skills/{name}/SKILL.md` | `skills/{name}/SKILL.md` | Yes |
| Search paths | `.claude/skills/` | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` | Yes (reads `.claude/`) |
| Frontmatter: `name` | Required | Required | Yes |
| Frontmatter: `description` | Required | Required (1-1024 chars) | Yes |
| Frontmatter: `user-invocable` | Controls slash command visibility | N/A (commands are separate) | Different |
| Frontmatter: `argument-hint` | Shows argument placeholder | N/A | Drop |
| Frontmatter: `disable-model-invocation` | Prevents auto-triggering | N/A | Drop |
| `references/` subdirectory | Detailed docs agents can Read | Not documented | **Unknown** — may still work if agents can Read files |
| Loading mechanism | Auto-load via `skills:` or `description` match | On-demand via `skill` tool | Different trigger |

**What needs to change**:
- Remove Claude Code-specific frontmatter fields (`user-invocable`, `argument-hint`, `disable-model-invocation`)
- Skills that serve as slash commands need corresponding `commands/` entries in OpenCode
- `references/` files should still work if agents have Read access (OpenCode agents do have `read` tool)

### 2.3 Hooks → Plugins (18 hooks — High effort, complete rewrite)

This is the **biggest incompatibility**. Claude Code uses `hooks.json` pointing to shell scripts. OpenCode uses a JavaScript/TypeScript plugin system.

**Claude Code hooks.json structure**:
```json
{
  "hooks": {
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "scripts/format-elixir.sh" }] }]
  }
}
```

**OpenCode plugin structure**:
```typescript
import type { Plugin } from "@opencode-ai/plugin"

export const ElixirPhoenixPlugin: Plugin = async (ctx) => {
  return {
    hooks: {
      "tool.call.after": async (event) => {
        if (event.tool === "edit" || event.tool === "write") {
          // Run mix format --check-formatted
          await ctx.shell`mix format --check-formatted ${event.file}`
        }
      }
    }
  }
}
```

**Hook event mapping**:

| Claude Code Event | OpenCode Equivalent | Notes |
|-------------------|---------------------|-------|
| `PreToolUse` | `tool.call.before` | Block dangerous ops |
| `PostToolUse` | `tool.call.after` | Format, verify, Iron Laws |
| `PostToolUseFailure` | `tool.call.error` (if exists) | Error critic pattern |
| `SubagentStart` | `task.start` or similar | Iron Laws injection |
| `SessionStart` | `session.start` | Setup dirs, resume detection |
| `PreCompact` | `compaction` hook | Workflow rule preservation |
| `Stop` | `session.end` | Pending task warning |

**Rewrite strategy**: Each shell script becomes a TypeScript function. The logic is portable (regex checks, file scanning), but the integration mechanism is completely different.

**Context injection patterns** differ significantly:

| Claude Code | OpenCode |
|------------|----------|
| stderr + `exit 2` → feeds message to LLM | Plugin return value → context injection |
| `hookSpecificOutput.additionalContext` | Plugin hook return value |
| `systemMessage` (survives compaction) | Compaction hook customization |
| stdout visible only for SessionStart | Plugin hooks have direct context access |

### 2.4 Custom Commands (Slash Commands — Medium effort)

Claude Code derives commands from skills with `user-invocable: true`. OpenCode uses separate `commands/` directories.

**Migration**: Each `/phx:*` command needs a corresponding `.md` file:

```yaml
# .opencode/commands/phx-plan.md
---
description: "Create a structured implementation plan for an Elixir/Phoenix feature"
agent: planning-orchestrator
---
$ARGUMENTS
```

All 15+ user-invocable skills would need command wrappers.

### 2.5 Plugin Distribution (High effort)

| Aspect | Claude Code | OpenCode |
|--------|------------|----------|
| Format | `.claude-plugin/plugin.json` | npm package or local directory |
| Discovery | Marketplace JSON registry | npm registry or manual path |
| Install | `/plugin install` | Config in `opencode.json` |
| Caching | Version-gated | npm caching via Bun |

**OpenCode distribution options**:
1. **npm package**: `@oliver-kriska/opencode-elixir-phoenix` — requires packaging as JS/TS
2. **Local directory**: `.opencode/plugins/elixir-phoenix.ts` — simpler but not distributable
3. **Hybrid**: npm for the plugin (hooks/tools), Git for agents/skills/commands

### 2.6 Model Name Mapping

| Claude Code | OpenCode Equivalent |
|-------------|-------------------|
| `opus` | `anthropic/claude-opus-4-6` |
| `sonnet` | `anthropic/claude-sonnet-4-6` |
| `haiku` | `anthropic/claude-haiku-4-5-20251001` |

Simple string replacement in agent frontmatter. Could also support other providers (e.g., `openai/gpt-4o` for some specialist agents).

---

## 3. Architecture: Dual-Target Build Strategy

### Option A: Separate Distributions (Recommended)

```
claude-elixir-phoenix/
├── shared/                          # Portable content
│   ├── agents/                      # Agent markdown bodies (no frontmatter)
│   ├── skills/                      # SKILL.md + references/
│   └── solutions/                   # Compound knowledge
├── targets/
│   ├── claude-code/                 # Claude Code-specific
│   │   ├── .claude-plugin/
│   │   ├── agents/                  # Frontmatter wrappers → shared/agents/
│   │   ├── hooks/                   # hooks.json + shell scripts
│   │   └── skills/                  # With user-invocable fields
│   └── opencode/                    # OpenCode-specific
│       ├── agents/                  # Frontmatter wrappers → shared/agents/
│       ├── commands/                # Slash command .md files
│       ├── plugins/                 # TypeScript plugin (hooks equivalent)
│       └── skills/                  # Clean frontmatter
└── scripts/
    └── build.sh                     # Assembles target-specific distributions
```

**Pros**: Clean separation, each target gets optimized output
**Cons**: Build step required, more files to maintain

### Option B: Single Source with Adapters

Keep current structure, add an OpenCode adapter layer:

```
plugins/elixir-phoenix/
├── agents/                          # Claude Code frontmatter (primary)
├── skills/                          # Claude Code skills (primary)
├── hooks/                           # Claude Code hooks
└── opencode/                        # OpenCode adapter
    ├── plugin.ts                    # Hooks rewritten as TS plugin
    ├── commands/                    # Command wrappers for skills
    └── build-agents.sh             # Transform agent frontmatter
```

**Pros**: Less restructuring, single source of truth for content
**Cons**: Adapter complexity, potential drift

### Option C: OpenCode Plugin Package (npm)

Package the entire thing as an npm module:

```
opencode-elixir-phoenix/
├── package.json
├── src/
│   └── plugin.ts                    # All hooks as TypeScript
├── agents/                          # OpenCode-format agents
├── skills/                          # Shared skills
└── commands/                        # Slash commands
```

**Pros**: Native OpenCode distribution, clean for users
**Cons**: Separate repo/package, dual maintenance

---

## 4. Implementation Phases

### Phase 1: Foundation (1-2 weeks)

- [ ] Create OpenCode agent frontmatter transformer (script)
- [ ] Map all 20 agents' frontmatter to OpenCode format
- [ ] Verify skills work in OpenCode's `.claude/skills/` fallback path
- [ ] Create `commands/` wrappers for all 15+ user-invocable skills
- [ ] Set up basic `opencode.json` configuration

### Phase 2: Hooks → Plugin (2-3 weeks)

- [ ] Create TypeScript plugin scaffold (`@opencode-ai/plugin` types)
- [ ] Port `format-elixir.sh` → `tool.call.after` hook
- [ ] Port `iron-law-verifier.sh` → `tool.call.after` hook
- [ ] Port `block-dangerous-ops.sh` → `tool.call.before` hook
- [ ] Port `security-reminder.sh` → `tool.call.after` hook
- [ ] Port `debug-statement-warning.sh` → `tool.call.after` hook
- [ ] Port `elixir-failure-hints.sh` → tool error hook
- [ ] Port `error-critic.sh` → tool error hook (with state tracking)
- [ ] Port `inject-iron-laws.sh` → subagent start hook
- [ ] Port `setup-dirs.sh` + session hooks → `session.start`
- [ ] Port `precompact-rules.sh` → compaction hook
- [ ] Port `check-pending-plans.sh` → `session.end`

### Phase 3: Orchestration Validation (1 week)

- [ ] Test planning-orchestrator subagent spawning in OpenCode
- [ ] Test parallel-reviewer multi-agent pattern
- [ ] Test context-supervisor compression flow
- [ ] Validate workflow state machine (plan → work → review → compound)
- [ ] Test `memory: project` workaround (filesystem-based state)

### Phase 4: Distribution (1 week)

- [ ] Decide on distribution format (npm package vs local)
- [ ] Package for OpenCode marketplace/registry
- [ ] Write OpenCode-specific installation docs
- [ ] Create AGENTS.md equivalent of CLAUDE.md behavioral instructions
- [ ] Test end-to-end on a real Elixir/Phoenix project

---

## 5. Risk Assessment

### High Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **No `skills:` auto-loading** | Agents lose domain knowledge, Iron Laws not enforced | Inline critical rules in agent prompts; add "load skill X" instructions |
| **Hook output injection differs** | Can't feed context back to LLM the same way | Study OpenCode plugin return values; may need different patterns |
| **Subagent spawning differences** | Orchestrator pattern may break | Test early; may need to restructure orchestrators for OpenCode's task system |
| **No `memory: project`** | Orchestrators can't learn across sessions | Use `.opencode/state/` files for persistence |

### Medium Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| **`references/` not documented** | Detailed skill docs may not be discoverable | Test if agents can Read from skill directories in OpenCode |
| **Permission model mismatch** | Agents may get blocked or have too much access | Careful per-agent permission mapping |
| **40+ OpenCode events vs 7 Claude Code events** | May miss useful hooks or mismap events | Study OpenCode plugin docs thoroughly |
| **OpenCode rapid evolution** | API may change (project is very active) | Pin to specific OpenCode version, add compat tests |

### Low Risk

| Risk | Impact | Mitigation |
|------|--------|------------|
| Model naming | Simple string mapping | Build-time transformation |
| CLAUDE.md → AGENTS.md | OpenCode reads CLAUDE.md as fallback | Works as-is; optionally create AGENTS.md |
| MCP (Tidewave) | Both support MCP natively | Configuration format differs slightly |

---

## 6. Effort Estimate

| Component | Files to Change/Create | Estimated Effort |
|-----------|----------------------|------------------|
| Agent frontmatter transforms | 20 agents | 2-3 days |
| Skill compatibility | 38 skills (mostly compatible) | 1-2 days |
| Command wrappers | ~15 commands | 1-2 days |
| TypeScript plugin (hooks) | 1 plugin + 12 hook functions | 5-8 days |
| Orchestrator adaptation | 5 orchestrators | 3-5 days |
| Distribution packaging | Package config + docs | 2-3 days |
| Testing & validation | End-to-end on real project | 3-5 days |
| **Total** | | **~3-5 weeks** |

---

## 7. Recommendations

1. **Start with skills** — They're ~80% compatible. Get them working in OpenCode first to validate the path.

2. **Build the TypeScript plugin early** — The hooks are the hardest part. Start with `format-elixir` and `iron-law-verifier` as proof of concept.

3. **Don't restructure the repo yet** — Use Option B (adapter layer) initially. Only move to Option A (dual-target build) if the adapter gets unwieldy.

4. **Solve the `skills:` gap creatively** — Consider adding a "preamble" section to each OpenCode agent that says: "Before starting any task, load these skills: [list]. Apply their Iron Laws as non-negotiable constraints."

5. **Contribute upstream** — OpenCode is open-source. Features like `skills:` auto-loading in agent frontmatter would benefit the ecosystem. File feature requests.

6. **Test with real users early** — The workflow orchestration (plan → work → review) is the plugin's core value. Validate it works in OpenCode before polishing edges.

7. **Consider a shared AGENTS.md** — Since OpenCode reads `CLAUDE.md` as fallback, the behavioral instructions in CLAUDE.md already work. Create an `AGENTS.md` only if OpenCode-specific instructions are needed.

---

## 8. What We Get For Free

These features work in OpenCode **without any changes**:

- `CLAUDE.md` behavioral instructions (OpenCode reads as fallback)
- Skills in `.claude/skills/` (OpenCode searches this path)
- MCP server support (Tidewave)
- Compound knowledge in `.claude/solutions/` (just filesystem)
- Plan/progress/scratchpad files (just filesystem)
- Iron Laws content (portable markdown)
- All reference documentation content

---

## 9. What Requires Complete Rewrite

These features have **no direct equivalent** and need ground-up implementation:

1. **hooks.json → TypeScript plugin** (12 hook scripts → 1 plugin module)
2. **Plugin distribution** (marketplace.json → npm package)
3. **Agent frontmatter** (every agent needs new frontmatter)
4. **SubagentStart context injection** (additionalContext → plugin hook)
5. **PreCompact systemMessage** (→ compaction hook)
6. **Skill-driven slash commands** (user-invocable → commands/ directory)

---

## 10. Open Questions

1. **Does OpenCode support `references/` in skills?** — Not documented. Need to test empirically.
2. **Can OpenCode plugins inject context into subagent prompts?** — Critical for Iron Laws enforcement.
3. **How does OpenCode handle parallel subagent execution?** — Need to test orchestrator pattern.
4. **Is there an equivalent to `run_in_background`?** — Subagent concurrency model unclear.
5. **Can OpenCode plugins add custom tools?** — Docs say yes (Zod schemas). Could replace some hooks.
6. **What's the OpenCode plugin versioning story?** — npm semver? Auto-updates?
7. **Does OpenCode support `disable-model-invocation` equivalent?** — Preventing auto-trigger of orchestrator skills.
