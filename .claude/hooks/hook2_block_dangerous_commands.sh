#!/bin/bash
# ============================================================
# HOOK 2: Block Dangerous Shell Commands
# Spendly Project
# ============================================================
# TOOLS USED: Pure bash — no extra installs needed
#
# HOW IT WORKS:
#   Claude Code runs this as a PreToolUse hook BEFORE
#   executing any bash/shell command. If the command matches
#   a dangerous pattern, the hook exits with code 2 which
#   tells Claude Code to BLOCK the command entirely.
#
# HOW TO USE IN CLAUDE CODE:
#   Add as PreToolUse hook in .claude/settings.json
#   The full command string is passed as $1
#
# EXIT CODES:
#   0 = Allow the command
#   2 = Block the command (Claude Code will refuse to run it)
# ============================================================

COMMAND="$1"

# Lowercase for easier matching
CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

echo "🛡️  [Spendly Guard] Checking command safety..."
echo "   CMD: $COMMAND"

# ============================================================
# BLOCK LIST — Dangerous patterns for a Flask/SQLite project
# ============================================================

block_command() {
    local reason="$1"
    echo ""
    echo "🚫 =============================================="
    echo "🚫  BLOCKED BY SPENDLY SAFETY HOOK"
    echo "🚫  Reason: $reason"
    echo "🚫  Command: $COMMAND"
    echo "🚫 =============================================="
    echo ""
    exit 2  # Exit code 2 = Claude Code blocks this command
}

# 1. Database destruction — spendly.db is critical
if echo "$CMD_LOWER" | grep -qE "(rm|del|remove|unlink).*(spendly\.db|\.db)"; then
    block_command "Attempted to DELETE the SQLite database file (spendly.db)"
fi

if echo "$CMD_LOWER" | grep -qE "db\.(drop_all|execute.*drop)"; then
    block_command "Attempted to DROP ALL database tables via SQLAlchemy"
fi

# 2. Mass file deletion
if echo "$CMD_LOWER" | grep -qE "rm\s+-rf\s+(/|\./?$|~|/home|/etc)"; then
    block_command "Recursive delete of root/home directory detected"
fi

if echo "$CMD_LOWER" | grep -qE "rm\s+-rf\s+\*"; then
    block_command "Wildcard recursive delete — too dangerous"
fi

# 3. Credential / secret exposure
if echo "$CMD_LOWER" | grep -qE "(cat|echo|print|curl|wget).*(secret|password|\.env|api_key|token)"; then
    block_command "Attempted to read or transmit secrets/credentials"
fi

if echo "$CMD_LOWER" | grep -qE "git\s+(push|commit).*(secret|password|\.env)"; then
    block_command "Attempted to commit secrets to git"
fi

# 4. Network exfiltration — sending data out
if echo "$CMD_LOWER" | grep -qE "(curl|wget|nc|ncat).*(spendly\.db|password|secret)"; then
    block_command "Attempted to send sensitive Spendly data over network"
fi

# 5. Permission escalation
if echo "$CMD_LOWER" | grep -qE "^sudo\s+(rm|chmod 777|chown root|passwd)"; then
    block_command "Dangerous sudo command detected"
fi

if echo "$CMD_LOWER" | grep -qE "chmod\s+777\s+/"; then
    block_command "chmod 777 on root path — security violation"
fi

# 6. Process/system destruction
if echo "$CMD_LOWER" | grep -qE ":(){ :|:& };:|fork\s+bomb"; then
    block_command "Fork bomb detected"
fi

if echo "$CMD_LOWER" | grep -qE "dd\s+if=/dev/(zero|random|urandom)\s+of=/dev/(sda|hda|nvme)"; then
    block_command "Disk wipe command detected"
fi

# 7. Git history destruction
if echo "$CMD_LOWER" | grep -qE "git\s+(push\s+--force|reset\s+--hard\s+HEAD~[5-9]|clean\s+-fdx)"; then
    block_command "Destructive git operation — force push or large history wipe"
fi

# 8. Python code execution from untrusted sources
if echo "$CMD_LOWER" | grep -qE "python\s+-c\s+.*(__import__|exec|eval|os\.system)"; then
    block_command "Potentially unsafe Python eval/exec via command line"
fi

# ============================================================
# ALLOW — Command passed all checks
# ============================================================
echo "✅ [Spendly Guard] Command is safe — allowing."
exit 0
