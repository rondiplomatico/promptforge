# Skill: Improve Project Configuration

## Description
Uses promptforge friction analysis to suggest improvements to CLAUDE.md, permission settings, and memory files. Spawns a task agent to gather context without flooding the main conversation.

## Trigger
When user runs `/promptforge:improve-project` or asks to improve their project configuration based on friction analysis.

## Steps

1. **Check for Friction Report**:
   Look for `$SCOPE_FRICTION_REPORT`. If it doesn't exist, inform the user to run `/promptforge:analyze-corrections` first.

2. **Gather context via task agent**:
   Spawn a task agent to read files from `$SCOPE_TARGET_DIR`:
   - **Project scope**: `CLAUDE.md`, `.claude/settings.json`, project memory files (`~/.claude/projects/*/memory/`)
   - **Global scope**: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/memory/*`

   > Return a condensed summary organized as:
   > 1. **Key CLAUDE.md instructions** (one line each)
   > 2. **Permission patterns** (what's allowed/denied)
   > 3. **Memory entries** (key preferences and patterns stored)
   > 4. **Potential gaps** (areas not covered by current instructions)

3. **Read Friction Report**:
   Read `$SCOPE_FRICTION_REPORT`.

4. **Read recent logs** (optional):
   Scan recent promptforge logs for additional context on friction patterns.

5. **Cross-reference and generate suggestions**:
   For each friction pattern from the report:
   - Check if a CLAUDE.md instruction already exists (→ needs clarification)
   - Check if instruction is missing (→ needs addition)
   - Check if permission prevents the action (→ needs allow-list update)
   - Check memory for conflicting entries (→ needs correction)

6. **Present suggestions**:
   Number each suggestion with What/Why/Where/Priority.
   Ask user which to apply before making changes.

## Input
No explicit input. Uses friction report and project files.

## Output
- Numbered list of suggestions with diffs
- Applied changes (after user approval)
