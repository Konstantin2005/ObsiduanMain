#!/usr/bin/env bash
set -euo pipefail

BASE_PATH="${1:-$HOME/obsidian}"
LOGS_DIR="${2:-$BASE_PATH/Main/Technical/Scripts/Logs}"
MONITOR_LOG="${3:-$LOGS_DIR/monitor.log}"
CHECK_INTERVAL="${4:-15}"
DURATION_MINUTES="${5:-1440}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

write_log() {
    local msg="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [MONITOR] $msg"
    mkdir -p "$(dirname "$MONITOR_LOG")"
    echo "[$ts] [MONITOR] $msg" >> "$MONITOR_LOG"
}

discover_repos() {
    local root="$1"
    write_log "Scanning for git repositories under: $root"
    local repos=()

    while IFS= read -r -d '' gitdir; do
        local repo_path
        repo_path="$(dirname "$gitdir")"

        local branch
        branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"

        local remote_url
        remote_url="$(git -C "$repo_path" remote get-url origin 2>/dev/null || echo "(no remote)")"

        local rel_path="${repo_path#$root}"
        rel_path="${rel_path#/}"
        local repo_name
        if [[ -z "$rel_path" ]]; then
            repo_name="$(basename "$root")"
        else
            repo_name="$(basename "$root")-${rel_path//\//-}"
        fi

        local has_changes
        has_changes="$(git -C "$repo_path" status --porcelain 2>/dev/null | wc -l)"

        repos+=("$repo_path|$repo_name|$branch|$remote_url|$has_changes")
        write_log "  Found repo: $repo_name | $repo_path | branch: $branch | changes: $has_changes"
    done < <(find "$root" -maxdepth 5 -type d -name '.git' -not -path '*/.git/*' -print0 2>/dev/null)

    if [[ ${#repos[@]} -eq 0 ]]; then
        write_log "WARNING: No git repositories found under $root"
    fi

    printf '%s\n' "${repos[@]}"
}

declare -A INSTANCES
declare -A INSTANCE_COMMITS
declare -A INSTANCE_PUSHES

start_instance() {
    local repo_path="$1" repo_name="$2" branch="$3"
    local log_file="$LOGS_DIR/daily-push-$repo_name.log"
    local push_script="$SCRIPT_DIR/daily-push.sh"

    if [[ ! -f "$push_script" ]]; then
        write_log "ERROR: daily-push.sh not found at $push_script"
        return
    fi

    mkdir -p "$LOGS_DIR"

    nohup bash "$push_script" \
        "$repo_path" \
        "$branch" \
        "$repo_name" \
        "$log_file" \
        5 \
        60 \
        100 \
        false \
        > /dev/null 2>&1 &

    local pid=$!
    INSTANCES["$repo_name"]="$pid"
    INSTANCE_COMMITS["$repo_name"]=0
    INSTANCE_PUSHES["$repo_name"]=0
    write_log "Started daily-push for '$repo_name' (PID: $pid)"
}

stop_instance() {
    local repo_name="$1"
    local pid="${INSTANCES[$repo_name]:-}"
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        write_log "Stopped daily-push for '$repo_name'"
        unset INSTANCES["$repo_name"]
    fi
}

get_live_status() {
    local repo_path="$1" branch="$2"
    local changes ahead last_commit last_time

    changes="$(git -C "$repo_path" status --porcelain 2>/dev/null | wc -l)"
    ahead="$(git -C "$repo_path" rev-list --count "origin/$branch..$branch" 2>/dev/null || echo 0)"
    last_commit="$(git -C "$repo_path" log --oneline -1 2>/dev/null || echo "")"
    last_time="$(git -C "$repo_path" log -1 --format=%ci 2>/dev/null || echo "")"

    echo "$changes|$ahead|$last_commit|$last_time"
}

update_from_log() {
    local repo_name="$1"
    local log_file="$LOGS_DIR/daily-push-$repo_name.log"

    if [[ ! -f "$log_file" ]]; then
        return
    fi

    local commits_before="${INSTANCE_COMMITS[$repo_name]:-0}"
    local pushes_before="${INSTANCE_PUSHES[$repo_name]:-0}"

    local commits_now
    commits_now="$(grep -c 'Committed:' "$log_file" 2>/dev/null || echo 0)"
    local pushes_now
    pushes_now="$(grep -c 'Push completed' "$log_file" 2>/dev/null || echo 0)"

    if [[ "$commits_now" -gt "$commits_before" ]]; then
        INSTANCE_COMMITS["$repo_name"]="$commits_now"
        write_log "COMMIT [$repo_name] #$commits_now"
    fi
    if [[ "$pushes_now" -gt "$pushes_before" ]]; then
        INSTANCE_PUSHES["$repo_name"]="$pushes_now"
        write_log "PUSH  [$repo_name] #$pushes_now"
    fi
}

write_log "========================================"
write_log "OBSIDIAN GIT MONITOR STARTED"
write_log "Base path: $BASE_PATH"
write_log "Check interval: ${CHECK_INTERVAL}s"
write_log "Duration: ${DURATION_MINUTES}m"
write_log "========================================"

mapfile -t repos < <(discover_repos "$BASE_PATH")

if [[ ${#repos[@]} -eq 0 ]]; then
    write_log "FATAL: No repositories to monitor. Exiting."
    exit 1
fi

write_log "Found ${#repos[@]} repositories to monitor"
write_log ""

declare -A REPO_INFO
for repo in "${repos[@]}"; do
    IFS='|' read -r rpath rname rbranch rurl rchanges <<< "$repo"
    REPO_INFO["$rname,path"]="$rpath"
    REPO_INFO["$rname,branch"]="$rbranch"
    REPO_INFO["$rname,url"]="$rurl"
    start_instance "$rpath" "$rname" "$rbranch"
done

end_time=$(( $(date +%s) + DURATION_MINUTES * 60 ))

while [[ $(date +%s) -lt "$end_time" ]]; do
    status_parts=()
    total_commits=0
    total_pushes=0

    for repo in "${repos[@]}"; do
        IFS='|' read -r rpath rname rbranch rurl rchanges <<< "$repo"

        local pid="${INSTANCES[$rname]:-}"
        local running=false
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            running=true
        fi

        if ! $running; then
            write_log "RESTART [$rname] Process died, restarting..."
            unset INSTANCES["$rname"]
            start_instance "$rpath" "$rname" "$rbranch"
        fi

        update_from_log "$rname"

        local live
        live="$(get_live_status "$rpath" "$rbranch")"
        IFS='|' read -r changes ahead last_commit last_time <<< "$live"

        status_parts+=("$rname($changes ch, $ahead ahead)")

        total_commits=$((total_commits + ${INSTANCE_COMMITS[$rname]:-0}))
        total_pushes=$((total_pushes + ${INSTANCE_PUSHES[$rname]:-0}))
    done

    local iteration
    iteration=$(( ($end_time - $(date +%s)) / CHECK_INTERVAL ))
    if (( iteration % 8 == 0 )); then
        write_log "STATUS: [${status_parts[*]}]"
        write_log "TOTALS: Commits=$total_commits | Pushes=$total_pushes"
    fi

    sleep "$CHECK_INTERVAL"
done

write_log ""
write_log "========================================"
write_log "MONITOR SUMMARY"
write_log "========================================"

all_ok=true
for repo in "${repos[@]}"; do
    IFS='|' read -r rpath rname rbranch rurl rchanges <<< "$repo"
    local pid="${INSTANCES[$rname]:-}"
    local running=false
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && running=true

    write_log "Repo:    $rname"
    write_log "  Path:     $rpath"
    write_log "  Branch:   $rbranch"
    write_log "  Running:  $( $running && echo 'YES' || echo 'NO' )"
    write_log "  Commits:  ${INSTANCE_COMMITS[$rname]:-0}"
    write_log "  Pushes:   ${INSTANCE_PUSHES[$rname]:-0}"

    if ! $running; then
        all_ok=false
    fi
done

write_log ""
write_log "Overall status: $( $all_ok && echo 'ALL OK' || echo 'ISSUES DETECTED' )"
write_log "Monitor finished at: $(date '+%Y-%m-%d %H:%M:%S')"
write_log "========================================"

$all_ok || exit 1