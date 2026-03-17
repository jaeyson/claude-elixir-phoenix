# Skills Guide — Lessons from Anthropic Applied to This Plugin

Contributor reference based on ["Skills: Lessons from Hundreds in Production at Anthropic"](https://www.anthropic.com) (Thariq, March 2026).

## Category Mapping

How the article's 9 skill categories map to our 38 skills:

| Article Category | Our Skills | Coverage |
|-----------------|------------|----------|
| Library & API Reference | ecto-patterns, liveview-patterns, oban, phoenix-contexts, security, elixir-idioms, deploy | **Strong** |
| Product Verification | verify (compile/test only) | **Weak** — no E2E/Wallaby |
| Data Fetching & Analysis | psql-query (contributor-only) | **Weak** — nothing user-facing |
| Business Process & Automation | pr-review, compound | Moderate |
| Code Scaffolding & Templates | quick, init | **Weak** — no dedicated scaffolds |
| Code Quality & Review | review, challenge, techdebt | **Strong** |
| CI/CD & Deployment | deploy | Moderate — no babysit-pr equivalent |
| Runbooks | investigate, call-tracing, ecto-constraint-debug | Moderate |
| Infrastructure Operations | (none) | N/A for framework plugin |

## Actionable Gaps

### 1. Skills are pure markdown — no scripts or assets

All 38 skills are `.md` only. The article emphasizes that the most interesting
skills use folders creatively with scripts, templates, and data files.

**Quick wins:**

- Add template files to scaffolding skills (EEx templates for new LiveViews, contexts)
- Add shell scripts to verification skills (e.g., `verify/scripts/full-check.sh`)
- Add JSON schemas to compound-docs for solution validation

### 2. No dedicated scaffolding skills

Missing: `new-live-view`, `new-context`, `new-migration`, `new-worker` generators
that go beyond what `mix phx.gen.*` provides (adding our Iron Laws, patterns,
and project conventions automatically).

**Value:** High for new Phoenix developers. Reduces boilerplate errors and
enforces patterns from day one.

### 3. Product verification is shallow

`verify` runs `mix compile`, `mix format`, `mix credo`, `mix test`, `mix dialyzer`.
No LiveView flow testing, no Wallaby/browser-based verification.

**Opportunity:** A `wallaby-flow` or `e2e-verify` skill that generates Wallaby
test scripts for common flows (auth, CRUD, forms). The article calls product
verification skills "extremely useful for correctness — worth investing
engineering time."

### 4. Missing gotchas sections in some skills

The article calls gotchas the "highest-signal part" of any skill. Update them
from real failure modes observed in sessions.

**Skills missing explicit Gotchas/Iron Laws:**

- `techdebt` — no gotchas section
- `examples` — no gotchas section
- `hexdocs-fetcher` — no gotchas section
- `intent-detection` — no gotchas section
- `assigns-audit` — has checks but no explicit gotchas
- `tidewave-integration` — no gotchas section

**Action:** Audit each skill for a gotchas section. Mine session data
(`/session-scan`, `/session-deep-dive`) for real failure patterns to populate them.

### 5. No "babysit" CI/CD skills

The article's `babysit-pr` pattern (monitor CI → retry flaky tests → resolve
conflicts → auto-merge) is high-value and missing from our plugin.

**Opportunity:** A `babysit-ci` skill using `gh` CLI to monitor GitHub Actions,
retry on flaky failures, and notify on real breakage.

## What We Already Do Well

The article validates several of our existing patterns:

| Article Recommendation | Our Implementation |
|----------------------|-------------------|
| "Build a Gotchas Section" | Iron Laws — our strongest differentiator |
| "Use the File System & Progressive Disclosure" | `references/` folders in 33 of 38 skills |
| "Don't State the Obvious" | Skills focus on Elixir-specific knowledge, not generic coding |
| "Avoid Railroading Claude" | Intent-detection suggests but doesn't force workflows |
| "Save previous results in logs" | Compound knowledge system (`solutions/`) |
| "Folders = context engineering" | Plan namespaces, review tracks, research output |

## Key Quotes to Remember

- "The most interesting part is they're **folders** that can include scripts, assets, data, etc. that the agent can discover, explore and manipulate."
- "Build a Gotchas Section — Highest-signal part. Update from real failure modes."
- "[Product Verification skills are] extremely useful for correctness. Worth investing engineering time."
- "Don't State the Obvious — Focus on org-specific knowledge that pushes Claude out of default behavior."
