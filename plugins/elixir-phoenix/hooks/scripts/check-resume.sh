#!/usr/bin/env bash
# SessionStart hook: Detect if resuming an existing session
if find .claude/plans/*/progress.md -mtime 0 2>/dev/null | grep -q .; then
  echo "↻ Resuming session - progress file exists"
else
  echo "Elixir/Phoenix plugin loaded"
fi
