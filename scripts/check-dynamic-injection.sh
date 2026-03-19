#!/usr/bin/env bash
# Blocks PRs that contain dynamic context injection (!`command`) syntax.
# This Claude Code feature executes arbitrary shell commands at skill load time.
# We don't use it and treat it as a security risk in plugin files.
#
# Docs: https://code.claude.com/docs/en/skills#inject-dynamic-context
# Pattern: !`some shell command` — runs command and injects stdout into context

set -euo pipefail

SCAN_DIRS="plugins/ .claude/ CLAUDE.md"

found=0

for target in $SCAN_DIRS; do
  if [ ! -e "$target" ]; then
    continue
  fi

  # Match !`...` dynamic context injection pattern.
  # Dangerous: !`command here` at line start, after whitespace, or after - / :
  # Safe (not matched): Elixir bangs like File.read!`, assert !`, verify_on_exit!`
  # We require !` to be preceded by whitespace, line start, or markdown list marker
  matches=$(grep -rn --include='*.md' --include='*.json' -P '(^|[\s\-:>])!\`[^`]+\`' "$target" 2>/dev/null || true)

  if [ -n "$matches" ]; then
    echo "BLOCKED: Dynamic context injection found:"
    echo "$matches"
    echo ""
    found=1
  fi
done

if [ "$found" -eq 1 ]; then
  echo "========================================="
  echo "ERROR: Dynamic context injection detected"
  echo "========================================="
  echo ""
  echo "The !\`command\` syntax executes shell commands and injects output"
  echo "into Claude's context. This is a security risk in plugin files."
  echo ""
  echo "If you need command output, use an agent with Bash tool access instead."
  exit 1
fi

echo "No dynamic context injection found."
