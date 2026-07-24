#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing daily-push system..."

chmod +x "$SCRIPT_DIR/run-daily-push"
chmod +x "$SCRIPT_DIR/Git/daily-push.sh"
chmod +x "$SCRIPT_DIR/Git/monitor-daily-push.sh"
chmod +x "$SCRIPT_DIR/Git/test-daily-push.sh"

echo "Done."
echo ""
echo "Usage:"
echo "  $SCRIPT_DIR/run-daily-push --help"
echo ""
echo "Quick start:"
echo "  $SCRIPT_DIR/run-daily-push --repo /path/to/repo"
echo "  $SCRIPT_DIR/run-daily-push --monitor"
echo "  $SCRIPT_DIR/run-daily-push --dry-run"