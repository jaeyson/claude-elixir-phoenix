# QMD Setup Guide

## Overview

[QMD](https://github.com/tobi/qmd) is a local search engine for markdown
files by Tobi Lutke. It combines BM25, vector embeddings, and LLM
reranking for hybrid search — all running locally with no cloud dependency.

When configured as an MCP server, Claude can semantically search your
compound knowledge base instead of relying on filename-based grep.

## Prerequisites

- Node.js 22.0.0+
- Ollama (recommended for local embeddings/reranking)

## Installation

```bash
# Install QMD globally
npm install -g @tobilu/qmd

# Start Ollama (if not running)
ollama serve
```

## Index Your Solutions

```bash
# Add compound knowledge as a collection
qmd collection add .claude/solutions --name solutions --pattern "**/*.md"

# Add plans (optional — for searching past plans/research)
qmd collection add .claude/plans --name plans --pattern "**/*.md"

# Add context descriptions for better search quality
qmd context add qmd://solutions "Solved Elixir/Phoenix problems with YAML frontmatter: module, problem_type, component, symptoms, root_cause, severity, tags. Categories: ecto-issues, liveview-issues, oban-issues, otp-issues, security-issues, testing-issues, phoenix-issues, deployment-issues, performance-issues, build-issues"
qmd context add qmd://plans "Development plans with checkboxes, research notes, scratchpads, and progress logs for Elixir/Phoenix features"

# Generate vector embeddings (takes a moment)
qmd embed
```

## Connect to Claude Code

### Option A: Stdio (simplest)

```bash
claude mcp add qmd -- qmd mcp
```

### Option B: HTTP daemon (persistent — avoids model reload)

```bash
# Start QMD HTTP server (keeps models in VRAM)
qmd mcp --http --daemon

# Add to Claude Code
claude mcp add --transport http qmd http://localhost:8181
```

### Option C: Project-scoped `.mcp.json`

Create `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "qmd": {
      "type": "stdio",
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

For HTTP transport:

```json
{
  "mcpServers": {
    "qmd": {
      "type": "http",
      "url": "http://localhost:8181"
    }
  }
}
```

## Re-indexing After New Solutions

After `/phx:compound` creates new solution files, re-index:

```bash
qmd update && qmd embed
```

The plugin will remind you to re-index when new solutions are created.

## QMD Configuration File

For advanced setups, create `~/.config/qmd/config.yaml`:

```yaml
global_context: >-
  These are Elixir/Phoenix development solutions and plans.
  Solutions have YAML frontmatter with: module, problem_type,
  component, symptoms, root_cause, severity, tags.
  When you see a relevant tag or module, search for it.

collections:
  solutions:
    path: /path/to/project/.claude/solutions
    pattern: "**/*.md"
    context:
      "/ecto-issues": "Database and Ecto ORM issues"
      "/liveview-issues": "Phoenix LiveView rendering and state issues"
      "/oban-issues": "Background job processing issues"
      "/security-issues": "Authentication, authorization, XSS, injection"
      "/testing-issues": "ExUnit, Mox, factory patterns"
      "/phoenix-issues": "Controllers, contexts, routing"
      "/performance-issues": "N+1 queries, memory, latency"
      "/": "All solved Elixir/Phoenix problems"

  plans:
    path: /path/to/project/.claude/plans
    pattern: "**/*.md"
    context:
      "/": "Development plans, research, and progress logs"
```

## Verification

```bash
# Check QMD status
qmd status

# Test a search
qmd query "preload association" -c solutions

# Verify MCP connection in Claude Code
# Type /mcp in Claude Code to see connected servers
```

## Multi-Project Setup

If you work on multiple Elixir projects, add each project's
solutions as a separate collection:

```bash
qmd collection add ~/project-a/.claude/solutions --name project-a
qmd collection add ~/project-b/.claude/solutions --name project-b
```

Use collection scoping in queries:

```
mcp__qmd__query({ query: "auth timeout", collection: "project-a" })
```
