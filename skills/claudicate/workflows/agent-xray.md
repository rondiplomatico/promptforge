# Agent X-Ray — Agent Session Analysis

Analyze Claude Code agent session patterns from Claudicate interaction logs.

## Prerequisites

None.

## Steps

### 1. Run the analysis script

```bash
python3 <skill_dir>/scripts/analyze_agents.py --format markdown $SCOPE_PROJECT_FILTER
```

Options: `--logs-dir DIR` (repeatable), `--since YYYY-MM-DD`, `--project-filter DIR`, `--format text|markdown`, `--output FILE`.

Where `$SCOPE_PROJECT_FILTER` is `--project-filter <project_dir>` for project scope or omitted for global scope.

### 2. Present and interpret results

Present the output as a well-formatted report. Highlight:
- Agent-to-user session ratio and whether it's growing
- Warmup noise volume
- Which user prompts spawn the most agents
- Agent sessions with friction (denials, corrections) and what parent prompt triggered them
- Suggestions for reducing agent friction (e.g., better CLAUDE.md instructions, skill improvements)
