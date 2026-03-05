# claudeloop

A self-improvement toolset for Claude Code. Captures all user interactions (prompts, question answers, tool denials) in structured JSON, then analyzes them to improve your project configuration and BMAD setup.

## What it captures

| Hook Event | What's logged |
|---|---|
| `UserPromptSubmit` | Every typed prompt with auto-tags |
| `PostToolUse[AskUserQuestion]` | Questions Claude asked + your answers |
| `PostToolUseFailure` | Tool denials and user interrupts |
| `Stop` | Turn-end metadata, model, token usage |

Logs are written as JSONL to `.claude/claudeloop/logs/YYYY-MM-DD.jsonl`.

## Installation

### Prerequisites

- `jq` (required)
- `python3` (optional, for session import and validation)

### Install

```bash
cd /path/to/claudeloop   # wherever you checked out this repo
./install.sh
```

The interactive installer asks:
1. **Install target**: Global (`~/.claude/`), project path, or current directory
2. **Install mode**: Symlink (auto-updates on `git pull`) or copy (standalone)
3. **Import history**: Parse existing Claude Code sessions into claudeloop format

Run multiple times to install to different targets.

### What gets installed

```
<target>/.claude/
├── claudeloop/
│   ├── logs/              # JSONL output (written by hooks)
│   ├── hooks/             # Hook scripts (symlinked or copied)
│   └── schema.json        # Log format definition
├── commands/claudeloop/   # Slash commands
└── skills/                # Skill wrappers for analysis
```

## Usage

### Slash Commands

| Command | Purpose |
|---|---|
| `/claudeloop:analyze-usage` | Usage behavior report (volume, patterns, time) |
| `/claudeloop:analyze-corrections` | Friction detection → writes Friction Report |
| `/claudeloop:improve-project` | Suggests CLAUDE.md + permission + memory improvements |
| `/claudeloop:improve-bmad` | Suggests BMAD agent/task/checklist improvements |

### Recommended workflow

1. Use Claude Code normally for a while to accumulate logs
2. Run `/claudeloop:analyze-usage` to see your patterns
3. Run `/claudeloop:analyze-corrections` to generate a Friction Report
4. Run `/claudeloop:improve-project` and/or `/claudeloop:improve-bmad` to get actionable suggestions

### Backfill historical data

```bash
python3 scripts/extract-sessions.py --include-old-logs
python3 scripts/extract-sessions.py --since 2025-01-01 --project bordnetzgpt
```

### Validate logs

```bash
python3 scripts/validate-logs.py
python3 scripts/validate-logs.py ~/.claude/claudeloop/logs/
```

## Log Format

Each JSONL line contains:

```json
{
  "timestamp": "2026-03-05T09:35:24Z",
  "event_type": "prompt|ask_response|tool_denial|turn_end",
  "session_id": "uuid",
  "project_dir": "/path/to/project",
  "cwd": "/path/to/cwd",
  "prompt": "user text",
  "tags": ["bmad", "testing"]
}
```

See `schema.json` for the full schema definition.

## Auto-tags

| Pattern | Tags |
|---|---|
| `/BMad:agents:<name>` | `bmad`, `bmad:<name>` |
| `/BMad:tasks:<name>` | `bmad`, `bmad_task:<name>` |
| Starts with `/` | `slash_command` |
| Plan mode indicators | `planning` |
| Test/pytest/verify | `testing` |
| Commit/push/pr | `git_ops` |
| AskUserQuestion | `clarification` |
| Tool denial | `correction` |

## Log directory resolution

Hooks resolve the log directory at runtime:
1. If `$CLAUDE_PROJECT_DIR/.claude/claudeloop/logs/` exists → write there
2. Else → `~/.claude/claudeloop/logs/` (global fallback)

This means project-installed targets get project-local logs, everything else goes global.

## Updating

- **Symlink mode**: `cd /path/to/claudeloop && git pull` — all installations update automatically
- **Copy mode**: Re-run `./install.sh` to update

## Uninstalling

1. Remove hook entries from `.claude/settings.json` (entries containing "claudeloop")
2. Remove `.claude/claudeloop/`, `.claude/commands/claudeloop/`, `.claude/skills/claudeloop-*`
