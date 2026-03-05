# Skill: Improve Project Configuration

## Description
Uses claudeloop friction analysis to suggest improvements to CLAUDE.md, permission settings, and memory files. Spawns a task agent to gather context without flooding the main conversation.

## Trigger
When user runs `/claudeloop:improve-project` or asks to improve their project configuration based on friction analysis.

## Steps

1. **Check for Friction Report**:
   Look for `.claude/claudeloop/friction-report.md`. If it doesn't exist, inform the user to run `/claudeloop:analyze-corrections` first.

2. **Gather context via task agent**:
   Spawn a task agent with these instructions:
   > Read and summarize the following files for the current project:
   > - `CLAUDE.md` — list all key instructions, preferences, and constraints
   > - `.claude/settings.json` — extract the permissions section (allow/deny lists)
   > - All files in the project's memory directory (MEMORY.md and any topic files)
   >
   > Return a condensed summary organized as:
   > 1. **Key CLAUDE.md instructions** (one line each)
   > 2. **Permission patterns** (what's allowed/denied)
   > 3. **Memory entries** (key preferences and patterns stored)
   > 4. **Potential gaps** (areas not covered by current instructions)

3. **Read Friction Report**:
   Read `.claude/claudeloop/friction-report.md`.

4. **Read recent logs** (optional):
   Scan recent claudeloop logs for additional context on friction patterns.

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
