#!/usr/bin/env bash
set -euo pipefail

REPO_PATH="${1:-$PWD}"
BRANCH="${2:-main}"
REPO_NAME="${3:-}"
LOG_PATH="${4:-}"
CHECK_INTERVAL="${5:-5}"
PUSH_INTERVAL="${6:-60}"
MAX_LOG_SIZE_MB="${7:-100}"
DRY_RUN="${8:-false}"
GIT="git"

REPO_NAME="${REPO_NAME:-$(basename "$(dirname "$REPO_PATH")")-$(basename "$REPO_PATH")}"
LOG_PATH="${LOG_PATH:-$REPO_PATH/Technical/Scripts/Logs/daily-push-$REPO_NAME.log}"

LOCK_FILE="$(dirname "$LOG_PATH")/.daily-push-$REPO_NAME.lock"

write_log() {
    local msg="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [$REPO_NAME] $msg"
    mkdir -p "$(dirname "$LOG_PATH")"
    echo "[$ts] [$REPO_NAME] $msg" >> "$LOG_PATH"
}

cleanup() {
    rm -f "$LOCK_FILE"
    exit 0
}

check_lock() {
    mkdir -p "$(dirname "$LOCK_FILE")"
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            echo "[$REPO_NAME] Another instance (PID $pid) already running. Exiting."
            exit 0
        fi
        rm -f "$LOCK_FILE"
    fi
    echo "$$" > "$LOCK_FILE"
    trap cleanup EXIT INT TERM
}

rotate_log() {
    if [[ -f "$LOG_PATH" ]]; then
        local size
        size="$(stat -c%s "$LOG_PATH" 2>/dev/null || echo 0)"
        local max_bytes=$((MAX_LOG_SIZE_MB * 1024 * 1024))
        if [[ "$size" -gt "$max_bytes" ]]; then
            mv "$LOG_PATH" "$LOG_PATH.old" 2>/dev/null || true
            write_log "Log rotated (>${MAX_LOG_SIZE_MB}MB)"
        fi
    fi
}

ensure_branch() {
    local current
    current="$($GIT rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ "$current" != "$BRANCH" ]]; then
        write_log "Branch mismatch: on '$current', expected '$BRANCH'. Switching..."
        $GIT checkout "$BRANCH" 2>/dev/null || write_log "ERROR: Failed to switch to branch '$BRANCH'"
    fi
}

has_changes() {
    $GIT status --porcelain 2>/dev/null | grep -q .
}

commit_changes() {
    ensure_branch
    if ! has_changes; then
        return
    fi
    $GIT add -A 2>/dev/null || { write_log "git add failed"; return; }
    local msg="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
    if $GIT commit -m "$msg" 2>/dev/null; then
        local hash
        hash="$($GIT rev-parse --short HEAD 2>/dev/null || echo "???")"
        write_log "Committed: $hash - $msg"
    fi
}

push_changes() {
    ensure_branch
    write_log "Pushing to origin/$BRANCH ..."
    $GIT fetch --all --prune 2>/dev/null || write_log "WARNING: fetch failed"
    $GIT pull --rebase --autostash origin "$BRANCH" 2>/dev/null || write_log "WARNING: pull --rebase failed"
    if $GIT push origin "$BRANCH" 2>/dev/null; then
        write_log "Push completed successfully"
    else
        write_log "Push failed"
    fi
}

check_lock
rotate_log
ensure_branch

write_log "Starting (check: ${CHECK_INTERVAL}s, push: ${PUSH_INTERVAL}m)"

if [[ "$DRY_RUN" == "true" ]]; then
    write_log "DryRun mode - exiting"
    exit 0
fi

last_push=0
loop_count=0
push_interval_sec=$((PUSH_INTERVAL * 60))

while true; do
    now=$(date +%s)
    loop_count=$((loop_count + 1))

    commit_changes

    if (( now - last_push >= push_interval_sec )); then
        push_changes
        last_push="$now"
    fi

    if (( loop_count % 100 == 0 )); then
        change_count="$(has_changes && $GIT status --porcelain 2>/dev/null | wc -l || echo 0)"
        write_log "Heartbeat: $change_count file(s) changed"
    fi

    rotate_log
    sleep "$CHECK_INTERVAL"
done