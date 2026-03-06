# Improve Project Configuration

Use promptforge friction analysis to suggest improvements to CLAUDE.md, permissions, and memory files.

**Before running this command**, read and follow the scope selection procedure in the `_scope-preamble.md` file located alongside this command file.

## Prerequisites

This command works best after running `/promptforge:analyze-corrections` to generate a Friction Report. If no friction report exists at `$SCOPE_FRICTION_REPORT`, run the analysis first.

## Data Sources

1. **Friction Report**: `$SCOPE_FRICTION_REPORT`
2. **PromptForge logs**: `~/.claude/promptforge/logs/*.jsonl` and project logs
3. **Current config** (read via task agent to avoid context flooding), resolved by scope:
   - **Project scope**: `CLAUDE.md`, `.claude/settings.json`, project memory directory
   - **Global scope**: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/memory/`

## Process

### Step 1: Gather Context
Spawn a task agent to read and summarize the config files at `$SCOPE_TARGET_DIR`:
- **Project scope**: `CLAUDE.md`, `.claude/settings.json`, project memory files (`~/.claude/projects/*/memory/`)
- **Global scope**: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/memory/*`
Ask the agent to return a condensed summary of: key instructions, permission patterns, and stored preferences.

### Step 2: Read Friction Report
Read `$SCOPE_FRICTION_REPORT` for the top friction patterns.

### Step 3: Cross-Reference
For each friction pattern, determine:
- Is there already a CLAUDE.md instruction that should prevent this? (instruction exists but is ignored/unclear)
- Is there a missing instruction? (no guidance exists for this situation)
- Is there a permission issue? (tool gets denied because it's not in the allow list)
- Is there a memory inconsistency? (memory says one thing, CLAUDE.md says another)

### Step 4: Generate Suggestions

Produce actionable suggestions as diffs/patches:

#### CLAUDE.md Changes
- New instructions to add (with exact text)
- Existing instructions to clarify or modify
- Cite the friction pattern that motivates each change

#### Permission Changes
- Tools to add to allow lists (commonly approved after denial)
- Patterns for automatic approval

#### Memory File Updates
- New memory entries to add
- Existing entries to correct or update
- Entries that should be promoted to CLAUDE.md (stable enough)

## Output

Present suggestions as a numbered list with:
- **What**: The specific change
- **Why**: The friction pattern it addresses (with example from logs)
- **Where**: Exact file and location
- **Priority**: High (frequent friction) / Medium / Low

Ask the user which suggestions to apply before making any changes.
