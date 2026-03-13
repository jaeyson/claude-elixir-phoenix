---
name: phx:work
description: Use after /phx:plan to systematically implement features, or with --continue to resume interrupted work. Executes plan tasks with progress tracking and verification after each step.
argument-hint: <path to plan file>
---

# Work

Execute tasks from a plan file with checkpoint tracking and verification.

## Usage

```
/phx:work .claude/plans/user-auth/plan.md
/phx:work .claude/plans/user-auth/plan.md --from P2-T3
/phx:work --skip-blockers
/phx:work  # Resumes most recent plan
```

## Arguments

- `<plan-file>` -- Path to plan file (optional, auto-detects recent)
- `--from <task-id>` -- Resume from specific task (e.g., `P2-T3`)
- `--skip-blockers` -- Continue past blocked tasks
- `--continue` -- Resume IN_PROGRESS plan from checkboxes

## Iron Laws (NON-NEGOTIABLE)

1. **NEVER auto-proceed** to /phx:review or any next workflow
   phase -- always ask the user what to do next
2. **AUTO-CONTINUE between plan phases** -- when Phase N completes,
   immediately start Phase N+1. Do NOT stop or ask for permission
   between phases. Only stop at BLOCKERS or when ALL phases are done.
3. **Plan checkboxes ARE the state** -- `[x]` = done, `[ ]` = pending.
   No separate JSON state files. Resume by reading the plan.
4. **Verify after EVERY task** -- never skip verification
5. **Max 3 retries then BLOCKER** -- don't keep retrying forever
6. **Stage specific files** -- never use `git add -A` or `git add .`
7. **Read scratchpad BEFORE implementing** -- scratchpad has dead-ends,
   decisions, and ideas backlog that prevent rework. Step 2 is not optional.
8. **Clarify ambiguous tasks** -- ask the user rather than guessing
   when a plan task's intent is unclear
9. **Don't thrash** -- if 2+ attempts at the same approach fail,
   write a DEAD-END to scratchpad and try something structurally
   different. Repeatedly reverting the same idea wastes context.
10. **Checkpoint after each task** -- commit passing work before
    moving to next task. If a task breaks tests and the fix isn't
    obvious after 3 retries, revert to last checkpoint and log
    as BLOCKER (see Step 4 checkpoint pattern).

## Step 1: Research Decision

For plans with >3 tasks, ask the user:

> This plan has {count} remaining tasks across {count} phases.
>
> 1. **Start working** -- Begin immediately (familiar patterns)
> 2. **Quick research** -- Read source files first (~10 min)
> 3. **Extensive research** -- Web search + docs (~30 min)

Skip for plans with 3 or fewer simple tasks -- just start.

> **Split warning**: Plans with >10 tasks risk 2-3 context
> compactions. Suggest splitting via `/phx:plan` if not already.

## Step 2: Check Context (MANDATORY)

Read scratchpad and compound docs before writing any code.
Skipping this causes rework — scratchpad captures dead-ends,
decisions, and ideas backlog from prior sessions.

```bash
# Read full scratchpad — it's short and has critical context
cat .claude/plans/{slug}/scratchpad.md 2>/dev/null
# Check compound docs for solved patterns
grep -rl "KEYWORD" .claude/solutions/ 2>/dev/null
```

Apply findings: skip dead-ends, follow decisions, reuse patterns.
**Check IDEAS BACKLOG** — if prior sessions logged promising
alternative approaches, prioritize those over re-trying failed
paths. If a task's intent is ambiguous, ask the user before
implementing rather than guessing — corrections are expensive.

## Step 3: Load, Create Task List, and Resume

Read plan file, count `[x]` (completed) vs `[ ]` (remaining).
Find first unchecked task by `[Pn-Tm]` ID.

**Create Claude Code tasks** from ALL unchecked plan items using
`TaskCreate`. This gives real-time progress visibility in the UI:

```
For each unchecked `- [ ] [Pn-Tm] Description`:
  TaskCreate({
    subject: "[Pn-Tm] Description",
    description: "Full task details from plan",
    activeForm: "Implementing: Description"
  })
```

Already-checked items (`[x]`): skip, don't create tasks for them.
Set up `blockedBy` dependencies between phases (Phase 2 tasks
blocked by Phase 1 tasks).

With `--from P2-T3`: Skip to that specific task.

See `references/resume-strategies.md` for all resume modes.

## Step 4: Execute Tasks

For each unchecked task (`- [ ] [Pn-Tm][agent] Description`):

1. **Start task**: `TaskUpdate({taskId, status: "in_progress"})`
2. **Route** by `[agent]` annotation (see `references/execution-guide.md`)
3. **Implement** the task
4. **Verify**: `mix format` + `mix compile --warnings-as-errors`
   (at phase end, also run `mix test <affected>` — see tiers below)
5. **Checkpoint** (keep/discard decision):
   - **Keep** (tests pass): Mark checkbox `[x]`, **append
     implementation note** inline, commit with
     `git commit -m "WIP: [Pn-Tm] description"`, AND
     `TaskUpdate({taskId, status: "completed"})`. Example:
     `- [x] [P1-T3] Add user schema — citext for email, composite index`
   - **Discard** (tests fail after 3 retries): Revert to last
     checkpoint (`git checkout -- .`), create BLOCKER, write
     DEAD-END to scratchpad (see error-recovery.md)
   - **Anti-thrash**: If reverting the same idea twice, stop and
     try a structurally different approach. Write to scratchpad
     IDEAS BACKLOG with alternative approaches to explore.
6. This survives context compaction; the plan is re-read on resume.

**Parallel groups**: Tasks under `### Parallel:` header spawn
as background subagents. See `references/execution-guide.md`
for spawning pattern, prompt template, and checkpoint flow.

**Verification tiers**:

- Per-task: `mix format` + `mix compile --warnings-as-errors`
  (when Tidewave available, also check `get_logs :error` after edits)
- Per-phase: above + `mix test <affected>` + `mix credo --strict`
- Per-feature (Tidewave): behavioral smoke test via `project_eval`
  (create record, fetch, verify -- see execution-guide.md)
- Final gate: `mix test` (full suite)

> **Linter note**: The PostToolUse hook checks formatting but does
> NOT modify files. Run `mix format` explicitly during verification
> steps or before committing.

## Step 5: Completion

Summarize results with `AskUserQuestion`:

> Implementation complete! {done}/{total} tasks finished.
> {count} files modified across {count} phases.

Options: 1. **Run review** (`/phx:review`) (Recommended),
2. **Get a briefing** (`/phx:brief` — understand what was built),
3. **Commit changes** (`/commit`), 4. **Continue manually**.

With blockers: list them, offer **Replan** (`/phx:plan`),
**Review first** (`/phx:review`), or **Handle myself**.

**If blockers remain**, auto-write HANDOFF to scratchpad:

```markdown
### [HH:MM] HANDOFF: {plan name}
Status: {done}/{total} tasks. Blockers: {list}.
Next: {first unchecked task ID and description}.
Key decisions: {brief list from this session}.

### IDEAS BACKLOG
- {promising approach not yet tried}
- {alternative strategy suggested during debugging}
```

This gives a fresh session context beyond just checkboxes.
The IDEAS BACKLOG persists deferred approaches across context
resets — a fresh agent reads it on resume and prioritizes
from the backlog instead of re-discovering paths from scratch.

**NEVER** auto-start /phx:review or any other phase.

## Step 6: Check for Additional Plans

After completion, check for other pending plans:

```bash
ls .claude/plans/*/plan.md 2>/dev/null
```

If pending plans exist, inform the user. Do NOT auto-start.

## Integration

```text
/phx:plan → /phx:work (YOU ARE HERE) → /phx:review → /phx:compound
                 ↑ ASK USER before each transition
```

## References

- `references/execution-guide.md` -- Task routing, parallel execution, verification
- `references/resume-strategies.md` -- Resume modes and state persistence
- `references/file-formats.md` -- Plan and progress file formats
- `references/error-recovery.md` -- Error handling and blockers
- `references/harness-patterns.md` -- Critic-refiner pattern for debugging loops
