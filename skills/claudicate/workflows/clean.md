# Clean — Reset Logs and Reports

Remove accumulated log data and generated reports to start fresh.

## Prerequisites

None.

## Steps

### 1. Inventory

Determine the log directory based on scope:
- **Project scope**: `$SCOPE_TARGET_DIR/.claudicate/logs/`
- **Global scope**: `~/.claudicate/logs/`

Use Glob to list all `*.jsonl` files in the log directory. Also check whether a friction report exists at `$SCOPE_FRICTION_REPORT`.

Present a summary to the user:
- Number of log files found
- Date range (from filenames: `YYYY-MM-DD.jsonl`)
- Whether a friction report exists
- Total line count across all log files (use `wc -l`)

If no log files and no friction report exist, inform the user there is nothing to clean and stop.

### 2. Ask what to clean

Ask the user using AskUserQuestion with multiSelect enabled:

> **What should be cleaned?** (select one or more)
> 1. **All logs** — Delete all JSONL log files in the $SCOPE_LABEL scope
> 2. **Logs before a date** — Delete log files older than a specific date
> 3. **Friction report** — Delete the generated friction report

### 3. Collect date (if applicable)

If the user selected "Logs before a date", ask for the cutoff date using AskUserQuestion:

> **Delete logs before which date?** (YYYY-MM-DD)

Provide sensible suggestions as options (e.g., 30 days ago, 90 days ago, 180 days ago).

### 4. Confirm

Show the user exactly what will be deleted:
- List the specific files (or count if many) and their total size
- For date-based deletion: show which date files will be kept vs deleted

Ask for explicit confirmation using AskUserQuestion before proceeding.

### 5. Execute

Delete the confirmed files using Bash `rm` commands:
- **All logs**: `rm <log_dir>/*.jsonl`
- **Logs before date**: `rm` each file where the filename date is before the cutoff
- **Friction report**: `rm $SCOPE_FRICTION_REPORT`

### 6. Report

Confirm what was deleted and what remains (if anything).
