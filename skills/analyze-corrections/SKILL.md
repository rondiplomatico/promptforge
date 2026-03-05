# Skill: Analyze Corrections and Friction

## Description
Analyzes promptforge interaction logs to detect patterns of corrections, negations, tool denials, and repeated friction points. Produces a structured Friction Report.

## Trigger
When user runs `/promptforge:analyze-corrections` or asks to analyze friction/corrections in their Claude Code usage.

## Steps

1. **Pre-filter logs** (optional optimization):
   Run `extract_friction.py` to pre-filter and aggregate friction signals from logs:
   ```bash
   python3 <skill_dir>/extract_friction.py --logs-dir ~/.claude/promptforge/logs/ --output /tmp/promptforge-friction-data.json
   ```
   If the script is unavailable or fails, fall back to reading logs directly with jq.

2. **Analyze friction patterns**:
   Read the pre-filtered data (or raw logs) and identify:
   - Tool denial frequency by tool name
   - Negation/correction language in prompts
   - Sequential contradictions within sessions
   - Repeated clarification questions across sessions
   - Correction chains (denial → follow-up prompt)

3. **Write Friction Report**:
   Write the report to `.claude/promptforge/friction-report.md` with:
   - Top 10 friction patterns ranked by frequency
   - Examples, root cause hypotheses, and suggested fix areas
   - Summary statistics and trend analysis

4. **Display summary** in conversation.

## Input
No explicit input required. Reads from promptforge log directories.

## Output
- File: `.claude/promptforge/friction-report.md`
- Conversation: Summary of top friction patterns
