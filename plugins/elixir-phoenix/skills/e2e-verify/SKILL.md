---
name: phx:e2e
description: Generate and run end-to-end product verification tests for Phoenix LiveView flows using Wallaby or LiveViewTest. Use when the user wants to verify a complete user flow works (auth, forms, CRUD, multi-step wizards), after implementing a feature that spans multiple pages, or when standard mix test isn't enough to confirm behavior. Goes beyond unit tests to verify real user journeys.
argument-hint: [flow description]
---

# E2E Product Verification

Generate end-to-end tests that verify complete user flows, not just individual functions.

## Usage

```
/phx:e2e Login → create post → verify post appears in feed
/phx:e2e Password reset flow
/phx:e2e Admin creates user, user logs in, updates profile
```

## Arguments

`$ARGUMENTS` = Description of the user flow to verify

## Iron Laws

1. **Test real user paths** — Click buttons, fill forms, navigate pages. Don't call context functions directly
2. **Assert intermediate states** — Verify each step succeeded before proceeding to next
3. **Clean up test state** — Use Ecto sandbox or explicit cleanup. Never leave test data
4. **Prefer LiveViewTest over Wallaby** — Use LiveViewTest when flow is within LiveView. Only reach for Wallaby when JavaScript interaction is required

## Workflow

### Step 1: Analyze Flow

1. Parse `$ARGUMENTS` into ordered steps
2. Identify which routes/LiveViews are involved
3. Check if flow requires JavaScript (→ Wallaby) or is pure LiveView (→ LiveViewTest)
4. Identify required test setup (users, data, auth state)

### Step 2: Check Project Setup

```bash
# Check for Wallaby
grep -r "wallaby" mix.exs mix.lock 2>/dev/null

# Check for existing E2E patterns
find test/ -name "*e2e*" -o -name "*integration*" -o -name "*feature*" 2>/dev/null

# Check test helpers
ls test/support/
```

### Step 3: Generate Test

Generate using the appropriate driver:

#### LiveViewTest (preferred)

```elixir
defmodule MyAppWeb.{Flow}E2ETest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "{flow description}" do
    setup do
      # Create required test data
      user = insert(:user)  # or manual setup
      %{user: user}
    end

    test "complete flow", %{conn: conn, user: user} do
      # Step 1: Navigate to start
      {:ok, view, _html} = live(conn, ~p"/start")

      # Step 2: Interact
      view
      |> form("#my-form", %{field: "value"})
      |> render_submit()

      # Step 3: Assert result
      assert render(view) =~ "Success"

      # Step 4: Verify side effects
      assert Repo.get_by(Resource, field: "value")
    end
  end
end
```

#### Wallaby (when JavaScript required)

```elixir
defmodule MyAppWeb.{Flow}FeatureTest do
  use MyAppWeb.FeatureCase  # Wallaby case
  use Wallaby.Feature

  import Wallaby.Query

  feature "{flow description}", %{session: session} do
    session
    |> visit("/start")
    |> fill_in(text_field("Email"), with: "test@example.com")
    |> click(button("Submit"))
    |> assert_has(css(".success-message"))
  end
end
```

### Step 4: Run and Verify

```bash
# Run the generated test
mix test test/my_app_web/e2e/{flow}_e2e_test.exs --trace

# If Wallaby
mix test test/my_app_web/features/{flow}_feature_test.exs --trace
```

## Gotchas

- **Async assigns**: If the flow uses `assign_async`, the test must wait for async completion. Use `assert_async` or `render_async` helpers
- **PubSub in tests**: If flow involves PubSub, ensure the test process subscribes before triggering the event
- **File uploads**: LiveView upload tests need `file_input/4` + `render_upload/3`, not direct form submission
- **Auth flows**: Use `log_in_user/2` from `ConnCase` helpers, don't test login itself unless that's the flow
- **Flash messages**: Flash may render on redirect — follow the redirect and then assert

## When to Use This vs /phx:verify

| Scenario | Use |
|----------|-----|
| "Do my tests pass?" | `/phx:verify` |
| "Does the login flow work end-to-end?" | `/phx:e2e` |
| "Verify compile + format + credo" | `/phx:verify` |
| "User creates account, gets email, clicks link" | `/phx:e2e` |
