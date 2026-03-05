#!/bin/bash
# claudeloop hook: PostToolUse[AskUserQuestion] → JSONL
# Captures questions Claude asked and user's answers
set -e

# --- Shared log directory resolution ---
resolve_log_dir() {
  local project_dir
  project_dir=$(echo "$INPUT" | jq -r '.workspace.project_dir // empty')
  if [ -n "$project_dir" ] && [ -d "$project_dir/.claude/claudeloop/logs" ]; then
    echo "$project_dir/.claude/claudeloop/logs"
  elif [ -d "$HOME/.claude/claudeloop/logs" ]; then
    echo "$HOME/.claude/claudeloop/logs"
  else
    mkdir -p "$HOME/.claude/claudeloop/logs"
    echo "$HOME/.claude/claudeloop/logs"
  fi
}

# --- Main ---
INPUT=$(cat)

LOG_DIR=$(resolve_log_dir)
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.workspace.project_dir // empty')
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Extract question(s) from inputs - handle both single and multiple questions
QUESTION=$(echo "$INPUT" | jq -r '
  if .inputs.questions then
    [.inputs.questions[].question] | join("\n")
  elif .inputs.question then
    .inputs.question
  else
    "unknown"
  end
')

# Extract user's answer from response
ANSWER=$(echo "$INPUT" | jq -r '.response // empty')

TAGS='["clarification"]'

jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg et "ask_response" \
  --arg sid "$SESSION_ID" \
  --arg pd "$PROJECT_DIR" \
  --arg cwd "$CWD" \
  --arg question "$QUESTION" \
  --arg answer "$ANSWER" \
  --argjson tags "$TAGS" \
  '{timestamp: $ts, event_type: $et, session_id: $sid, project_dir: $pd, cwd: $cwd, question: $question, answer: $answer, tags: $tags}' \
  >> "$LOG_FILE"

exit 0
