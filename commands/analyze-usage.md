# Analyze Usage Behavior

Analyze my Claude Code usage patterns from claudeloop interaction logs.

## Data Source

Read all JSONL files from:
1. `~/.claude/claudeloop/logs/*.jsonl` (global logs)
2. If inside a project: `$CLAUDE_PROJECT_DIR/.claude/claudeloop/logs/*.jsonl` (project logs)

Each line is a JSON object with fields: `timestamp`, `event_type` (prompt|ask_response|tool_denial|turn_end), `session_id`, `project_dir`, `cwd`, `prompt`, `question`, `answer`, `denied_tool`, `tags`, `model`, `token_usage`.

## Analysis

Use Bash with `jq` and `python3` (if available) to process the logs. Produce a report covering:

### Volume
- Total interactions, date range covered
- Sessions per day (group by session_id per date)
- Prompts per session (average, min, max)

### Activity Distribution
- Count entries by tag: `planning`, `testing`, `git_ops`, `bmad`, `slash_command`, `clarification`, `correction`
- Show as percentage of total prompts

### BMAD Agent Usage
- Frequency of each `bmad:<agent>` and `bmad_task:<task>` tag
- Average session length when using BMAD agents

### Interaction Patterns
- `ask_response` rate (% of turns with a clarification)
- `tool_denial` rate (% of turns with a denial)
- Average prompts between denials
- Most frequently denied tools

### Time Patterns
- Active hours (UTC) distribution
- Day-of-week distribution

### Token Usage (if available)
- Average input/output tokens per turn
- Cache hit rate (cache_read / total input)
- Total estimated token spend

### Prompt Characteristics
- Average prompt length (chars)
- Slash command vs free-text ratio
- Top 10 most common prompt prefixes (first 30 chars)

## Output

Present as a well-formatted markdown report. Include actual numbers, not just categories. Use tables where appropriate.

If no log data is found, explain where logs should be and how to generate them (run the installer or use extract-sessions.py for backfill).
