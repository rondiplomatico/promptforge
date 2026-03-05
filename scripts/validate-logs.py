#!/usr/bin/env python3
"""
promptforge: validate-logs.py
Validates JSONL log files against the promptforge schema.
"""

import json
import sys
from pathlib import Path

# Inline schema validation (no jsonschema dependency required)
REQUIRED_FIELDS = {"timestamp", "event_type", "session_id"}
VALID_EVENT_TYPES = {"prompt", "ask_response", "tool_denial", "turn_end"}
EVENT_REQUIRED = {
    "prompt": ["prompt"],
    "ask_response": ["question", "answer"],
    "tool_denial": ["denied_tool"],
    "turn_end": [],
}


def validate_entry(entry, line_num):
    """Validate a single log entry. Returns list of error strings."""
    errors = []

    if not isinstance(entry, dict):
        return [f"Line {line_num}: Not a JSON object"]

    # Required fields
    for field in REQUIRED_FIELDS:
        if field not in entry:
            errors.append(f"Line {line_num}: Missing required field '{field}'")

    event_type = entry.get("event_type")
    if event_type and event_type not in VALID_EVENT_TYPES:
        errors.append(f"Line {line_num}: Invalid event_type '{event_type}'")

    # Event-specific required fields
    if event_type in EVENT_REQUIRED:
        for field in EVENT_REQUIRED[event_type]:
            if field not in entry:
                errors.append(f"Line {line_num}: event_type '{event_type}' missing required field '{field}'")

    # Type checks
    if "tags" in entry and not isinstance(entry["tags"], list):
        errors.append(f"Line {line_num}: 'tags' must be an array")

    if "token_usage" in entry and not isinstance(entry["token_usage"], dict):
        errors.append(f"Line {line_num}: 'token_usage' must be an object")

    if "is_interrupt" in entry and not isinstance(entry["is_interrupt"], bool):
        errors.append(f"Line {line_num}: 'is_interrupt' must be a boolean")

    return errors


def validate_file(filepath):
    """Validate a JSONL file. Returns (entry_count, error_list)."""
    errors = []
    count = 0

    with open(filepath, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            count += 1
            try:
                entry = json.loads(line)
            except json.JSONDecodeError as e:
                errors.append(f"Line {line_num}: Invalid JSON: {e}")
                continue
            errors.extend(validate_entry(entry, line_num))

    return count, errors


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Validate promptforge JSONL log files")
    parser.add_argument("paths", nargs="*", help="Log files or directories to validate")
    parser.add_argument("--quiet", "-q", action="store_true", help="Only show errors")
    args = parser.parse_args()

    # Default: check both global and project log dirs
    paths = args.paths
    if not paths:
        default_dirs = [
            Path.home() / ".claude" / "promptforge" / "logs",
        ]
        # Also check CLAUDE_PROJECT_DIR if set
        proj_dir = os.environ.get("CLAUDE_PROJECT_DIR")
        if proj_dir:
            default_dirs.append(Path(proj_dir) / ".claude" / "promptforge" / "logs")
        paths = [str(d) for d in default_dirs if d.exists()]

    if not paths:
        print("No log files found to validate.")
        print("Usage: validate-logs.py [path/to/logs/ ...]")
        sys.exit(0)

    total_files = 0
    total_entries = 0
    total_errors = 0

    for path_str in paths:
        path = Path(path_str)
        if path.is_dir():
            files = sorted(path.glob("*.jsonl"))
        elif path.is_file():
            files = [path]
        else:
            print(f"Warning: '{path_str}' not found, skipping.")
            continue

        for filepath in files:
            total_files += 1
            count, errors = validate_file(filepath)
            total_entries += count
            total_errors += len(errors)

            if errors:
                print(f"\n{filepath} ({count} entries, {len(errors)} errors):")
                for err in errors:
                    print(f"  {err}")
            elif not args.quiet:
                print(f"{filepath}: {count} entries, all valid")

    print(f"\nSummary: {total_files} files, {total_entries} entries, {total_errors} errors")
    sys.exit(1 if total_errors > 0 else 0)


if __name__ == "__main__":
    import os
    main()
