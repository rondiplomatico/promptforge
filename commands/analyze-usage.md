# Analyze Usage Behavior

Analyze my Claude Code usage patterns from PromptForge interaction logs.

**Before running this command**, read and follow the scope selection procedure in the `_scope-preamble.md` file located alongside this command file.

## How to run

Locate `analyze-usage.py` by following the hook symlink back to the repo:

```bash
SCRIPT="$(dirname "$(readlink -f ~/.claude/promptforge/hooks/log-prompt.sh)")/../scripts/analyze-usage.py"
python3 "$SCRIPT" --format markdown $SCOPE_PROJECT_FILTER
```

Where `$SCOPE_PROJECT_FILTER` is either `--project-filter <project_dir>` (project scope) or omitted (global scope), as determined by the scope preamble.

Options: `--logs-dir DIR` (repeatable), `--since YYYY-MM-DD`, `--project-filter DIR`, `--format text|markdown`, `--output FILE`.

## After the script runs

Present the output as a well-formatted report. Add interpretation and insights:
- Highlight notable patterns (e.g., high denial rates, time concentration)
- Flag potential improvement areas
- Compare BMAD vs non-BMAD session characteristics if both are present
