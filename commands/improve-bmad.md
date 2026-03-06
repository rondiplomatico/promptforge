# Improve BMAD Configuration

Use promptforge friction analysis to suggest improvements to BMAD agents, tasks, checklists, and configuration.

**Before running this command**, read and follow the scope selection procedure in the `_scope-preamble.md` file located alongside this command file.

**Note**: BMAD configuration (`.bmad-core/`) is project-local. If global scope was selected, inform the user that this command only works in project scope. Offer to switch to project scope or abort.

## Prerequisites

This command works best after running `/promptforge:analyze-corrections` to generate a Friction Report. If no friction report exists at `$SCOPE_FRICTION_REPORT`, run the analysis first.

## Data Sources

1. **Friction Report**: `$SCOPE_FRICTION_REPORT`
2. **PromptForge logs**: `~/.claude/promptforge/logs/*.jsonl` and project logs
3. **BMAD files** (read via task agent to avoid context flooding):
   - `.bmad-core/core-config.yaml`
   - `.bmad-core/agents/*.md` (only those mentioned in friction report)
   - `.bmad-core/tasks/*.md` (only those mentioned in friction report)
   - `.bmad-core/checklists/*.md`
   - Project memory files (for cross-referencing preferences)

## Process

### Step 1: Identify BMAD-Related Friction
Filter the friction report for patterns tagged with `bmad`, `bmad:<agent>`, or `bmad_task:<task>`. Also look for:
- Friction during BMAD agent sessions (session contains bmad-tagged prompts)
- Repeated clarifications about BMAD workflow
- Tool denials during BMAD task execution

### Step 2: Gather BMAD Context
Spawn a task agent to read and summarize the relevant BMAD files:
- Only read agents/tasks that appear in the friction patterns
- Summarize their current instructions, constraints, and behavior
- Read memory files for cross-referencing stored preferences
- Return a condensed context report

### Step 3: Cross-Reference
For each BMAD-related friction pattern:
- Does the agent instruction cause the friction? (e.g., asks unnecessary questions)
- Is the task template missing guidance? (e.g., doesn't specify output format)
- Is a checklist too strict or too lenient?
- Does core-config.yaml need adjustment?

### Step 4: Generate Suggestions

Produce actionable suggestions:

#### Agent Instruction Patches
- Specific text to add/modify in agent .md files
- Example: "QA agent asks for test framework every time → add default: pytest"

#### Task Template Adjustments
- Steps to add, remove, or clarify in task definitions
- Default values to set to reduce clarification questions

#### Checklist Refinements
- Items to add or relax based on friction patterns
- Quality gates that cause unnecessary rework

#### core-config.yaml Tweaks
- Settings to add or modify
- devLoadAlwaysFiles updates

## Output

Present suggestions as a numbered list with:
- **What**: The specific change (with exact text for patches)
- **Why**: The friction pattern it addresses (with example from logs)
- **Where**: Exact file path and section
- **Priority**: High (frequent friction) / Medium / Low

Ask the user which suggestions to apply before making any changes.
