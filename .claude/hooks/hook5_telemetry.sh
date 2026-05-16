#!/bin/bash
# ============================================================
# HOOK 5: Telemetry — Local Action Logging
# Spendly Project
# ============================================================
# TOOLS USED:
#   - Pure bash + Python3 (standard, no install needed)
#   - All data stays LOCAL — nothing sent to internet
#
# WHAT IT LOGS (in .spendly_telemetry/):
#   - Every file Claude reads, writes, or edits
#   - Every bash command Claude runs
#   - Timestamps, durations, success/failure
#   - Daily summaries in JSON and a human-readable log
#
# HOW TO USE IN CLAUDE CODE:
#   Add as BOTH PreToolUse and PostToolUse hook
#   Pass $1=tool_name, $2=file_or_command, $3=status(pre/post)
#
# VIEW YOUR TELEMETRY:
#   cat .spendly_telemetry/today.log
#   cat .spendly_telemetry/summary.json
# ============================================================

TOOL_NAME="${1:-unknown}"    # e.g., Read, Write, Bash, Edit
SUBJECT="${2:-unknown}"      # file path or command
PHASE="${3:-post}"           # "pre" (before) or "post" (after)
STATUS="${4:-ok}"            # "ok" or "error"

TELEMETRY_DIR=".spendly_telemetry"
TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP=$(date +%s)

# Create telemetry dir (gitignored)
mkdir -p "$TELEMETRY_DIR"

# Make sure .gitignore ignores telemetry
if [ -f ".gitignore" ]; then
    if ! grep -q ".spendly_telemetry" .gitignore; then
        echo "" >> .gitignore
        echo "# Claude Code telemetry (local only)" >> .gitignore
        echo ".spendly_telemetry/" >> .gitignore
        echo "spendly_notifier.html" >> .gitignore
        echo ".spendly_claude_status.json" >> .gitignore
        echo ".spendly_task_history.json" >> .gitignore
    fi
fi

LOG_FILE="$TELEMETRY_DIR/${TODAY}.log"
JSON_LOG="$TELEMETRY_DIR/${TODAY}.json"
SUMMARY_FILE="$TELEMETRY_DIR/summary.json"

# ---- Categorize the tool ----
categorize_tool() {
    case "$1" in
        Read|View)          echo "file_read" ;;
        Write|Create)       echo "file_write" ;;
        Edit|Str_replace)   echo "file_edit" ;;
        Bash|Shell)         echo "shell_command" ;;
        Search|Grep)        echo "search" ;;
        *)                  echo "other" ;;
    esac
}

CATEGORY=$(categorize_tool "$TOOL_NAME")

# ---- Write to human-readable log ----
PHASE_ICON="→"
[ "$PHASE" = "post" ] && PHASE_ICON="✓"
[ "$STATUS" = "error" ] && PHASE_ICON="✗"

echo "[$NOW] $PHASE_ICON [$TOOL_NAME] $SUBJECT" >> "$LOG_FILE"

# ---- Write to JSON log ----
python3 - << PYEOF
import json, os, time

json_log = "$JSON_LOG"
entry = {
    "timestamp": "$NOW",
    "unix_time": $TIMESTAMP,
    "phase": "$PHASE",
    "tool": "$TOOL_NAME",
    "category": "$CATEGORY",
    "subject": "$SUBJECT",
    "status": "$STATUS"
}

# Load existing or create new
try:
    with open(json_log) as f:
        data = json.load(f)
except:
    data = {"date": "$TODAY", "project": "spendly", "events": []}

data["events"].append(entry)

with open(json_log, 'w') as f:
    json.dump(data, f, indent=2)

# Update rolling summary
summary_file = "$SUMMARY_FILE"
try:
    with open(summary_file) as f:
        summary = json.load(f)
except:
    summary = {
        "project": "spendly",
        "total_events": 0,
        "by_category": {},
        "by_day": {},
        "most_edited_files": {},
        "last_updated": ""
    }

summary["total_events"] += 1
summary["by_category"][$CATEGORY] = summary["by_category"].get("$CATEGORY", 0) + 1
summary["by_day"]["$TODAY"] = summary["by_day"].get("$TODAY", 0) + 1
summary["last_updated"] = "$NOW"

# Track most-edited files
if "$CATEGORY" in ("file_edit", "file_write", "file_read"):
    subject = "$SUBJECT"
    summary["most_edited_files"][subject] = summary["most_edited_files"].get(subject, 0) + 1

with open(summary_file, 'w') as f:
    json.dump(summary, f, indent=2)

print(f"  📊 Telemetry logged: [{entry['category']}] {entry['subject'][:60]}")
PYEOF

# ---- Every 50 events, print a mini summary to console ----
EVENT_COUNT=$(python3 -c "
import json
try:
    with open('$SUMMARY_FILE') as f:
        d = json.load(f)
    print(d.get('total_events', 0))
except:
    print(0)
")

if [ $((EVENT_COUNT % 50)) -eq 0 ] && [ "$EVENT_COUNT" -gt 0 ]; then
    echo ""
    echo "📊 ====== SPENDLY TELEMETRY MILESTONE: $EVENT_COUNT events ======"
    python3 -c "
import json
with open('$SUMMARY_FILE') as f:
    s = json.load(f)
print('  Top categories:', dict(sorted(s['by_category'].items(), key=lambda x: -x[1])[:3]))
top_files = sorted(s.get('most_edited_files', {}).items(), key=lambda x: -x[1])[:3]
print('  Most worked on:', [f[0].split('/')[-1] for f in top_files])
"
    echo "======================================================"
    echo ""
fi

exit 0
