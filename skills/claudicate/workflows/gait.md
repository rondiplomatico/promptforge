# Gait — Usage Analysis

Analyze Claude Code usage patterns from Claudicate interaction logs.

## Prerequisites

None.

## Steps

### 1. Run the analysis script

```bash
python3 <skill_dir>/scripts/analyze_usage.py --format markdown $SCOPE_PROJECT_FILTER
```

Options: `--logs-dir DIR` (repeatable), `--since YYYY-MM-DD`, `--project-filter DIR`, `--format text|markdown`, `--output FILE`.

Where `$SCOPE_PROJECT_FILTER` is `--project-filter <project_dir>` for project scope or omitted for global scope.

### 2. Present and interpret results

Present the output as a well-formatted report. Add interpretation and insights:
- Highlight notable patterns (e.g., high denial rates, time concentration)
- Flag potential improvement areas
- Compare BMAD vs non-BMAD session characteristics if both are present
