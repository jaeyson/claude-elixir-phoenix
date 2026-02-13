#!/usr/bin/env bash
# Stop hook: Warn about plans with uncompleted tasks
PENDING=$(grep -rl '\[ \]' .claude/plans/*/plan.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$PENDING" -gt 0 ]]; then
  echo "⚠ $PENDING plan(s) have uncompleted tasks"
fi
