#!/usr/bin/env bash
# SessionStart hook: Detect plans with remaining tasks
FOUND_PLAN=false
for dir in .claude/plans/*/; do
  [ -f "${dir}plan.md" ] || continue
  UNCHECKED=$(grep -c '^\- \[ \]' "${dir}plan.md" 2>/dev/null || echo 0)
  CHECKED=$(grep -c '^\- \[x\]' "${dir}plan.md" 2>/dev/null || echo 0)
  if [ "$UNCHECKED" -gt 0 ]; then
    SLUG="$(basename "$dir")"
    echo "↻ Plan '${SLUG}' has ${UNCHECKED} remaining tasks (${CHECKED} done). Resume with: /phx:work .claude/plans/${SLUG}/plan.md"
    FOUND_PLAN=true
  fi
done
# Detect active autoresearch sessions
for dir in .claude/autoresearch/*/; do
  [ -f "${dir}config.json" ] || continue
  if [ -f "${dir}results.jsonl" ]; then
    DONE=$(wc -l < "${dir}results.jsonl" 2>/dev/null | tr -d ' ')
    MAX=$(python3 -c "import json; print(json.load(open('${dir}config.json')).get('max_iterations', 15))" 2>/dev/null || echo 15)
    if [ "$DONE" -lt "$MAX" ]; then
      SLUG="$(basename "$dir")"
      echo "↻ Active autoresearch '${SLUG}' (${DONE}/${MAX} iterations). Resume with: /phx:autoresearch --resume ${SLUG}"
      FOUND_PLAN=true
    fi
  fi
done
if [ "$FOUND_PLAN" = false ]; then
  echo "Elixir/Phoenix plugin loaded — describe your task and I'll suggest the right workflow"
fi
