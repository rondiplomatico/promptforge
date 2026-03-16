#!/bin/bash
# claudicate installer — interactive, no CLI arguments
# Installs hooks, scripts, and skill to a target directory
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST_FILES=()

echo "=== claudicate installer ==="
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
while true; do
  echo "[1] Install target"
  echo "    (g) Global (~/.claudicate/ + ~/.claude/)"
  echo "    (p) Project — enter path"
  echo "    (.) Current directory ($(pwd))"
  echo "    (q) Cancel"
  printf "    > "
  read -r TARGET_CHOICE
  TARGET_CHOICE=$(echo "$TARGET_CHOICE" | tr '[:upper:]' '[:lower:]')

  case "$TARGET_CHOICE" in
    g)
      TARGET_BASE="$HOME"
      break
      ;;
    p)
      printf "    Enter project path: "
      read -r PROJECT_PATH
      if [ ! -d "$PROJECT_PATH" ]; then
        echo "    Directory '$PROJECT_PATH' does not exist. Try again."
        echo ""
        continue
      fi
      TARGET_BASE="$PROJECT_PATH"
      break
      ;;
    .)
      TARGET_BASE="$(pwd)"
      break
      ;;
    q)
      echo "Cancelled."
      exit 0
      ;;
    *)
      echo "    Invalid choice. Try again."
      echo ""
      ;;
  esac
done

TARGET_PF_DIR="$TARGET_BASE/.claudicate"
TARGET_CLAUDE_DIR="$TARGET_BASE/.claude"
echo ""

# --- [2] Install mode ---
while true; do
  echo "[2] Install mode"
  echo "    (l) Link — symlink back to this repo (auto-updates on git pull)"
  echo "    (c) Copy — standalone copy (requires manual re-install for updates)"
  echo "    (q) Cancel"
  printf "    > "
  read -r MODE_CHOICE
  MODE_CHOICE=$(echo "$MODE_CHOICE" | tr '[:upper:]' '[:lower:]')

  case "$MODE_CHOICE" in
    l) INSTALL_MODE="link"; break ;;
    c) INSTALL_MODE="copy"; break ;;
    q) echo "Cancelled."; exit 0 ;;
    *) echo "    Invalid choice. Try again."; echo "" ;;
  esac
done
echo ""

# --- Execute installation ---
echo "Installing to $TARGET_PF_DIR (data) + $TARGET_CLAUDE_DIR (skill/hooks config)..."

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
  MANIFEST_FILES+=("$dst")
}

# Helper: install a directory (symlink or copy)
install_dir() {
  local src="$1" dst="$2"
  if [ "$INSTALL_MODE" = "link" ]; then
    ln -sfn "$src" "$dst"
    echo "  Linked   $dst → $src"
    MANIFEST_FILES+=("$dst")
  else
    rm -rf "$dst"
    cp -r "$src" "$dst"
    echo "  Copied   $dst"
    # Add all files in the copied directory to manifest
    while IFS= read -r -d '' f; do
      MANIFEST_FILES+=("$f")
    done < <(find "$dst" -type f -print0)
  fi
}

# Create .claudicate directories
mkdir -p "$TARGET_PF_DIR/logs"
echo "  Created  $TARGET_PF_DIR/logs/"
mkdir -p "$TARGET_PF_DIR/hooks"

# Install hook scripts to .claudicate/hooks/
chmod +x "$REPO_DIR/hooks/"*.sh
for hook in "$REPO_DIR/hooks/"*.sh; do
  install_file "$hook" "$TARGET_PF_DIR/hooks/$(basename "$hook")"
done

# Always copy schema (small file)
cp "$REPO_DIR/schema.json" "$TARGET_PF_DIR/schema.json"
echo "  Copied   $TARGET_PF_DIR/schema.json"
MANIFEST_FILES+=("$TARGET_PF_DIR/schema.json")

# Install unified skill to .claude/skills/
mkdir -p "$TARGET_CLAUDE_DIR/skills"
install_dir "$REPO_DIR/skills/claudicate" "$TARGET_CLAUDE_DIR/skills/claudicate"

# --- Write install manifest ---
printf '%s\n' "${MANIFEST_FILES[@]}" > "$TARGET_PF_DIR/install.manifest"
echo "  Written  $TARGET_PF_DIR/install.manifest (${#MANIFEST_FILES[@]} entries)"

# --- Write setup.yaml ---
case "$TARGET_CHOICE" in
  g) SCOPE="global" ;;
  *) SCOPE="project" ;;
esac

{
  echo "# Written by claudicate installer"
  echo "scope: $SCOPE"
  echo "install_mode: $INSTALL_MODE"
  echo "source: $REPO_DIR"
  echo "installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "manifest:"
  for f in "${MANIFEST_FILES[@]}"; do
    echo "  - $f"
  done
} > "$TARGET_PF_DIR/setup.yaml"
echo "  Written  $TARGET_PF_DIR/setup.yaml"

# --- Update settings with hook entries ---
# Global installs use settings.json (settings.local.json is not supported at ~/.claude/).
# Project installs use settings.local.json (non-committed, machine-specific paths).
if [ "$SCOPE" = "global" ]; then
  SETTINGS_FILE="$TARGET_CLAUDE_DIR/settings.json"
else
  SETTINGS_FILE="$TARGET_CLAUDE_DIR/settings.local.json"
fi

# Ensure settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

HOOKS_DIR="$TARGET_PF_DIR/hooks"

# Build hooks in Claude Code's required format:
#   { "hooks": { "EventName": [ { "matcher": "...", "hooks": [ { "type": "command", "command": "..." } ] } ] } }
# Read existing settings, remove old claudicate hook entries, add new ones
UPDATED=$(jq --arg hdir "$HOOKS_DIR" '
  # Ensure hooks is an object
  .hooks = (.hooks // {})
  |
  # Helper: filter out existing claudicate entries from an event array
  def remove_pf: map(select(.hooks | all(.command | tostring | contains("claudicate") | not)));
  # Clean existing claudicate entries from all events
  .hooks |= with_entries(.value |= remove_pf)
  |
  # Add claudicate hooks
  .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) + [
    { "hooks": [{ "type": "command", "command": ($hdir + "/log-prompt.sh"), "timeout": 5000 }] }
  ])
  |
  .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [
    { "matcher": "AskUserQuestion",
      "hooks": [{ "type": "command", "command": ($hdir + "/log-ask-response.sh"), "timeout": 5000 }] },
    { "matcher": "Bash|Write|Edit",
      "hooks": [{ "type": "command", "command": ($hdir + "/log-tool-use.sh"), "timeout": 5000 }] }
  ])
  |
  .hooks.PostToolUseFailure = ((.hooks.PostToolUseFailure // []) + [
    { "hooks": [{ "type": "command", "command": ($hdir + "/log-tool-denial.sh"), "timeout": 5000 }] }
  ])
  |
  .hooks.Stop = ((.hooks.Stop // []) + [
    { "hooks": [{ "type": "command", "command": ($hdir + "/log-stop.sh"), "timeout": 10000 }] }
  ])
' "$SETTINGS_FILE")

echo "$UPDATED" > "$SETTINGS_FILE"
echo "  Updated  $SETTINGS_FILE (5 hook entries)"


echo ""
echo "Done!"
echo ""

# --- [3] Gitignore check (project installs only) ---
if [ "$TARGET_CHOICE" != "g" ] && [ -d "$TARGET_BASE/.git" ]; then
  GITIGNORE="$TARGET_BASE/.gitignore"
  NEEDS_ADD=true

  if [ -f "$GITIGNORE" ]; then
    # Check if .claudicate is already ignored (exact line or with trailing slash)
    if grep -qxF '.claudicate' "$GITIGNORE" 2>/dev/null || \
       grep -qxF '.claudicate/' "$GITIGNORE" 2>/dev/null || \
       grep -qxF '/.claudicate' "$GITIGNORE" 2>/dev/null || \
       grep -qxF '/.claudicate/' "$GITIGNORE" 2>/dev/null; then
      NEEDS_ADD=false
      echo "[3] .claudicate/ is already in .gitignore ✓"
    fi
  fi

  if [ "$NEEDS_ADD" = true ]; then
    echo "[3] This is a git repository. .claudicate/ contains usage logs"
    echo "    (session prompts, tool invocations, timestamps) that should"
    echo "    NOT be committed to version control."
    echo ""
    while true; do
      echo "    (a) Add '.claudicate/' to .gitignore (Recommended)"
      echo "    (s) Skip — I'll handle it myself"
      echo "    (q) Cancel"
      printf "    > "
      read -r GITIGNORE_CHOICE
      GITIGNORE_CHOICE=$(echo "$GITIGNORE_CHOICE" | tr '[:upper:]' '[:lower:]')

      case "$GITIGNORE_CHOICE" in
        a)
          # Add with a comment header if .gitignore doesn't exist or doesn't have it
          if [ ! -f "$GITIGNORE" ]; then
            echo "# claudicate interaction logs" > "$GITIGNORE"
            echo ".claudicate/" >> "$GITIGNORE"
            echo "  Created  $GITIGNORE with .claudicate/ entry"
          else
            # Add a blank line separator if file doesn't end with newline
            [ -s "$GITIGNORE" ] && [ "$(tail -c 1 "$GITIGNORE")" != "" ] && echo "" >> "$GITIGNORE"
            echo "" >> "$GITIGNORE"
            echo "# claudicate interaction logs" >> "$GITIGNORE"
            echo ".claudicate/" >> "$GITIGNORE"
            echo "  Added    .claudicate/ to $GITIGNORE"
          fi
          break
          ;;
        s)
          echo ""
          echo "    ⚠  WARNING: .claudicate/logs/ contains full usage logs including"
          echo "    session prompts, tool arguments, and timestamps. Without a .gitignore"
          echo "    entry, this data WILL be committed to version control."
          echo ""
          break
          ;;
        q) echo "Cancelled."; exit 0 ;;
        *) echo "    Invalid choice. Try again."; echo "" ;;
      esac
    done
  fi
  echo ""
fi

# --- [4] Import existing session data ---
while true; do
  echo "[4] Import existing session history into claudicate logs?"
  echo "    (y) Yes — parse existing Claude Code sessions + old prompt logs (may take a moment)"
  echo "    (n) No — start fresh, only capture new interactions going forward"
  echo "    (q) Cancel"
  printf "    > "
  read -r IMPORT_CHOICE
  IMPORT_CHOICE=$(echo "$IMPORT_CHOICE" | tr '[:upper:]' '[:lower:]')

  case "$IMPORT_CHOICE" in
    y|n|q) break ;;
    *) echo "    Invalid choice. Try again."; echo "" ;;
  esac
done

if [ "$IMPORT_CHOICE" = "q" ]; then
  echo "Cancelled."
  exit 0
fi

if [ "$IMPORT_CHOICE" = "y" ]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo ""
    echo "Warning: python3 is required for import but not found. Skipping."
  else
    echo ""
    echo "Importing session history..."
    IMPORT_ARGS=(--include-old-logs --output "$TARGET_PF_DIR/logs/")
    # For project-specific installs, filter to only this project's sessions
    if [ "$TARGET_CHOICE" != "g" ]; then
      IMPORT_ARGS+=(--project "$TARGET_BASE")
    fi
    python3 "$REPO_DIR/scripts/extract-sessions.py" "${IMPORT_ARGS[@]}" \
      && echo "Import complete." \
      || echo "Warning: Import encountered errors (partial data may have been written)."
  fi
fi

echo ""
echo "Installation complete. Run again to install to additional targets."
