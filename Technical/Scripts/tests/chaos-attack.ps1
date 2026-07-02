# chaos-attack.ps1 — Simulates 7 real failure scenarios to test self-healing
# ATTACK MODE: Intentionally breaks the system in realistic ways

$script:ATTACKS = @{}
$script:REPAIRED = @{}

Write-Host "╔══════════════════════════════════════════════╗"
Write-Host "║     ⚔️  CHAOS ATTACK — 7 REAL FAILURES       ║"
Write-Host "║     Testing self-healing & fault tolerance   ║"
Write-Host "╚══════════════════════════════════════════════╝"

# Hide window
try {
    $t = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindow -Namespace Win32 -PassThru
    $t::ShowWindow((Get-Process -Id $pid).MainWindowHandle, 0) | Out-Null
} catch {}

Write-Host ""

# ─────────────────────────────────────────────────────
# ATTACK 1: STALE LOCK FILE
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 1/7: Stale lock file" -ForegroundColor Red
$lockFiles = @(
    "C:\obsidian\Main\.git\index.lock",
    "C:\obsidian\.git\index.lock"
)
foreach ($lf in $lockFiles) {
    # Create a lock file with an old timestamp (2 hours ago)
    $stamp = (Get-Date).AddHours(-2)
    Set-Content -Path $lf -Value "chaos attack: simulated stale lock" -Force
    (Get-Item $lf).CreationTime = $stamp
    (Get-Item $lf).LastWriteTime = $stamp
    Write-Host "  [CREATED] $lf (aged 2 hours)" -ForegroundColor DarkRed
}
$script:ATTACKS["Lock"] = "2 stale lock files created"

# ─────────────────────────────────────────────────────
# ATTACK 2: STUCK REBASE
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 2/7: Stuck rebase" -ForegroundColor Red
$rebaseDirs = @(
    "C:\obsidian\Main\.git\rebase-merge",
    "C:\obsidian\.git\rebase-merge",
    "C:\obsidian\Main\.git\rebase-apply",
    "C:\obsidian\.git\rebase-apply"
)
foreach ($rd in $rebaseDirs) {
    New-Item -ItemType Directory -Path $rd -Force | Out-Null
    Set-Content -Path "$rd\head-name" -Value "refs/heads/chaos-branch" -Force
    Set-Content -Path "$rd\onto" -Value "abc123def456" -Force
    $stamp = (Get-Date).AddHours(-3)
    (Get-Item $rd).CreationTime = $stamp
    (Get-Item $rd).LastWriteTime = $stamp
    Write-Host "  [CREATED] $rd (aged 3 hours)" -ForegroundColor DarkRed
}
$script:ATTACKS["Rebase"] = "4 stuck rebase directories created"

# ─────────────────────────────────────────────────────
# ATTACK 3: CORRUPT CREDENTIAL STORE
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 3/7: Corrupt credential store" -ForegroundColor Red
# Remove credential store settings
git config --global --unset credential.credentialStore 2>$null
git config --global --unset credential.helper 2>$null
# Set a non-existent credential helper that will fail
git config --global credential.helper "!f() { exit 1; }; f" 2>$null
Write-Host "  [SET] credential.helper to broken script (always fails)" -ForegroundColor DarkRed
Write-Host "  [DELETED] credential.credentialStore" -ForegroundColor DarkRed
$script:ATTACKS["Credential"] = "Credential helper broken + store removed"

# ─────────────────────────────────────────────────────
# ATTACK 4: SWITCH REMOTE TO HTTPS (BROKEN)
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 4/7: Switch remote to HTTPS (broken)" -ForegroundColor Red
$remotes = @(
    @{ Path = "C:\obsidian\Main"; Name = "origin"; BadUrl = "https://github.com/Konstantin2005/ObsiduanMain.git" },
    @{ Path = "C:\obsidian"; Name = "origin"; BadUrl = "https://github.com/Konstantin2005/BecapOvsiduan.git" }
)
foreach ($r in $remotes) {
    Push-Location $r.Path
    git remote set-url $r.Name $r.BadUrl 2>$null
    Write-Host "  [CHANGED] $($r.Path): remote $($r.Name) -> $($r.BadUrl)" -ForegroundColor DarkRed
    Pop-Location
}
$script:ATTACKS["Remote"] = "Both repos switched to HTTPS (will prompt for creds)"

# ─────────────────────────────────────────────────────
# ATTACK 5: CREATE STALE GIT PROCESSES
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 5/7: Stale git processes" -ForegroundColor Red
# We can't easily create real git processes from here, but we can
# create a PID file that looks like a stale process
$pidFiles = @(
    "C:\obsidian\Main\.git\gc.pid",
    "C:\obsidian\.git\gc.pid"
)
foreach ($pf in $pidFiles) {
    Set-Content -Path $pf -Value "99999" -Force
    $stamp = (Get-Date).AddHours(-4)
    (Get-Item $pf).CreationTime = $stamp
    (Get-Item $pf).LastWriteTime = $stamp
}
Write-Host "  [CREATED] Stale gc.pid files (fake PID 99999)" -ForegroundColor DarkRed

# Also create a real background process that simulates a stale git
$scriptName = [System.IO.Path]::GetTempFileName() + ".ps1"
@"
Start-Sleep -Seconds 3600
"@ | Set-Content $scriptName -Force
$staleProc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptName`"" -WindowStyle Hidden -PassThru
Write-Host "  [SPAWNED] Background process PID=$($staleProc.Id) (will be killed as 'stale git')" -ForegroundColor DarkRed
$script:ATTACKS["Processes"] = "Stale gc.pid + background process spawned"

# ─────────────────────────────────────────────────────
# ATTACK 6: DELETE TASK SCHEDULER TASKS
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 6/7: Delete Task Scheduler tasks" -ForegroundColor Red
$tasksToKill = @("AutoCommitNotes", "GitWorker", "HealthMonitor")
foreach ($tn in $tasksToKill) {
    schtasks /DELETE /TN $tn /F 2>$null | Out-Null
    Write-Host "  [DELETED] Task: $tn" -ForegroundColor DarkRed
}
$script:ATTACKS["Tasks"] = "All 3 scheduled tasks deleted"

# ─────────────────────────────────────────────────────
# ATTACK 7: CORRUPT .git CONFIG & ADD GARBAGE
# ─────────────────────────────────────────────────────
Write-Host "▰▰▰ ATTACK 7/7: Corrupt .git config + garbage" -ForegroundColor Red
# Remove GIT_TERMINAL_PROMPT setting
git config --global --unset gui.gcwarning 2>$null

# Add garbage objects to .git
$garbageDir = "C:\obsidian\Main\.git\objects\chaos"
New-Item -ItemType Directory -Path $garbageDir -Force | Out-Null
$bigFile = [System.Text.StringBuilder]::new()
for ($i = 0; $i -lt 10000; $i++) { $null = $bigFile.Append("GARBAGE_DATA_CHAOS_ATTACK_$i`n") }
Set-Content -Path "$garbageDir\garbage_object" -Value $bigFile.ToString() -Force
Write-Host "  [CREATED] 500KB garbage object in .git/objects/chaos/" -ForegroundColor DarkRed

# Remove the push config
git config --local --unset branch.main.remote 2>$null
git config --local --unset branch.main.merge 2>$null
Write-Host "  [REMOVED] branch.main.remote + merge config (push will fail)" -ForegroundColor DarkRed
$script:ATTACKS["Config"] = "Git config corrupted + garbage added"

# ─────────────────────────────────────────────────────
# REPORT
# ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗"
Write-Host "║     ⚔️  ATTACK COMPLETE — 7/7 FAILURES       ║"
Write-Host "╠══════════════════════════════════════════════╣"
foreach ($key in $script:ATTACKS.Keys) {
    Write-Host "║  ✗ $($key): $($script:ATTACKS[$key])" -ForegroundColor Red
}
Write-Host "╚══════════════════════════════════════════════╝"
Write-Host ""
Write-Host "System is BROKEN. Run self-healer to test recovery." -ForegroundColor Yellow

# Save attack log
$attackLog = "C:\obsidian\Main\Technical\Scripts\Logs\chaos-attack.log"
$report = @"
╔══════════════════════════════════════════════╗
║     CHAOS ATTACK LOG — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')        ║
╠══════════════════════════════════════════════╣
$(foreach ($key in $script:ATTACKS.Keys) { "║  ✗ $key`: $($script:ATTACKS[$key])`n" })
╚══════════════════════════════════════════════╝
"@
Add-Content -Path $attackLog -Value $report -Encoding UTF8
Write-Host "Attack logged: $attackLog"
