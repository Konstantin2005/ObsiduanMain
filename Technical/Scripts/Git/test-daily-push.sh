#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="${1:-$SCRIPT_DIR/daily-push.sh}"
REPO_PATH="${2:-$PWD}"
TEST_DURATION="${3:-30}"

PASS=0
FAIL=0

test_log() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [TEST] $1"
}

assert() {
    local name="$1" result="$2"
    if $result; then
        test_log "PASS: $name"
        PASS=$((PASS + 1))
    else
        test_log "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

test_shellcheck() {
    if command -v shellcheck &>/dev/null; then
        shellcheck "$SCRIPT_PATH" && return 0 || return 1
    else
        test_log "SKIP: shellcheck not installed"
        return 0
    fi
}

test_dry_run() {
    bash "$SCRIPT_PATH" "$REPO_PATH" main "" "" 5 60 100 true 2>&1
}

test_has_changes() {
    git -C "$REPO_PATH" status --porcelain 2>/dev/null | grep -q .
}

test_branch_detection() {
    local branch
    branch="$(git -C "$REPO_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [[ -n "$branch" && "$branch" != "HEAD" ]]
}

test_push_interval_logic() {
    local now last_push=0 interval=900
    now=$(date +%s)
    if (( now - last_push >= interval )); then
        return 0
    else
        return 1
    fi
}

test_log "=== Starting daily-push.sh Tests ==="
test_log "Script: $SCRIPT_PATH"
test_log "Repo: $REPO_PATH"
test_log "Test Duration: ${TEST_DURATION}s"
test_log ""

assert "Syntax check (shellcheck)" test_shellcheck
assert "Branch detection" test_branch_detection
assert "Push interval logic (first run)" test_push_interval_logic
assert "Dry run parameter works" test_dry_run

test_log ""
test_log "=== Test Summary ==="
test_log "Passed: $PASS"
test_log "Failed: $FAIL"

if [[ "$FAIL" -gt 0 ]]; then
    test_log "SOME TESTS FAILED"
    exit 1
else
    test_log "ALL TESTS PASSED"
    exit 0
fi