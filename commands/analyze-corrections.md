# Analyze Corrections and Friction

Scan claudeloop interaction logs for patterns of corrections, negations, contradictions, and repeated friction points.

## Data Source

Read all JSONL files from:
1. `~/.claude/claudeloop/logs/*.jsonl` (global logs)
2. If inside a project: `$CLAUDE_PROJECT_DIR/.claude/claudeloop/logs/*.jsonl` (project logs)

## Analysis

### Tool Denials
- Count denials by `denied_tool` — which tools get denied most?
- Analyze `denial_reason` patterns
- Identify `is_interrupt: true` vs explicit denials
- Look for repeated denial → same tool patterns within sessions

### Negation Language in Prompts
Scan prompts for negation/correction signals:
- "no", "not that", "stop", "undo", "wrong", "instead", "actually", "rather", "don't", "should not", "revert"
- Weight these by position (start of prompt = stronger signal)

### Sequential Contradictions
Within each session (group by session_id, order by timestamp):
- Find prompt N that negates/refines prompt N-1
- Examples: "actually do X instead", "no, I meant Y", "forget that, do Z"

### Repeated Clarifications
- Find `ask_response` events with similar questions across different sessions
- Same question asked repeatedly = unclear instructions somewhere

### Correction Chains
- Pattern: tool_denial → next prompt in same session
- What does the user say right after denying a tool?
- Group by denied tool to find systematic misunderstandings

## Output

Write a **Friction Report** to `.claude/claudeloop/friction-report.md` containing:

1. **Top 10 Friction Patterns** ranked by frequency
2. For each pattern:
   - Category (tool_denial / negation / contradiction / repeated_clarification)
   - Frequency count and date range
   - 2-3 example interactions (timestamp, prompt/denial text)
   - Root cause hypothesis
   - Suggested fix area: `CLAUDE.md` / `BMAD agent:<name>` / `BMAD task:<name>` / `permissions` / `workflow`

3. **Summary Statistics**
   - Total friction events
   - Friction rate (friction events / total interactions)
   - Trend over time (improving or worsening?)

Also display the report summary in the conversation.
