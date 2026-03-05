# Skill: Improve BMAD Configuration

## Description
Uses promptforge friction analysis to suggest improvements to BMAD agents, tasks, checklists, and core configuration. Spawns a task agent to gather context without flooding the main conversation.

## Trigger
When user runs `/promptforge:improve-bmad` or asks to improve their BMAD setup based on friction analysis.

## Steps

1. **Check for Friction Report**:
   Look for `.claude/promptforge/friction-report.md`. If it doesn't exist, inform the user to run `/promptforge:analyze-corrections` first.

2. **Identify BMAD-related friction**:
   Read the friction report and filter for patterns tagged with `bmad`, `bmad:<agent>`, or `bmad_task:<task>`.
   Also identify friction that occurred during BMAD sessions.

3. **Gather BMAD context via task agent**:
   Based on the agents/tasks identified in step 2, spawn a task agent:
   > Read and summarize the following BMAD files:
   > - `.bmad-core/core-config.yaml` — current BMAD settings
   > - `.bmad-core/agents/<name>.md` — for each agent mentioned in friction patterns
   > - `.bmad-core/tasks/<name>.md` — for each task mentioned in friction patterns
   > - `.bmad-core/checklists/*.md` — relevant validation checklists
   > - Project memory files — for cross-referencing stored preferences
   >
   > Return a condensed summary organized as:
   > 1. **Core config settings** (key values)
   > 2. **Agent instructions** (key behaviors for each relevant agent)
   > 3. **Task definitions** (key steps for each relevant task)
   > 4. **Checklist items** (gates and quality checks)
   > 5. **Memory preferences** (that should propagate to BMAD)

4. **Cross-reference and generate suggestions**:
   For each BMAD-related friction pattern:
   - Does the agent ask unnecessary questions? → Add defaults
   - Is the task template missing steps? → Add guidance
   - Is a checklist too strict/lenient? → Adjust gates
   - Does core-config need settings? → Add/modify values

5. **Present suggestions**:
   Number each suggestion with What/Why/Where/Priority.
   Ask user which to apply before making changes.

## Input
No explicit input. Uses friction report and BMAD files.

## Output
- Numbered list of suggestions with exact text patches
- Applied changes (after user approval)
