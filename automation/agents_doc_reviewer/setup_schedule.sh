#!/usr/bin/env bash
set -euo pipefail

# Configurable
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REVIEW_SCRIPT="$SCRIPT_DIR/agents_doc_review.sh"
LABEL="com.vibe-utils.agents-doc-review"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/.local/log/agents-doc-review"
DEFAULT_INTERVAL_DAYS=21
DEFAULT_HOUR=10
DEFAULT_MINUTE=0

ACTION=""
INTERVAL_DAYS="$DEFAULT_INTERVAL_DAYS"
HOUR="$DEFAULT_HOUR"
MINUTE="$DEFAULT_MINUTE"
USE_CLAUDE="true"

print_help() {
  cat <<'EOF'
Usage:
  scripts/setup_schedule.sh <action> [options]

Actions:
  install       Create and load launchd plist for periodic execution
  uninstall     Unload and remove launchd plist
  status        Show current schedule status
  run-now       Trigger an immediate run via launchd

Options (for install):
  --interval <days>   Review interval in days (default: 21)
  --hour <0-23>       Hour to run (default: 10)
  --minute <0-59>     Minute to run (default: 0)
  --no-claude         Disable Claude CLI review (enabled by default)

Examples:
  setup_schedule.sh install --interval 14
  setup_schedule.sh status
  setup_schedule.sh uninstall
EOF
}

if [[ $# -lt 1 ]]; then
  print_help
  exit 1
fi

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  print_help
  exit 0
fi

ACTION="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      INTERVAL_DAYS="${2:-$DEFAULT_INTERVAL_DAYS}"
      shift 2
      ;;
    --hour)
      HOUR="${2:-$DEFAULT_HOUR}"
      shift 2
      ;;
    --minute)
      MINUTE="${2:-$DEFAULT_MINUTE}"
      shift 2
      ;;
    --claude)
      USE_CLAUDE="true"
      shift
      ;;  # kept for backward compat
    --no-claude)
      USE_CLAUDE="false"
      shift
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help
      exit 1
      ;;
  esac
done

do_install() {
  if [[ ! -x "$REVIEW_SCRIPT" ]]; then
    echo "Review script not found or not executable: $REVIEW_SCRIPT" >&2
    exit 1
  fi

  mkdir -p "$LOG_DIR"
  mkdir -p "$(dirname "$PLIST_PATH")"

  # Build the script arguments
  local args=("--force")
  if [[ "$USE_CLAUDE" == "false" ]]; then
    args+=("--no-claude")
  fi

  # Unload existing if present
  if launchctl list "$LABEL" >/dev/null 2>&1; then
    echo "Unloading existing schedule..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
  fi

  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$REVIEW_SCRIPT</string>
$(for arg in "${args[@]}"; do echo "    <string>$arg</string>"; done)
  </array>

  <key>WorkingDirectory</key>
  <string>$REPO_DIR</string>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$HOUR</integer>
    <key>Minute</key>
    <integer>$MINUTE</integer>
  </dict>

  <key>StandardOutPath</key>
  <string>$LOG_DIR/stdout.log</string>

  <key>StandardErrorPath</key>
  <string>$LOG_DIR/stderr.log</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    <key>HOME</key>
    <string>$HOME</string>
  </dict>
</dict>
</plist>
PLIST

  launchctl load "$PLIST_PATH"

  echo "Installed: $PLIST_PATH"
  echo
  echo "Schedule:"
  echo "  - Runs daily at $(printf '%02d:%02d' "$HOUR" "$MINUTE")"
  echo "  - Interval check: ${INTERVAL_DAYS} days (handled by the script's state files)"
  echo "  - Claude review: $USE_CLAUDE"
  echo "  - Logs: $LOG_DIR/"
  echo
  echo "Note: launchd triggers daily, but the script skips projects not yet due."
  echo "Use 'scripts/setup_schedule.sh run-now' to trigger immediately."
}

do_uninstall() {
  if [[ -f "$PLIST_PATH" ]]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "Uninstalled: $PLIST_PATH"
  else
    echo "No schedule found at: $PLIST_PATH"
  fi
}

do_status() {
  echo "=== Schedule Status ==="
  echo
  if [[ -f "$PLIST_PATH" ]]; then
    echo "Plist: $PLIST_PATH"
    echo
    if launchctl list "$LABEL" >/dev/null 2>&1; then
      echo "Status: LOADED"
      launchctl list "$LABEL" 2>/dev/null || true
    else
      echo "Status: NOT LOADED (plist exists but not loaded)"
    fi
  else
    echo "Status: NOT INSTALLED"
    echo "Run: scripts/setup_schedule.sh install"
    return
  fi

  echo
  echo "=== Recent Logs ==="
  if [[ -f "$LOG_DIR/stdout.log" ]]; then
    echo "--- stdout (last 20 lines) ---"
    tail -20 "$LOG_DIR/stdout.log"
  fi
  if [[ -f "$LOG_DIR/stderr.log" ]]; then
    echo "--- stderr (last 10 lines) ---"
    tail -10 "$LOG_DIR/stderr.log"
  fi

  echo
  echo "=== State Files ==="
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents-doc-review"
  if [[ -d "$state_dir" ]]; then
    for f in "$state_dir"/*.last_review_epoch; do
      if [[ -f "$f" ]]; then
        local slug
        slug="$(basename "$f" .last_review_epoch)"
        local epoch
        epoch="$(cat "$f")"
        echo "  $slug: last reviewed $(date -r "$epoch" '+%Y-%m-%d %H:%M' 2>/dev/null || echo 'unknown')"
      fi
    done
  else
    echo "  (no state directory yet)"
  fi
}

do_run_now() {
  if ! launchctl list "$LABEL" >/dev/null 2>&1; then
    echo "Schedule not loaded. Running script directly..." >&2
    cd "$REPO_DIR"
    local args=("--force")
    if [[ "$USE_CLAUDE" == "true" ]]; then
      args+=("--claude")
    fi
    exec "$REVIEW_SCRIPT" "${args[@]}"
  else
    echo "Triggering via launchctl kickstart..."
    launchctl kickstart "gui/$(id -u)/$LABEL"
    echo "Triggered. Check logs: $LOG_DIR/"
  fi
}

case "$ACTION" in
  install)
    do_install
    ;;
  uninstall)
    do_uninstall
    ;;
  status)
    do_status
    ;;
  run-now)
    do_run_now
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    print_help
    exit 1
    ;;
esac
