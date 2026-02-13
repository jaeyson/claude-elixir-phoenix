---
name: phx:triage
description: Interactive triage of review findings. Present each finding for human decision — approve, skip, or customize priority. Use after /phx:review to filter findings before fixing.
argument-hint: [path to review file]
---

# Triage — Interactive Review Resolution

Walk through review findings one by one for human decision before
committing to fixes.

## Usage

```
/phx:triage .claude/plans/user-auth/reviews/user-auth-review.md
/phx:triage                  # Uses most recent review
```

## Why Triage

After `/phx:review` produces findings, you have three options:

1. **Fix everything** — `/phx:plan .claude/plans/{slug}/reviews/...`
2. **Triage first** — `/phx:triage` (filter, then fix what matters)
3. **Handle manually** — Read review, pick what to fix yourself

Best when review has 5+ findings and you want to prioritize.

## Workflow

### Step 1: Load Review

Read the review file. Parse all findings with severity.

**Auto-approve Iron Law violations**: Findings matching the 13
Iron Laws are auto-approved as "Fix it" without asking. These
are non-negotiable in Elixir/Phoenix development.

### Step 2: Present Findings One at a Time

For each non-auto-approved finding:

```
Finding 1 of N: [SEVERITY] Title
File: {file path and line}

{Brief description}

1. Fix it    2. Skip    3. Downgrade    4. Need more info
```

Order: BLOCKERs first, then WARNINGs, then SUGGESTIONs.

### Step 3: Gather Context on "Fix it" Items

When user approves, ask ONE follow-up: "Any specific approach?"
If they say "just fix it", skip and move on.

### Step 4: Generate Triage Summary

Write to `.claude/plans/{slug}/reviews/{slug}-triage.md` with Fix Queue
(approved items with checkboxes), Skipped, and Deferred sections.

### Step 5: Present Next Steps

```
Triage complete: {n} to fix, {n} skipped, {n} deferred.

1. Plan fixes — /phx:plan .claude/plans/{slug}/reviews/{slug}-triage.md
2. Fix directly — /phx:work (for simple fixes)
3. Review deferred items later
```

## Iron Laws

1. **ONE finding at a time** — Never dump all findings at once
2. **User decides, not the agent** — Present facts, don't push
3. **BLOCKERs cannot be skipped silently** — Warn if user tries
4. **Capture user context** — Every "fix it" should include
   any user guidance for better fixes

## Integration with Workflow

```text
/phx:review
       |
/phx:triage  ← YOU ARE HERE (interactive filtering)
       |
/phx:plan (with triage file) → /phx:work → /phx:compound
```

## References

- `references/triage-patterns.md` — Common triage decisions
