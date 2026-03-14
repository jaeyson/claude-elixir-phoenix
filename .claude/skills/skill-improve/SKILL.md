---
name: skill-improve
description: Apply skill improvement recommendations by generating concrete patches. Reads recommendations from /skill-monitor --improve and proposes targeted changes to underperforming skills. Use after skill-effectiveness-analyzer has written recommendations.
argument-hint: "[--apply] [--skill NAME] [--revert PATCH]"
disable-model-invocation: true
---

# Skill Improve

Closes the feedback loop: monitor → analyze → **improve**. Reads
recommendations from the skill-effectiveness-analyzer and produces
reviewable patch proposals for flagged skills.

```
/skill-monitor --improve → recommendations-{date}.md
       ↓
/skill-improve → patches/{date}-{skill}.md (PROPOSED)
       ↓
/skill-improve --apply → patches updated to APPLIED, skill files changed
       ↓
/skill-monitor → verify improvement against regression baseline
```

## Usage

```
/skill-improve                    # Propose patches from latest recommendations
/skill-improve --skill review     # Propose patch for one skill only
/skill-improve --apply            # Apply all PROPOSED patches
/skill-improve --apply --skill X  # Apply one specific patch
/skill-improve --revert X         # Revert an applied patch (restores before)
/skill-improve --status           # Show all patches and their status
```

## What Main Context Does

### Step 1: Parse Arguments

Extract from `$ARGUMENTS`:

- **`--apply`**: Apply proposed patches instead of generating new ones
- **`--skill NAME`**: Focus on one skill
- **`--revert PATCH`**: Revert a previously applied patch
- **`--status`**: Show patch status table

### Step 2: Route by Mode

#### Status Mode (`--status`)

Read all patch files from `.claude/skill-metrics/patches/`:

```
| Patch | Skill | Date | Status | Evidence |
|-------|-------|------|--------|----------|
| 2026-03-14-review | review | 2026-03-14 | PROPOSED | STRONG (5) |
| 2026-03-10-investigate | investigate | 2026-03-10 | APPLIED | MODERATE (3) |
```

Show regression check: if a patch is APPLIED, compare current dashboard
metrics against the regression baseline stored in the patch file.

#### Revert Mode (`--revert`)

1. Read the patch file
2. Verify status is APPLIED
3. Read the "Before" section from the patch
4. Write the original content back to the target file
5. Update patch status to REVERTED with timestamp
6. Log revert to `.claude/skill-metrics/applied-patches.jsonl`

#### Propose Mode (default)

Continue to Step 3.

#### Apply Mode (`--apply`)

Skip to Step 5.

### Step 3: Find Latest Recommendations

Glob `.claude/skill-metrics/recommendations-*.md`, pick most recent.

If none found: "No recommendations found. Run `/skill-monitor --improve` first."

If `--skill` specified, filter to that skill's recommendations only.

### Step 4: Spawn Skill Improver Agent

```
Agent(subagent_type="skill-improver", model="sonnet", prompt="""
Read recommendations and propose patches for flagged skills.

Recommendations file: {recommendations_path}
Mode: propose
Skill filter: {skill_name or "all"}

Read the recommendation file, then for each flagged skill:
1. Read the current skill/agent file
2. Generate a patch proposal following the patch template
3. Write to .claude/skill-metrics/patches/{date}-{skill}.md

Include regression baseline from latest dashboard:
{dashboard_path}
""")
```

### Step 5: Apply Mode

When `--apply` is specified:

1. Glob `.claude/skill-metrics/patches/*.md` for PROPOSED patches
2. If `--skill` specified, filter to that skill
3. For each PROPOSED patch:

```
Agent(subagent_type="skill-improver", model="sonnet", prompt="""
Apply the proposed patch.

Patch file: {patch_path}
Mode: apply

Read the patch, verify it's PROPOSED, apply the changes to the
target file, update patch status to APPLIED.
""")
```

4. After applying, show summary with next steps

### Step 6: Output Summary

Display results:

```
## Skill Improvement Results

{patches proposed or applied}

### Next Steps
- Propose mode: Review patches in .claude/skill-metrics/patches/
- Apply mode: Use improved skills for 5+ sessions, then /skill-monitor
```

## Iron Laws

1. **NEVER auto-apply without `--apply` flag** — patches are proposals only
2. **Skip WEAK evidence** — only patch skills with 3+ sessions of data
3. **Preserve Iron Laws** — never weaken or remove safety rules
4. **One patch per skill per run** — apply, measure, then iterate
5. **Regression baseline required** — every patch records metrics to compare against

## Integration

```
/session-scan → metrics.jsonl
       ↓
/skill-monitor --improve → recommendations-{date}.md
       ↓
/skill-improve → patches/{date}-{skill}.md
       ↓
/skill-improve --apply → skill files updated
       ↓
(use skills for 5+ sessions)
       ↓
/skill-monitor → verify against regression baseline
       ↓
/skill-improve --revert (if regression detected)
```
