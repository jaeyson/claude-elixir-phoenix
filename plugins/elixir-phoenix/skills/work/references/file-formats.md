# Plan & Progress File Formats

## Plan File Format

Plans must follow this structure for parsing:

```markdown
# Plan: {Feature Name}

**Status**: IN_PROGRESS
**Created**: {date}
**Last Updated**: {date}

## Phase 1: {Phase Name} [COMPLETED|IN_PROGRESS|PENDING]

- [x] [P1-T1][ecto] Completed task description — implementation note (key decisions, gotchas)
- [ ] [P1-T2][ecto] Pending task description
- [ ] [P1-T3][direct] Another pending task

## Phase 2: {Phase Name} [PENDING]

### Parallel: {Group Name}

- [ ] [P2-T1][liveview] Task that can run in parallel
- [ ] [P2-T2][liveview] Another parallel task

### Sequential

- [ ] [P2-T3][security] Task that depends on above
```

**Task format**: `- [ ] [Pn-Tm][agent] Description`

- `[Pn-Tm]`: Phase n, Task m (for resume)
- `[agent]`: Agent annotation (for routing)

**Task ID format**: `[Pn-Tm]` - Phase n, Task m. Used for:

- Precise resume: `--from P2-T3`
- Blocker references
- Progress tracking

## Scratchpad File Format

The scratchpad (`.claude/plans/{slug}/scratchpad.md`) captures
decisions, dead-ends, episodes, and ideas. It is the primary
context recovery document on resume.

```markdown
### [14:00] DECISION: Use citext for email
Choice: citext extension. Rationale: case-insensitive by default.
Alternatives rejected: lower() index (fragile), application-level downcase (leaky).

### [14:32] EPISODE: [P1-T2] Add password_hash field
Changed: lib/my_app/accounts/user.ex, priv/repo/migrations/xxx.exs
Learned: Bcrypt.hash_pwd_salt/1 returns 60-char string, use :string not :binary

### [15:10] DEAD-END: Cast assoc with shared tags
Tried: cast_assoc with on_replace: :delete. Failed: duplicate tag inserts.
Attempts: 3. See BLOCKER in progress.md for full error.

### IDEAS BACKLOG
- Try put_assoc with pre-fetched tags instead of cast_assoc
- Consider many_to_many with join table for tag dedup
```

**Pruning rule**: On resume, if a DEAD-END has a corresponding
EPISODE that solved the same problem (later session found a fix),
the DEAD-END is stale. Don't delete it (it's still useful context
for why the first approach failed), but prioritize EPISODE and
IDEAS BACKLOG entries over old DEAD-ENDs when context is tight.

## Progress File Format

```markdown
# Progress: {Feature Name}

**Plan**: .claude/plans/{feature}/plan.md
**Started**: {date}
**Status**: IN_PROGRESS

## Session Log

### {date} {time}

**Task**: {description}
**Result**: PASS | FAIL
**Files**: {list of modified files}
**Notes**: {any observations}

---

### {date} {time}

**Task**: {description}
**Result**: FAIL
**Error**: {error message}
**Retry**: 1/3
**Resolution**: {what was tried}
```
