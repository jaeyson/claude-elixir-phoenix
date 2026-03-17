#!/usr/bin/env bash
# Full Elixir/Phoenix verification loop.
# Runs: compile → format → credo → test (→ dialyzer if --dialyzer).
# Exits on first failure with the failing step name.
#
# Usage:
#   ./full-check.sh                # Standard check (no dialyzer)
#   ./full-check.sh --dialyzer     # Include dialyzer (pre-PR)
#   ./full-check.sh --files "lib/my_app/accounts.ex lib/my_app/users.ex"
#                                  # Scope format check to specific files

set -euo pipefail

DIALYZER=false
FILES=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dialyzer) DIALYZER=true; shift ;;
    --files) FILES="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

step() {
  local name="$1"; shift
  echo "▸ $name"
  if ! "$@"; then
    echo "✗ FAILED: $name" >&2
    exit 1
  fi
  echo "✓ $name"
}

step "Compile" mix compile --warnings-as-errors

if [ -n "$FILES" ]; then
  step "Format (scoped)" mix format --check-formatted $FILES
else
  step "Format" mix format --check-formatted
fi

if mix help credo >/dev/null 2>&1; then
  step "Credo" mix credo --strict
else
  echo "⊘ Credo not installed, skipping"
fi

step "Test" mix test

if [ "$DIALYZER" = true ]; then
  if mix help dialyzer >/dev/null 2>&1; then
    step "Dialyzer" mix dialyzer
  else
    echo "⊘ Dialyzer not installed, skipping"
  fi
fi

echo ""
echo "All checks passed ✓"
