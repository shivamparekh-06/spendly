#!/bin/bash
# ============================================================
# HOOK 6: Session Start Summary
# Spendly Project
# ============================================================
# TOOLS USED:
#   - git (built-in to most dev systems)
#   - Python3 (standard)
#   - Pure bash
#
# WHAT IT SHOWS AT THE START OF EVERY CLAUDE SESSION:
#   ✅ Overview of Spendly project progress
#   📝 Last git commits (what was done)
#   🔧 Modified files not yet committed
#   🐛 TODO/FIXME/HACK comments found in code
#   📊 Telemetry from last session (what Claude did)
#   🎯 Suggested next steps (based on CLAUDE.md future enhancements)
#
# HOW TO USE IN CLAUDE CODE:
#   Add as a PreToolUse hook on "start" events, OR
#   Run manually: bash hook6_session_summary.sh
#   OR add to .claude/settings.json as a startup hook
# ============================================================

PROJECT="Spendly — Flask Expense Tracker"
CLAUDE_MD="CLAUDE.md"
TELEMETRY_DIR=".spendly_telemetry"
TODAY=$(date '+%Y-%m-%d')

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║        🏦 SPENDLY — SESSION START BRIEFING          ║"
echo "║        $(date '+%A, %B %d %Y — %H:%M')              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# SECTION 1: Project Snapshot
# ============================================================
echo "📁 PROJECT STRUCTURE"
echo "─────────────────────"

# Count files
PY_COUNT=$(find . -name "*.py" -not -path "./venv/*" 2>/dev/null | wc -l | tr -d ' ')
HTML_COUNT=$(find ./templates -name "*.html" 2>/dev/null | wc -l | tr -d ' ')
CSS_LINES=$(wc -l < ./static/css/style.css 2>/dev/null || echo "?")
JS_LINES=$(wc -l < ./static/js/main.js 2>/dev/null || echo "?")
DB_SIZE=$(du -sh spendly.db 2>/dev/null | cut -f1 || echo "not found")

echo "  🐍 Python files   : $PY_COUNT"
echo "  🌐 HTML templates : $HTML_COUNT"
echo "  🎨 CSS lines      : $CSS_LINES"
echo "  ⚡ JS lines       : $JS_LINES"
echo "  💾 Database size  : $DB_SIZE"
echo ""

# ============================================================
# SECTION 2: Git Status — What's been done, what's pending
# ============================================================
echo "📝 GIT STATUS"
echo "─────────────────────"

if git rev-parse --git-dir > /dev/null 2>&1; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    echo "  🌿 Branch: $CURRENT_BRANCH"
    echo ""

    echo "  📜 Last 5 commits:"
    git log --oneline -5 2>/dev/null | while read line; do
        echo "    • $line"
    done
    echo ""

    MODIFIED=$(git status --porcelain 2>/dev/null)
    if [ -n "$MODIFIED" ]; then
        MODIFIED_COUNT=$(echo "$MODIFIED" | wc -l | tr -d ' ')
        echo "  ⚠️  Uncommitted changes ($MODIFIED_COUNT files):"
        echo "$MODIFIED" | head -10 | while read line; do
            echo "    $line"
        done
        [ "$MODIFIED_COUNT" -gt 10 ] && echo "    ... and $((MODIFIED_COUNT - 10)) more"
    else
        echo "  ✅ Working tree clean — all changes committed"
    fi
else
    echo "  ℹ️  Not a git repository"
fi
echo ""

# ============================================================
# SECTION 3: Code Health — TODOs and FIXMEs
# ============================================================
echo "🔧 CODE NOTES (TODO/FIXME/HACK)"
echo "─────────────────────"

TODO_COUNT=$(grep -rn "TODO\|FIXME\|HACK\|XXX\|BUG" \
    --include="*.py" --include="*.html" --include="*.js" --include="*.css" \
    --exclude-dir=venv --exclude-dir=.venv \
    . 2>/dev/null | wc -l | tr -d ' ')

if [ "$TODO_COUNT" -gt 0 ]; then
    echo "  Found $TODO_COUNT notes:"
    grep -rn "TODO\|FIXME\|HACK" \
        --include="*.py" --include="*.html" --include="*.js" \
        --exclude-dir=venv --exclude-dir=.venv \
        . 2>/dev/null | head -8 | while read line; do
        echo "    ⚡ $line"
    done
    [ "$TODO_COUNT" -gt 8 ] && echo "    ... and $((TODO_COUNT - 8)) more"
else
    echo "  ✅ No TODO/FIXME/HACK comments found"
fi
echo ""

# ============================================================
# SECTION 4: Last Session Telemetry (from Hook 5)
# ============================================================
echo "📊 LAST SESSION ACTIVITY"
echo "─────────────────────"

YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d' 2>/dev/null)

python3 - << PYEOF
import json, os

telemetry_dir = "$TELEMETRY_DIR"
today = "$TODAY"
yesterday = "$YESTERDAY"

# Try today and yesterday
for day in [today, yesterday]:
    log_file = os.path.join(telemetry_dir, f"{day}.json")
    if os.path.exists(log_file):
        try:
            with open(log_file) as f:
                data = json.load(f)
            events = data.get("events", [])
            if events:
                print(f"  📅 {day}: {len(events)} Claude actions")
                
                # Count by category
                cats = {}
                files_touched = set()
                for e in events:
                    cat = e.get("category", "other")
                    cats[cat] = cats.get(cat, 0) + 1
                    if cat in ("file_edit", "file_write", "file_read"):
                        subj = e.get("subject", "")
                        if subj:
                            files_touched.add(subj.split("/")[-1])
                
                for cat, count in sorted(cats.items(), key=lambda x: -x[1])[:4]:
                    print(f"    • {cat}: {count}")
                
                if files_touched:
                    print(f"  📂 Files touched: {', '.join(list(files_touched)[:6])}")
                break
        except:
            pass
else:
    print("  ℹ️  No telemetry yet (Hook 5 will start logging once you use it)")
PYEOF
echo ""

# ============================================================
# SECTION 5: Routes & Feature Map
# ============================================================
echo "🗺️  CURRENT ROUTES"
echo "─────────────────────"
if [ -f "app.py" ]; then
    grep -n "@app.route" app.py 2>/dev/null | while read line; do
        echo "  $line"
    done
else
    echo "  app.py not found in current directory"
fi
echo ""

# ============================================================
# SECTION 6: Suggested Next Steps
# (Based on CLAUDE.md Future Enhancements + git log)
# ============================================================
echo "🎯 SUGGESTED NEXT STEPS"
echo "─────────────────────"
echo "  Based on CLAUDE.md and current project state:"
echo ""

# Check which features exist and suggest what's missing
TEMPLATES=$(ls templates/ 2>/dev/null)
HAS_DASHBOARD=$(echo "$TEMPLATES" | grep -c "dashboard" || echo 0)
HAS_ADD=$(echo "$TEMPLATES" | grep -c "add\|expense" || echo 0)
HAS_EDIT=$(echo "$TEMPLATES" | grep -c "edit" || echo 0)
HAS_EXPORT=$(grep -rl "export\|csv" templates/ static/ 2>/dev/null | wc -l | tr -d ' ')

SUGGESTIONS=()

[ "$HAS_EDIT" -eq 0 ] && echo "  💡 1. Add 'Edit Expense' feature (template + route missing)"
[ "$HAS_EXPORT" -eq 0 ] && echo "  💡 2. Export to CSV — great for Indian tax purposes"
grep -q "budget\|limit" app.py 2>/dev/null || echo "  💡 3. Budget limits & overspend alerts per category"
grep -q "chart\|graph\|canvas\|recharts" static/js/main.js 2>/dev/null || echo "  💡 4. Add spending charts (Chart.js already zero-install)"
grep -q "recurring\|repeat" app.py 2>/dev/null || echo "  💡 5. Recurring expenses (rent, subscriptions, EMIs)"
grep -q "pwa\|manifest\|service.worker" templates/base.html 2>/dev/null || echo "  💡 6. Make Spendly a PWA for mobile use"

echo ""
echo "  📖 Full future plans: see CLAUDE.md → Future Enhancements"
echo ""

# ============================================================
# FOOTER
# ============================================================
echo "╔══════════════════════════════════════════════════════╗"
echo "║  🚀 Session ready! Spendly briefing complete.        ║"
echo "║  All hooks active. Happy coding!                     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
