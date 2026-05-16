#!/bin/bash
# ============================================================
# HOOK 1: Auto-Formatting & Linting
# Spendly Project — Flask (Python) + HTML/CSS/JS
# ============================================================
# TOOLS USED:
#   - black      → Python code formatter (PEP8 compliant)
#   - flake8     → Python linter (catches bugs, style issues)
#   - isort      → Sorts Python imports automatically
#   - prettier   → Formats HTML, CSS, JS files
#
# INSTALL ONCE:
#   pip install black flake8 isort
#   npm install -g prettier
#
# HOW TO USE IN CLAUDE CODE:
#   Add this as a PostToolUse hook in .claude/settings.json
#   It runs automatically after Claude edits any file.
# ============================================================

set -e  # Exit on any error

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGED_FILE="${1:-}"  # Claude passes the edited file path as $1

echo "🔍 [Spendly Formatter] Running on: ${CHANGED_FILE:-all files}"

# ---- PYTHON FILES ----
format_python() {
    local file="$1"
    echo "  🐍 Formatting Python: $file"

    # Sort imports (put stdlib first, then third-party like flask, sqlalchemy)
    isort "$file" --profile black --quiet

    # Format with black (matches Spendly's 4-space indent convention)
    black "$file" --line-length 88 --quiet

    # Lint and report (don't fail build, just warn)
    echo "  🔎 Linting: $file"
    flake8 "$file" \
        --max-line-length 88 \
        --extend-ignore E203,W503 \
        --exclude=venv,.venv \
        || echo "  ⚠️  Lint warnings above (fix when possible)"
}

# ---- HTML FILES ----
format_html() {
    local file="$1"
    echo "  🌐 Formatting HTML: $file"
    prettier "$file" \
        --write \
        --parser html \
        --print-width 100 \
        --tab-width 4 \
        --html-whitespace-sensitivity ignore \
        2>/dev/null || echo "  ⚠️  prettier not found — run: npm install -g prettier"
}

# ---- CSS FILES ----
format_css() {
    local file="$1"
    echo "  🎨 Formatting CSS: $file"
    prettier "$file" \
        --write \
        --parser css \
        --print-width 100 \
        --tab-width 4 \
        2>/dev/null || echo "  ⚠️  prettier not found — run: npm install -g prettier"
}

# ---- JS FILES ----
format_js() {
    local file="$1"
    echo "  ⚡ Formatting JS: $file"
    prettier "$file" \
        --write \
        --parser babel \
        --print-width 100 \
        --tab-width 4 \
        --single-quote \
        2>/dev/null || echo "  ⚠️  prettier not found — run: npm install -g prettier"
}

# ---- DISPATCH BASED ON FILE TYPE ----
if [ -n "$CHANGED_FILE" ]; then
    # Single file mode (used by Claude Code hook)
    case "$CHANGED_FILE" in
        *.py)   format_python "$CHANGED_FILE" ;;
        *.html) format_html "$CHANGED_FILE" ;;
        *.css)  format_css "$CHANGED_FILE" ;;
        *.js)   format_js "$CHANGED_FILE" ;;
        *)      echo "  ℹ️  No formatter for: $CHANGED_FILE" ;;
    esac
else
    # Full project scan mode (run manually)
    echo "📁 Scanning full Spendly project..."
    find . -name "*.py" -not -path "./venv/*" -not -path "./.venv/*" | while read f; do
        format_python "$f"
    done
    find ./templates -name "*.html" | while read f; do
        format_html "$f"
    done
    find ./static/css -name "*.css" | while read f; do
        format_css "$f"
    done
    find ./static/js -name "*.js" | while read f; do
        format_js "$f"
    done
fi

echo "✅ [Spendly Formatter] Done!"
