#!/usr/bin/env bash
# SessionStart hook: Check if QMD MCP server is available for semantic search
# QMD provides hybrid search (BM25 + vectors + reranking) over markdown files.
# When available, agents use mcp__qmd__query instead of grep for .claude/solutions/

if command -v qmd &>/dev/null; then
  # QMD is installed — check if it has indexed collections
  if qmd status 2>/dev/null | grep -q "solutions"; then
    echo "✓ QMD MCP available — prefer mcp__qmd__query over grep for .claude/solutions/ and .claude/plans/ search"
  else
    echo "○ QMD installed but no 'solutions' collection indexed — run: qmd collection add .claude/solutions --name solutions && qmd embed"
  fi
else
  # Silent — don't nag about optional tooling
  :
fi
