---
name: phx:babysit-ci
description: Monitor GitHub Actions CI runs, detect flaky test failures, retry on transient errors, and report real failures with context. Use after pushing a branch, when CI is running and you want automated monitoring, or when the user says "watch CI", "babysit the PR", "monitor the build", or "is CI green yet".
argument-hint: [PR number or branch name]
---

# Babysit CI

Monitor GitHub Actions CI, distinguish flaky failures from real ones, and auto-retry when appropriate.

## Usage

```
/phx:babysit-ci 42           # Monitor PR #42
/phx:babysit-ci main         # Monitor latest run on main
/phx:babysit-ci              # Monitor current branch
```

## Arguments

`$ARGUMENTS` = PR number or branch name (optional, defaults to current branch)

## Iron Laws

1. **Never auto-merge** — Only monitor and report. Human decides when to merge
2. **Distinguish flaky from real** — Flaky: same test passes on retry. Real: consistent failure across retries
3. **Max 2 retries** — Don't waste CI minutes. After 2 retries, report as real failure
4. **Report with context** — Include failing test name, error message, and whether it's a known flaky test

## Workflow

### Step 1: Identify Target

```bash
# Get current branch if no argument
BRANCH=$(git branch --show-current)

# If PR number given
gh pr view $PR_NUMBER --json headRefName,statusCheckRollup

# If branch name given
gh run list --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion
```

### Step 2: Monitor Loop

Poll CI status every 60 seconds:

```bash
# Get run status
gh run view $RUN_ID --json status,conclusion,jobs

# Get job details on failure
gh run view $RUN_ID --json jobs --jq '.jobs[] | select(.conclusion == "failure")'
```

Report status changes:

- "CI started — monitoring..."
- "CI step X passed (Y remaining)"
- "CI failed on step X — analyzing..."

### Step 3: Analyze Failure

On failure, determine if flaky or real:

```bash
# Get failed test output
gh run view $RUN_ID --log-failed

# Check if this test has failed before (known flaky)
gh api repos/{owner}/{repo}/actions/runs \
  --jq '[.workflow_runs[] | select(.conclusion == "failure")] | length'
```

**Flaky indicators:**

- Timeout errors (`** (EXIT) time out`)
- Database connection errors (`Postgrex.Error connection refused`)
- Port/socket errors in CI environment
- Test passed on previous run of same commit

**Real failure indicators:**

- Compilation error
- Assertion failure with clear mismatch
- Pattern match error
- Same test fails consistently

### Step 4: Retry or Report

**If flaky** (attempt ≤ 2):

```bash
gh run rerun $RUN_ID --failed
```

Then return to Step 2 monitoring loop.

**If real failure or max retries reached:**

Report structured summary:

````markdown
## CI Failure Report

**Branch**: feature/my-change
**Run**: #1234 (attempt 2/2)
**Duration**: 4m 32s

### Failed Jobs
- `test` — 1 failure

### Failed Tests
- `test/my_app/accounts_test.exs:42` — "create_user/1 with duplicate email"
  Error: `Assertion failed: expected {:error, changeset} got {:ok, user}`

### Assessment
Real failure — assertion mismatch in accounts test. The uniqueness
constraint on email is not being enforced in the changeset.
````

## Gotchas

- **GitHub API rate limits** — `gh` CLI respects rate limits but polling every 60s can hit them on busy repos. Use `--cache 30s` for repeated calls
- **CI matrix builds** — A run may have multiple jobs (Elixir versions, databases). Parse all jobs, not just the first
- **Cancelled runs** — If someone pushes a new commit, the old run may be cancelled. Detect this and switch to monitoring the new run
- **Private repos** — `gh` must be authenticated. Check with `gh auth status` first
- **Concurrent runs** — Multiple CI runs for same branch can exist. Always use the latest run ID
