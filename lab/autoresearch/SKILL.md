---
name: lab:autoresearch
description: >
  Self-improving loop for plugin skills. Reads program.md, proposes one
  mutation per iteration, evaluates against deterministic scorer, keeps
  improvements via git, reverts failures. Targets weakest skill+dimension.
  Use with /loop for overnight runs.
effort: high
argument-hint: "[--skill NAME] [--strategy targeted|sweep|random] [--dry-run] [--max-iterations N]"
disable-model-invocation: true
---

# Autoresearch — Plugin Skill Self-Improvement

Iteratively improve plugin skills via the autoresearch pattern:
propose one mutation -> eval -> keep/revert -> repeat.

## Usage

```
/lab:autoresearch                           # Targeted: attack weakest skill+dimension
/lab:autoresearch --skill review            # Focus on one skill
/lab:autoresearch --strategy sweep          # Process all skills alphabetically
/lab:autoresearch --dry-run                 # Show what would change, don't commit
/lab:autoresearch --max-iterations 50       # Override default limit (20)
```

For overnight runs:

```
/loop 5m /lab:autoresearch --strategy sweep --max-iterations 200
```

## Arguments

| Arg | Default | Description |
|-----|---------|-------------|
| `--skill` | (auto) | Target specific skill name |
| `--strategy` | `targeted` | `targeted` (weakest first), `sweep` (alphabetical), `random` |
| `--dry-run` | false | Propose mutation but don't apply or commit |
| `--max-iterations` | 20 | Hard stop after N iterations |

## Iron Laws

1. **ONE mutation per iteration** — if description needs "and", split into two iterations
2. **NEVER mutate read-only files** — check program.md before every write
3. **COMMIT before eval** — enables clean revert via `git checkout --`
4. **EVAL is deterministic** — always use `python3 -m lab.eval.scorer`, never LLM-judge
5. **REVERT on regression** — no exceptions, no "but it looks better"
6. **LOG every iteration** — append to results.tsv even on discard

## Core Loop (ONE iteration)

Execute these steps in order. Do NOT skip steps.

### Step 1: Read State

1. Read `lab/autoresearch/program.md` (goals, mutable surface, rules)
2. Read `lab/autoresearch/autoresearch.md` if it exists (iteration count, scores, stuck skills)
3. Read last 5 lines of `lab/autoresearch/results.tsv` if it exists (recent history)

### Step 2: Select Target

**Targeted strategy** (default):

- Read current scores from autoresearch.md (or run scorer on all target skills)
- Find skill+dimension with LOWEST score
- Skip skills in the "stuck" list

**Sweep strategy**: Process skills alphabetically, improve weakest dimension per skill.
**Random strategy**: Pick random skill + random dimension.

### Step 3: Read Current Skill

Read the target `SKILL.md` and its `references/` directory listing.
Read the eval definition from `lab/eval/evals/{skill}.json` if it exists.
Identify which specific checks are failing (from the scorer output).

### Step 4: Propose ONE Mutation

Based on the failing checks, propose exactly ONE change.
Consult `${CLAUDE_SKILL_DIR}/references/mutation-strategies.md` for mutation types.

Rules:

- Target the specific failing check(s) for the weakest dimension
- Check recent results.tsv — do NOT retry a mutation that was already discarded
- Prefer deletions/compressions over additions (simplicity criterion)
- If last discard was on this skill: analyze WHY it failed before proposing

### Step 5: Apply or Dry-Run

**If `--dry-run`**: Print the proposed change and expected impact. STOP.

**If real run**:

1. Apply the mutation via Edit tool
2. Run: `python3 -m lab.eval.scorer {skill_path}`
3. Parse the JSON output — extract composite score

### Step 6: Keep or Revert

Compare `new_composite` against `previous_best_composite` (from autoresearch.md):

**If improved or tied** (keep):

```bash
git add plugins/elixir-phoenix/skills/{skill}/
git commit -m "autoresearch: {skill} {dimension} {old:.3f}->{new:.3f}"
```

**If regressed** (revert):

```bash
git checkout -- plugins/elixir-phoenix/skills/{skill}/
```

### Step 7: Journal

Append one line to `lab/autoresearch/results.tsv`:

```
{iteration}\t{skill}\t{dimension}\t{mutation_type}\t{old_composite}\t{new_composite}\t{kept}\t{timestamp}\t{description}
```

### Step 8: Update State

Write `lab/autoresearch/autoresearch.md` with:

- Current iteration number
- Per-skill best scores
- Consecutive discard count
- Stuck skills list
- Last mutation summary

### Step 9: Continue or Stop

Check stop conditions from program.md:

- All targets >= 0.95? Print "AUTORESEARCH_COMPLETE" and stop
- Max iterations reached? Print "AUTORESEARCH_COMPLETE" and stop
- 50 consecutive discards? Print "AUTORESEARCH_STUCK" and stop

Otherwise: **immediately start Step 1 again** (next iteration).

## Output Quarantine

CRITICAL: When running the scorer, only parse the composite score from JSON output.
Do NOT paste full scorer output into context (wastes tokens over 50+ iterations).

## References

- `${CLAUDE_SKILL_DIR}/references/mutation-strategies.md` — mutation type catalog
- `${CLAUDE_SKILL_DIR}/references/state-management.md` — git protocol, journaling
- `lab/autoresearch/program.md` — research agenda (read every iteration)
