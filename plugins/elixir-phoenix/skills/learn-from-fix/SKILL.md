---
name: phx:learn
description: Capture lessons learned after fixing a bug or receiving a correction. Updates knowledge base to prevent future mistakes.
argument-hint: <description of what was fixed>
---

# Learn From Fix

After fixing a bug or receiving a correction, capture the lesson to prevent future mistakes.

## Usage

```
/phx:learn Fixed N+1 query in user listing - was missing preload
/phx:learn String vs atom key mismatch in params handling
/phx:learn LiveView assign_async needs render_async in tests
```

## Workflow

### Step 1: Identify the Pattern

Ask yourself:

- What was the root cause? (not the symptom)
- Is this a common mistake others might make?
- Can it be prevented with a simple rule?

### Step 2: Check Existing Knowledge

```bash
# Check if already documented
grep -ri "PATTERN_KEYWORD" plugins/elixir-phoenix/skills/
grep -i "PATTERN_KEYWORD" CLAUDE.md
```

### Step 3: Add Prevention Rule

If not already documented, add to `references/common-mistakes.md`:

```markdown
### Category: [Ecto/LiveView/OTP/Testing/etc]

**Mistake**: [What went wrong]

**Pattern**: Do NOT [bad pattern] - instead [good pattern]

**Example**:

    ```elixir
    # Bad
    bad_code()

    # Good
    good_code()
    ```
```

### Step 4: Consider Broader Updates

If the lesson is significant:

- [ ] Update relevant agent instructions?
- [ ] Add to skill quick reference?
- [ ] Create new test case?

## Categories

| Category | Common Mistakes |
|----------|----------------|
| Ecto | N+1 queries, missing preloads, string vs atom keys |
| LiveView | Blocking mount, missing render_async, stale assigns |
| OTP | Unnecessary processes, missing supervision, bottlenecks |
| Testing | async: false with global mocks, Process.sleep, insert vs build |
| Phoenix | Business logic in controllers, missing CSRF |

## Output

After capturing, confirm:

```text
Lesson captured in references/common-mistakes.md

Pattern: Do NOT use map["key"] for internal data - instead use map.key or Map.get(map, :key)
Category: Ecto
```

## References

See existing lessons: `references/common-mistakes.md`
