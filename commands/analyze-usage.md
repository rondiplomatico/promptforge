# Analyze Usage Behavior

Analyze my Claude Code usage patterns from PromptForge interaction logs.

## How to run

Locate `analyze-usage.py` by following the hook symlink back to the repo:

```bash
SCRIPT="$(dirname "$(readlink -f ~/.claude/promptforge/hooks/log-prompt.sh)")/../scripts/analyze-usage.py"
python3 "$SCRIPT" --format markdown
```

Options: `--logs-dir DIR` (repeatable), `--since YYYY-MM-DD`, `--format text|markdown`, `--output FILE`.

## After the script runs

Present the output as a well-formatted report. Add interpretation and insights:
- Highlight notable patterns (e.g., high denial rates, time concentration)
- Flag potential improvement areas
- Compare BMAD vs non-BMAD session characteristics if both are present
