#!/bin/bash
# ============================================================
# HOOK 3: Protect Sensitive Files
# Spendly Project
# ============================================================
# TOOLS USED: Pure bash — no extra installs needed
#
# WHAT IT PROTECTS:
#   - .env files (API keys, SECRET_KEY, DB passwords)
#   - spendly.db (live user expense data)
#   - Any file with "secret", "key", "password" in name
#   - Git credentials / SSH keys
#   - Flask secret key config
#
# HOW TO USE IN CLAUDE CODE:
#   Add as PreToolUse hook for tools: Read, Write, Edit
#   The file path being accessed is passed as $1
#
# EXIT CODES:
#   0 = Allow access
#   2 = Block access (Claude Code will refuse the file operation)
# ============================================================

FILE_PATH="$1"
OPERATION="${2:-read}"  # read, write, edit

echo "🔒 [Spendly File Guard] Checking: $FILE_PATH (op: $OPERATION)"

# ============================================================
# PROTECTED FILE PATTERNS — Spendly specific
# ============================================================

block_file() {
    local reason="$1"
    echo ""
    echo "🚫 =============================================="
    echo "🚫  FILE ACCESS BLOCKED — SPENDLY SECURITY HOOK"
    echo "🚫  File    : $FILE_PATH"
    echo "🚫  Operation: $OPERATION"  
    echo "🚫  Reason  : $reason"
    echo "🚫 =============================================="
    echo ""
    exit 2
}

warn_file() {
    local reason="$1"
    echo "⚠️  [Spendly File Guard] WARNING: $reason"
    echo "   File: $FILE_PATH — Allowing but flagging for review."
}

# Normalize path for matching
BASENAME=$(basename "$FILE_PATH")
BASENAME_LOWER=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]')

# 1. Environment / secrets files — ALWAYS BLOCK WRITE, warn on read
if echo "$BASENAME_LOWER" | grep -qE "^\.env(\..*)?$"; then
    if [ "$OPERATION" = "write" ] || [ "$OPERATION" = "edit" ]; then
        block_file ".env file write blocked — manage secrets manually"
    else
        warn_file ".env file being read — contains Flask SECRET_KEY and credentials"
    fi
fi

# 2. Spendly database — BLOCK ALL DIRECT WRITES (use SQLAlchemy only)
if echo "$BASENAME_LOWER" | grep -qE "spendly\.db|\.db$"; then
    if [ "$OPERATION" = "write" ] || [ "$OPERATION" = "edit" ]; then
        block_file "Direct write to SQLite database blocked — use SQLAlchemy/Flask routes instead"
    else
        warn_file "Reading SQLite DB directly — contains real user expense data"
    fi
fi

# 3. Files with sensitive names
if echo "$BASENAME_LOWER" | grep -qE "(secret|credential|password|api_key|private_key|token)"; then
    block_file "File name contains sensitive keyword: $BASENAME"
fi

# 4. SSH / GPG keys
if echo "$FILE_PATH" | grep -qE "(\.ssh|\.gnupg|id_rsa|id_ed25519|\.pem|\.p12|\.pfx)"; then
    block_file "SSH/GPG key file — never expose these to AI tools"
fi

# 5. Flask config with secret key (warn on read, block on write)
if echo "$BASENAME_LOWER" | grep -qE "^config\.py$|^settings\.py$"; then
    if [ "$OPERATION" = "write" ] || [ "$OPERATION" = "edit" ]; then
        warn_file "Editing Flask config — ensure SECRET_KEY is not hardcoded"
    fi
fi

# 6. Git credentials
if echo "$FILE_PATH" | grep -qE "(\.git/config|\.netrc|\.gitcredentials)"; then
    block_file "Git credentials file — blocked from AI access"
fi

# 7. Backup files that may contain sensitive data
if echo "$BASENAME_LOWER" | grep -qE "\.(bak|backup|dump|sql)$"; then
    warn_file "Backup/dump file — may contain user data from Spendly database"
fi

# 8. Spendly's user upload folder (if added in future)
if echo "$FILE_PATH" | grep -qE "/uploads/|/user_data/"; then
    block_file "User upload directory — contains private user files"
fi

echo "✅ [Spendly File Guard] Access permitted: $FILE_PATH"
exit 0
