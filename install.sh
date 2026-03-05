#!/bin/bash
# promptforge installer — interactive, no CLI arguments
# Installs hooks, commands, and skills to a target .claude/ directory
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== promptforge installer ==="
echo "Source: $REPO_DIR"
echo ""

# --- Prerequisites ---
echo -n "Checking prerequisites... "
if ! command -v jq >/dev/null 2>&1; then
  echo "FAILED"
  echo "Error: jq is required but not installed."
  echo "Install it with: sudo apt install jq  (or brew install jq)"
  exit 1
fi
echo "jq ✓"
echo ""

# --- [1] Install target ---
echo "[1] Install target"
echo "    (g) Global (~/.claude/)"
echo "    (p) Project — enter path"
echo "    (.) Current directory ($(pwd))"
printf "    > "
read -r TARGET_CHOICE

case "$TARGET_CHOICE" in
  g)
    TARGET_CLAUDE_DIR="$HOME/.claude"
    ;;
  p)
    printf "    Enter project path: "
    read -r PROJECT_PATH
    if [ ! -d "$PROJECT_PATH" ]; then
      echo "Error: Directory '$PROJECT_PATH' does not exist."
      exit 1
    fi
    TARGET_CLAUDE_DIR="$PROJECT_PATH/.claude"
    ;;
  .)
    TARGET_CLAUDE_DIR="$(pwd)/.claude"
    ;;
  *)
    echo "Error: Invalid choice '$TARGET_CHOICE'. Use g, p, or ."
    exit 1
    ;;
esac
echo ""

# --- [2] Install mode ---
echo "[2] Install mode"
echo "    (l) Link — symlink back to this repo (auto-updates on git pull)"
echo "    (c) Copy — standalone copy (requires manual re-install for updates)"
printf "    > "
read -r MODE_CHOICE

case "$MODE_CHOICE" in
  l) INSTALL_MODE="link" ;;
  c) INSTALL_MODE="copy" ;;
  *)
    echo "Error: Invalid choice '$MODE_CHOICE'. Use l or c."
    exit 1
    ;;
esac
echo ""

# --- Execute installation ---
echo "Installing to $TARGET_CLAUDE_DIR using ${INSTALL_MODE}s..."

# Helper: install a file (symlink or copy)
install_file() {
  local src="$1" dst="$2"
  if [ "$INSTALL_MODE" = "link" ]; then
    ln -sf "$src" "$dst"
    echo "  Linked   $dst → $src"
  else
    cp "$src" "$dst"
    echo "  Copied   $dst"
  fi
}

# Helper: install a directory (symlink or copy)
install_dir() {
  local src="$1" dst="$2"
  if [ "$INSTALL_MODE" = "link" ]; then
    ln -sfn "$src" "$dst"
    echo "  Linked   $dst → $src"
  else
    rm -rf "$dst"
    cp -r "$src" "$dst"
    echo "  Copied   $dst"
  fi
}

# Create directories
mkdir -p "$TARGET_CLAUDE_DIR/promptforge/logs"
echo "  Created  $TARGET_CLAUDE_DIR/promptforge/logs/"
mkdir -p "$TARGET_CLAUDE_DIR/promptforge/hooks"

# Install hook scripts
chmod +x "$REPO_DIR/hooks/"*.sh
for hook in "$REPO_DIR/hooks/"*.sh; do
  install_file "$hook" "$TARGET_CLAUDE_DIR/promptforge/hooks/$(basename "$hook")"
done

# Always copy schema (small file)
cp "$REPO_DIR/schema.json" "$TARGET_CLAUDE_DIR/promptforge/schema.json"
echo "  Copied   $TARGET_CLAUDE_DIR/promptforge/schema.json"

# Install commands
mkdir -p "$TARGET_CLAUDE_DIR/commands/promptforge"
for cmd in "$REPO_DIR/commands/"*.md; do
  [ -f "$cmd" ] || continue
  install_file "$cmd" "$TARGET_CLAUDE_DIR/commands/promptforge/$(basename "$cmd")"
done

# Install skills
mkdir -p "$TARGET_CLAUDE_DIR/skills"
for skill_dir in "$REPO_DIR/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  install_dir "$skill_dir" "$TARGET_CLAUDE_DIR/skills/promptforge-${skill_name}"
done

# --- Update settings.json with hook entries ---
SETTINGS_FILE="$TARGET_CLAUDE_DIR/settings.json"

# Ensure settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

HOOKS_DIR="$TARGET_CLAUDE_DIR/promptforge/hooks"

# Build the hooks array using jq
# Read existing settings, remove old promptforge hooks, add new ones
UPDATED=$(jq --arg hdir "$HOOKS_DIR" '
  # Remove existing promptforge hook entries (by command path containing "promptforge")
  .hooks = ((.hooks // []) | map(select(.command | tostring | contains("promptforge") | not)))
  # Also remove old log-prompts.sh hook
  | .hooks = (.hooks | map(select(.command | tostring | contains("log-prompts.sh") | not)))
  # Add new promptforge hooks
  | .hooks += [
    {
      "event": "UserPromptSubmit",
      "command": ($hdir + "/log-prompt.sh"),
      "timeout": 5000
    },
    {
      "event": "PostToolUse",
      "matcher": "AskUserQuestion",
      "command": ($hdir + "/log-ask-response.sh"),
      "timeout": 5000
    },
    {
      "event": "PostToolUseFailure",
      "command": ($hdir + "/log-tool-denial.sh"),
      "timeout": 5000
    },
    {
      "event": "Stop",
      "command": ($hdir + "/log-stop.sh"),
      "timeout": 10000
    }
  ]
' "$SETTINGS_FILE")

echo "$UPDATED" > "$SETTINGS_FILE"
echo "  Updated  $SETTINGS_FILE (4 hook entries)"

# Check if old log-prompts.sh was removed
if echo "$UPDATED" | jq -e '.hooks | map(select(.command | tostring | contains("log-prompts.sh"))) | length == 0' >/dev/null 2>&1; then
  echo "  Removed  old log-prompts.sh hook entry (if present)"
fi

echo ""
echo "Done!"
echo ""

# --- [3] Import existing session data ---
echo "[3] Import existing session history into promptforge logs?"
echo "    (y) Yes — parse existing Claude Code sessions + old prompt logs (may take a moment)"
echo "    (n) No — start fresh, only capture new interactions going forward"
printf "    > "
read -r IMPORT_CHOICE

if [ "$IMPORT_CHOICE" = "y" ]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo ""
    echo "Warning: python3 is required for import but not found. Skipping."
  else
    echo ""
    echo "Importing session history..."
    python3 "$REPO_DIR/scripts/extract-sessions.py" \
      --include-old-logs \
      --output "$TARGET_CLAUDE_DIR/promptforge/logs/" \
      && echo "Import complete." \
      || echo "Warning: Import encountered errors (partial data may have been written)."
  fi
fi

echo ""
echo "Installation complete. Run again to install to additional targets."
