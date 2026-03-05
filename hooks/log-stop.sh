#!/bin/bash
# claudeloop hook: Stop → JSONL
# Captures turn-end metadata including model and best-effort token usage
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

# --- Token usage extraction (best-effort) ---
extract_token_usage() {
  local transcript_path="$1"
  if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
    echo "null"
    return
  fi
  # Find last assistant message with usage data
  local usage
  usage=$(tac "$transcript_path" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | jq -e 'select(.type == "assistant") | .message.usage' 2>/dev/null; then
      break
    fi
  done)
  if [ -n "$usage" ]; then
    echo "$usage" | jq -c '{
      input_tokens: .input_tokens,
      output_tokens: .output_tokens,
      cache_read_input_tokens: .cache_read_input_tokens,
      cache_creation_input_tokens: .cache_creation_input_tokens
    }' 2>/dev/null || echo "null"
  else
    echo "null"
  fi
}

# --- Main ---
INPUT=$(cat)

# Debug dump on first run
DEBUG_FILE="/tmp/claudeloop-stop-debug.json"
if [ ! -f "$DEBUG_FILE" ]; then
  echo "$INPUT" > "$DEBUG_FILE"
fi

LOG_DIR=$(resolve_log_dir)
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.workspace.project_dir // empty')
MODEL=$(echo "$INPUT" | jq -r '.model.id // .model // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

TOKEN_USAGE=$(extract_token_usage "$TRANSCRIPT_PATH")

# Build the JSON entry, conditionally including token_usage
if [ "$TOKEN_USAGE" = "null" ]; then
  jq -n -c \
    --arg ts "$TIMESTAMP" \
    --arg et "turn_end" \
    --arg sid "$SESSION_ID" \
    --arg pd "$PROJECT_DIR" \
    --arg cwd "$CWD" \
    --arg model "$MODEL" \
    --argjson tags '[]' \
    '{timestamp: $ts, event_type: $et, session_id: $sid, project_dir: $pd, cwd: $cwd, model: $model, tags: $tags}' \
    >> "$LOG_FILE"
else
  jq -n -c \
    --arg ts "$TIMESTAMP" \
    --arg et "turn_end" \
    --arg sid "$SESSION_ID" \
    --arg pd "$PROJECT_DIR" \
    --arg cwd "$CWD" \
    --arg model "$MODEL" \
    --argjson usage "$TOKEN_USAGE" \
    --argjson tags '[]' \
    '{timestamp: $ts, event_type: $et, session_id: $sid, project_dir: $pd, cwd: $cwd, model: $model, token_usage: $usage, tags: $tags}' \
    >> "$LOG_FILE"
fi

exit 0
