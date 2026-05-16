#!/bin/bash
# ============================================================
# HOOK 4: Task Completion Notification — WINDOWS VERSION
# Spendly Project
# ============================================================
# TOOLS USED (all FREE, no install needed on Windows):
#   - PowerShell      → Windows Toast Notifications (built-in)
#   - Python3         → writes status JSON file
#   - Browser HTML page → polls every 3 sec, plays beep sound
#
# 3 WAYS TO GET NOTIFIED (pick any or all):
#   METHOD 1 → Windows Toast Notification (popup in corner)
#   METHOD 2 → Browser Tab (open spendly_notifier.html in a tab)
#   METHOD 3 → Sound beep via PowerShell
#
# HOW TO USE IN CLAUDE CODE:
#   Place this file at: .claude/hooks/hook4_task_notification.sh
#   It is called automatically via settings.json PostToolUse hook
# ============================================================

TASK_SUMMARY="${1:-Task completed}"
TASK_TYPE="${2:-general}"
TIMESTAMP=$(date "+%H:%M:%S")
DATE_TODAY=$(date "+%Y-%m-%d")

echo "🔔 [Spendly Notifier] Task done at $TIMESTAMP: $TASK_SUMMARY"

# ============================================================
# METHOD 1: Windows Toast Notification via PowerShell
# Shows a popup in the bottom-right corner of your screen
# Works on Windows 10 and Windows 11 — NO install needed
# ============================================================

send_windows_toast() {
    local title="$1"
    local message="$2"

    # Check if we're on Windows (Git Bash / WSL)
    if command -v powershell.exe &>/dev/null || command -v powershell &>/dev/null; then
        PWSH="powershell.exe"
        command -v powershell.exe &>/dev/null || PWSH="powershell"

        echo "  📬 Sending Windows Toast notification..."

        "$PWSH" -NoProfile -NonInteractive -Command "
\$ErrorActionPreference = 'SilentlyContinue'

# Method A: Windows 10/11 Toast Notification (modern style)
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null

    \$template = @'
<toast duration='short'>
  <visual>
    <binding template='ToastGeneric'>
      <text>$title</text>
      <text>$message</text>
      <text hint-style='captionSubtle'>Spendly Project</text>
    </binding>
  </visual>
  <audio src='ms-winsoundevent:Notification.Default'/>
</toast>
'@

    \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    \$xml.LoadXml(\$template)
    \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
    \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Spendly - Claude Code')
    \$notifier.Show(\$toast)
    Write-Host '  Toast sent (Windows 10/11 style)'
    exit 0
} catch {}

# Method B: Fallback — BalloonTip via System Tray (older Windows)
try {
    Add-Type -AssemblyName System.Windows.Forms
    \$notify = New-Object System.Windows.Forms.NotifyIcon
    \$notify.Icon = [System.Drawing.SystemIcons]::Information
    \$notify.Visible = \$true
    \$notify.BalloonTipIcon = 'Info'
    \$notify.BalloonTipTitle = '$title'
    \$notify.BalloonTipText = '$message'
    \$notify.ShowBalloonTip(8000)
    Start-Sleep -Milliseconds 500
    \$notify.Dispose()
    Write-Host '  Balloon tip sent (System Tray style)'
    exit 0
} catch {}

Write-Host '  Notification failed — using browser method instead'
" 2>/dev/null && echo "  ✅ Windows notification sent" || echo "  ℹ️  Toast failed — browser tab will still work"

    else
        echo "  ℹ️  PowerShell not found — skipping toast notification"
    fi
}

# ============================================================
# METHOD 2: Play a sound beep via PowerShell
# Simple audio alert so you hear it without looking at screen
# ============================================================

send_windows_beep() {
    if command -v powershell.exe &>/dev/null || command -v powershell &>/dev/null; then
        PWSH="powershell.exe"
        command -v powershell.exe &>/dev/null || PWSH="powershell"

        "$PWSH" -NoProfile -NonInteractive -Command "
[Console]::Beep(800, 200)
Start-Sleep -Milliseconds 100
[Console]::Beep(1000, 300)
" 2>/dev/null && echo "  🔊 Beep played" || true
    fi
}

# ============================================================
# METHOD 3: Write status JSON (read by browser tab)
# Open spendly_notifier.html in a browser tab — it polls this
# ============================================================

STATUS_FILE=".spendly_claude_status.json"
HISTORY_FILE=".spendly_task_history.json"

# Write current status
cat > "$STATUS_FILE" << EOF
{
  "project": "spendly",
  "status": "completed",
  "task": "$TASK_SUMMARY",
  "type": "$TASK_TYPE",
  "timestamp": "$TIMESTAMP",
  "date": "$DATE_TODAY",
  "unix_time": $(date +%s 2>/dev/null || python3 -c "import time; print(int(time.time()))")
}
EOF
echo "  📄 Status file updated: $STATUS_FILE"

# Append to history (keep last 20)
python3 - << PYEOF
import json, time, os

history_file = "$HISTORY_FILE"
new_task = {
    "task": "$TASK_SUMMARY",
    "type": "$TASK_TYPE",
    "timestamp": "$TIMESTAMP",
    "date": "$DATE_TODAY",
    "unix_time": int(time.time())
}

try:
    with open(history_file) as f:
        history = json.load(f)
except:
    history = []

history.insert(0, new_task)
history = history[:20]

with open(history_file, 'w') as f:
    json.dump(history, f, indent=2)

print(f"  📝 History updated ({len(history)} tasks logged)")
PYEOF

# ============================================================
# METHOD 4: Generate the browser polling HTML page
# Open this file in Chrome/Edge/Firefox in a separate tab
# It beeps and flashes when Claude finishes!
# ============================================================

NOTIFIER_HTML="spendly_notifier.html"

cat > "$NOTIFIER_HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Spendly — Claude Status</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Segoe UI', 'DM Sans', sans-serif;
    background: #F8FAFC;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    transition: background 0.5s;
  }
  body.done { background: #DCFCE7; }
  body.waiting { background: #F8FAFC; }
  .card {
    background: white;
    border-radius: 20px;
    padding: 48px 40px;
    text-align: center;
    box-shadow: 0 10px 40px rgba(0,0,0,0.08);
    max-width: 520px;
    width: 92%;
    border: 2px solid #E2E8F0;
    transition: border-color 0.5s;
  }
  .card.done { border-color: #22C55E; }
  .logo { font-size: 2rem; font-weight: 700; color: #0F172A; margin-bottom: 4px; }
  .subtitle { color: #64748B; font-size: 0.9rem; margin-bottom: 32px; }
  .status-icon { font-size: 4rem; margin: 8px 0; transition: all 0.3s; }
  .status-text {
    font-size: 1.2rem;
    font-weight: 600;
    color: #0F172A;
    margin: 12px 0 8px;
    min-height: 1.8rem;
  }
  .task-time { color: #64748B; font-size: 0.85rem; margin-bottom: 24px; }
  .badge {
    display: inline-block;
    background: #DCFCE7;
    color: #16A34A;
    padding: 4px 14px;
    border-radius: 99px;
    font-size: 0.8rem;
    font-weight: 600;
    margin-bottom: 28px;
  }
  .badge.waiting { background: #FEF9C3; color: #CA8A04; }
  .history {
    text-align: left;
    border-top: 1px solid #E2E8F0;
    padding-top: 20px;
    margin-top: 8px;
  }
  .history h3 { font-size: 0.85rem; color: #94A3B8; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 0.05em; }
  .hist-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 0;
    border-bottom: 1px solid #F1F5F9;
    font-size: 0.85rem;
    color: #475569;
  }
  .hist-item:last-child { border-bottom: none; }
  .hist-time { color: #94A3B8; font-size: 0.78rem; flex-shrink: 0; margin-left: 8px; }
  .poll-dot {
    display: inline-block;
    width: 8px; height: 8px;
    background: #22C55E;
    border-radius: 50%;
    animation: pulse 2s infinite;
    margin-right: 6px;
  }
  .poll-info { color: #94A3B8; font-size: 0.78rem; margin-top: 16px; }
  @keyframes pulse {
    0%, 100% { opacity: 1; transform: scale(1); }
    50% { opacity: 0.4; transform: scale(0.8); }
  }
  @keyframes flash {
    0%, 100% { background: white; }
    50% { background: #DCFCE7; }
  }
  .flash { animation: flash 0.6s ease 3; }
</style>
</head>
<body class="waiting">
<div class="card" id="card">
  <div class="logo">🏦 Spendly</div>
  <div class="subtitle">Claude Code — Live Status Monitor</div>
  <div class="status-icon" id="icon">⏳</div>
  <div class="status-text" id="statusText">Waiting for Claude...</div>
  <div class="task-time" id="taskTime">No tasks yet</div>
  <div class="badge waiting" id="badge">MONITORING</div>
  <div class="history" id="historySection" style="display:none">
    <h3>Recent Tasks</h3>
    <div id="historyList"></div>
  </div>
  <div class="poll-info">
    <span class="poll-dot"></span>
    Auto-refreshing every 3 seconds
  </div>
</div>

<script>
// Audio beep using Web Audio API (no file needed, works in all browsers)
function playBeep() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.setValueAtTime(800, ctx.currentTime);
    osc.frequency.setValueAtTime(1000, ctx.currentTime + 0.15);
    gain.gain.setValueAtTime(0.4, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.5);
  } catch(e) {}
}

let lastTaskTime = null;

async function poll() {
  try {
    const res = await fetch('.spendly_claude_status.json?t=' + Date.now());
    if (!res.ok) return;
    const data = await res.json();

    const isNew = data.unix_time !== lastTaskTime && lastTaskTime !== null;
    lastTaskTime = data.unix_time;

    document.getElementById('icon').textContent = '✅';
    document.getElementById('statusText').textContent = data.task || 'Task completed';
    document.getElementById('taskTime').textContent = 'Completed at ' + data.timestamp + ' on ' + data.date;
    document.getElementById('badge').textContent = 'DONE';
    document.getElementById('badge').className = 'badge';
    document.body.className = 'done';
    document.getElementById('card').className = 'card done';
    document.title = '✅ Done — Spendly';

    if (isNew) {
      playBeep();
      document.getElementById('card').classList.add('flash');
      setTimeout(() => document.getElementById('card').classList.remove('flash'), 2000);

      // Browser notification
      if (Notification.permission === 'granted') {
        new Notification('✅ Spendly — Claude Done', {
          body: data.task,
          icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">🏦</text></svg>'
        });
      }
    }

    // Load history
    try {
      const hRes = await fetch('.spendly_task_history.json?t=' + Date.now());
      const history = await hRes.json();
      if (history.length > 0) {
        document.getElementById('historySection').style.display = 'block';
        document.getElementById('historyList').innerHTML = history.slice(0, 5).map(t =>
          `<div class="hist-item"><span>⚡ ${t.task}</span><span class="hist-time">${t.timestamp}</span></div>`
        ).join('');
      }
    } catch(e) {}

  } catch(e) {
    document.getElementById('icon').textContent = '⏳';
    document.getElementById('statusText').textContent = 'Waiting for Claude...';
    document.getElementById('badge').textContent = 'MONITORING';
    document.getElementById('badge').className = 'badge waiting';
    document.body.className = 'waiting';
    document.getElementById('card').className = 'card';
    document.title = '⏳ Monitoring — Spendly';
  }
}

// Request browser notification permission
if (Notification.permission === 'default') {
  Notification.requestPermission();
}

poll();
setInterval(poll, 3000);
</script>
</body>
</html>
HTMLEOF

echo "  🌐 Browser notifier page created/updated: $NOTIFIER_HTML"

# ============================================================
# FIRE ALL METHODS
# ============================================================
send_windows_toast "✅ Spendly — Claude Done" "[$TIMESTAMP] $TASK_SUMMARY"
send_windows_beep

echo ""
echo "✅ [Spendly Notifier] All notifications sent!"
echo "   💡 Open spendly_notifier.html in a browser tab for visual + sound alerts"
echo "   💡 Allow browser notifications when prompted for popup alerts too"
