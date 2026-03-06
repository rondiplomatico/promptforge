# Analyze Corrections and Friction

Scan PromptForge interaction logs for corrections, negations, contradictions, and repeated friction.

## How to run

Pre-filter logs with the helper script, then analyze the output:

```bash
SCRIPT="$(dirname "$(readlink -f ~/.claude/promptforge/hooks/log-prompt.sh)")/../skills/analyze-corrections/extract_friction.py"
python3 "$SCRIPT" --output /tmp/promptforge-friction-data.json
```

Read the resulting JSON and analyze:
- **Tool denials**: frequency by tool, `is_interrupt` vs explicit, repeated patterns
- **Negation language**: "no", "not that", "stop", "undo", "wrong", "instead", "actually" — weight by position (start = stronger)
- **Sequential contradictions**: prompt N negates prompt N-1 in same session
- **Repeated clarifications**: same `ask_response` question across sessions = unclear instructions
- **Correction chains**: tool_denial → follow-up prompt patterns, grouped by denied tool

## Output

Write a **Friction Report** to `.claude/promptforge/friction-report.md`:

1. **Top 10 Friction Patterns** ranked by frequency, each with: category, frequency, 2-3 examples, root cause hypothesis, suggested fix area (`CLAUDE.md` / `BMAD agent` / `BMAD task` / `permissions` / `workflow`)
2. **Summary Statistics**: total friction events, friction rate, trend over time

Also display the summary in the conversation.
