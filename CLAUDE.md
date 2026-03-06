# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is promptforge?

A self-improvement toolkit for Claude Code. Four bash hooks capture user interactions (prompts, clarification answers, tool denials, turn ends) as structured JSONL logs. Python scripts and Claude-driven skills then analyze these logs to detect friction patterns and suggest improvements to project configuration (CLAUDE.md, permissions, memory) and BMAD setup.

## Data Flow

```
Claude Code events → 4 hook scripts → JSONL daily logs → Python analysis / Skills → Recommendations
```

## Architecture

### Hooks (`hooks/`)
Bash scripts triggered by Claude Code events. All share a common pattern:
- Read JSON from stdin (`INPUT=$(cat)`)
- Extract fields with `jq -r`
- Resolve log directory (project-local `.claude/promptforge/logs/` first, global `~/.claude/promptforge/logs/` fallback)
- Append one JSON line to `YYYY-MM-DD.jsonl`
- Use `set -e` and exit 0

| Hook | Event | event_type |
|------|-------|------------|
| `log-prompt.sh` | `UserPromptSubmit` | `prompt` |
| `log-ask-response.sh` | `PostToolUse[AskUserQuestion]` | `ask_response` |
| `log-tool-denial.sh` | `PostToolUseFailure` | `tool_denial` |
| `log-stop.sh` | `Stop` | `turn_end` |

PostToolUse hooks receive data in `tool_input` / `tool_response` fields (not `inputs` / `response`).

`log-prompt.sh` applies auto-tags via regex (bmad, slash_command, planning, testing, git_ops, etc.). `log-tool-denial.sh` filters to only user interrupts and explicit denials.

### Log Format (`schema.json`)
JSONL with required fields: `timestamp` (ISO 8601 UTC), `event_type`, `session_id`. Event-specific required fields: `prompt` (prompt), `question`+`answer` (ask_response), `denied_tool` (tool_denial). All events have optional `tags` array.

### Python Scripts (`scripts/`)
- `analyze-usage.py` — generates usage report (volume, time patterns, token usage, tags)
- `extract-sessions.py` — backfills logs from Claude Code session transcripts
- `validate-logs.py` — validates JSONL against schema

All support `--logs-dir` (repeatable), `--since`, auto-discover log directories.

### Skills & Commands
Commands (`commands/*.md`) are user-facing slash command docs. Skills (`skills/*/SKILL.md`) define the multi-step process Claude follows. The workflow chain is: `analyze-corrections` (generates friction report) → `improve-project` or `improve-bmad` (consumes friction report, cross-references with current config, suggests changes).

`skills/analyze-corrections/extract_friction.py` pre-aggregates friction signals (denials, negations, contradictions, repeated clarifications) into JSON to reduce context load.

### Installation (`install.sh`, `uninstall.sh`)
Interactive scripts (no CLI args). Install supports link (symlink) or copy mode to global/project/.claude/ directories. Writes `install.manifest` tracking all installed files. Updates `settings.json` with hook entries via jq. Uninstall reads manifest for clean removal.

Installed layout:
```
<target>/.claude/
  promptforge/hooks/     ← hook scripts
  promptforge/logs/      ← JSONL log files
  promptforge/schema.json
  promptforge/install.manifest
  commands/promptforge/  ← slash command .md files
  skills/promptforge-*/  ← skill directories
```

## Development Conventions

- Hook scripts duplicate `resolve_log_dir()` intentionally (isolation over DRY)
- Python scripts use only stdlib (no pip dependencies)
- jq is the only external dependency for hooks; python3 is optional (for analysis)
- Tags are the primary mechanism for filtering and categorization across the system
- Log files are append-only, daily-partitioned, never overwritten
