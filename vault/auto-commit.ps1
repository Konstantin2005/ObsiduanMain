<#
.SYNOPSIS
    Auto-commit: saves vault changes every 60 min.
    Self-logging. Runs via Windows Task Scheduler (hidden window).
.EXAMPLE
    .\vault\auto-commit.ps1
    .\vault\auto-commit.ps1 -ThresholdFiles 1 -ThresholdLines 1
#>

param(
    [int]$ThresholdFiles = 1,
    [int]$ThresholdLines = 1,
    [string]$ObsidianRoot = ""
)

# ====== HIDE TERMINAL WINDOW ======
$Async = '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -MemberDefinition $Async -Name "Win32ShowWindow" -Namespace Win32 -PassThru
$Type::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0) | Out-Null

$StartTime = Get-Date

# ====== DUMB-USER BOOTSTRAP ======
# Protection 1: Check git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "FATAL: Git is not installed. Install git from https://git-scm.com/"
    exit 99
}

# Protection 2: Determine correct paths regardless of where script is launched
$script:DetectedRoot = if ($ObsidianRoot) { $ObsidianRoot } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$script:VaultPath = Join-Path $script:DetectedRoot "Main"
if (-not (Test-Path $script:VaultPath)) {
    # Fallback: maybe script is inside Main/vault/ already
    $script:VaultPath = $script:DetectedRoot
    $script:DetectedRoot = Split-Path -Parent $script:DetectedRoot
}

# Protection 3: Ensure we're in the right directory
Set-Location $script:DetectedRoot -ErrorAction Stop

# Protection 4: Ensure .git exists (dumb user might have deleted it)
$gitDir = Join-Path $script:VaultPath ".git"
if (-not (Test-Path $gitDir)) {
    Write-Host "[BOOTSTRAP] .git missing! Attempting recovery..."
    $remoteUrl = "git@github.com:Konstantin2005/ObsiduanMain.git"
    $initOk = & git -C $script:VaultPath init 2>$null
    if ($LASTEXITCODE -eq 0) {
        & git -C $script:VaultPath remote add origin $remoteUrl 2>$null
        & git -C $script:VaultPath config user.name "Auto-commit Bot" 2>$null
        & git -C $script:VaultPath config user.email "bot@obsidian.vault" 2>$null
        & git -C $script:VaultPath fetch origin 2>$null
        $remoteMain = & git -C $script:VaultPath rev-parse origin/main 2>$null
        if ($remoteMain) {
            & git -C $script:VaultPath reset --hard origin/main 2>$null
            & git -C $script:VaultPath branch --set-upstream-to=origin/main main 2>$null
            Write-Host "[BOOTSTRAP] .git recovered from remote! Reset to origin/main"
        } else {
            & git -C $script:VaultPath add -A 2>$null
            & git -C $script:VaultPath commit -m "chore: recovery after .git deletion" 2>$null
            & git -C $script:VaultPath branch -M main 2>$null
            & git -C $script:VaultPath config --local branch.main.remote origin 2>$null
            & git -C $script:VaultPath config --local branch.main.merge refs/heads/main 2>$null
            Write-Host "[BOOTSTRAP] New .git initialized with initial commit"
        }
    } else {
        Write-Host "[BOOTSTRAP] FATAL: Cannot reinitialize git: $initOk"
        exit 98
    }
}

# Protection 5: Simple mutex (prevent two instances)
$mutexName = "Global\ObsidianAutoCommit-$([System.Environment]::UserName)"
try {
    $script:Mutex = New-Object System.Threading.Mutex($false, $mutexName)
    if (-not $script:Mutex.WaitOne(0)) {
        Write-Host "[BOOTSTRAP] Another instance is already running. Exiting."
        exit 0
    }
} catch {}

# ====== SILENT GIT ENV ======
# РќРµ РґР°С‘Рј git'Сѓ Р·Р°РїСЂР°С€РёРІР°С‚СЊ РёРЅС‚РµСЂР°РєС‚РёРІРЅС‹Р№ РІРІРѕРґ (С‡С‚РѕР± РЅРµ Р·Р°РІРёСЃ РІ Task Scheduler)
$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASKPASS = "echo"
$env:GCM_INTERACTIVE = "never"

$Branch = & git rev-parse --abbrev-ref HEAD 2>$null
if (-not $Branch) { $Branch = "unknown" }

# Log system (РєР»Р°РґС‘Рј РІ Main/vault/log/ С‡С‚РѕР±С‹ РЅРµ РїРѕС‚РµСЂСЏС‚СЊ РёСЃС‚РѕСЂРёСЋ)
$VaultDir = Join-Path $ObsidianRoot "Main"
$LogDir = Join-Path (Join-Path $VaultDir "vault\log") "script"
$HistoryLog = Join-Path (Join-Path $VaultDir "vault\log") "script-history.md"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
if (-not (Test-Path $HistoryLog)) {
    "# Script History`n`n| Date | Script | Branch | Exit | Duration | Output |" | Set-Content $HistoryLog
}
$ScriptName = "auto-commit.ps1"
$ScriptLog = Join-Path $LogDir $ScriptName

function Write-Log {
    param([int]$ExitCode)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $dur = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)
    $output = "[auto-commit] $ScriptName on $Branch exit=$ExitCode"
    $line = "| $ts | $ScriptName | $Branch | $ExitCode | ${dur}s | $output |"
    Add-Content $HistoryLog $line
    "[$ts] branch=$Branch exit=$ExitCode duration=${dur}s" | Add-Content $ScriptLog
    exit $ExitCode
}

# Only run on allowed branches (Obsidian-wide РёСЃРїРѕР»СЊР·СѓРµС‚ master, Main РёСЃРїРѕР»СЊР·СѓРµС‚ main)
$Allowed = @("main", "master", "develop", "feature/", "ai/")
$ShouldRun = $false
foreach ($prefix in $Allowed) {
    if ($Branch -eq $prefix -or $Branch -like "$prefix*") {
        $ShouldRun = $true
        break
    }
}
if (-not $ShouldRun) { Write-Log 0 }

# ====== CHECK FOR CHANGES ======
# РСЃРїРѕР»СЊР·СѓРµРј git status --porcelain вЂ” РѕРЅ РІРёРґРёС‚ Р’РЎР• РёР·РјРµРЅРµРЅРёСЏ (РІРєР»СЋС‡Р°СЏ untracked)
$Porcelain = & git status --porcelain 2>$null
$HasChanges = ($Porcelain -join '').Trim() -ne ''

if (-not $HasChanges) {
    Write-Log 0
}

# РЎС‡РёС‚Р°РµРј СЂРµР°Р»СЊРЅС‹Рµ РёР·РјРµРЅРµРЅРёСЏ
$FilesChanged = @($Porcelain | Where-Object { $_ -ne '' }).Count
$LinesChanged = 0
$Numstat = & git diff --numstat 2>$null
if ($Numstat) {
    $LinesChanged = ($Numstat | ForEach-Object {
        $parts = $_ -split "`t"
        $a = 0; $r = 0
        [int]::TryParse($parts[0], [ref]$a) | Out-Null
        [int]::TryParse($parts[1], [ref]$r) | Out-Null
        $a + $r
    } | Measure-Object -Sum).Sum
}

if ($FilesChanged -lt $ThresholdFiles -and $LinesChanged -lt $ThresholdLines) {
    Write-Log 0
}

# ====== STAGE ALL CHANGES ======
git add -A 2>&1 | ForEach-Object { Add-Content $ScriptLog "  $_" }
$AddExit = $LASTEXITCODE
if ($AddExit -ne 0) {
    Start-Sleep -Seconds 1
    git add -A 2>&1 | ForEach-Object { Add-Content $ScriptLog "  $_" }
}

# ====== COMMIT ======
$Date = Get-Date -Format "yyyy-MM-dd HH:mm"
$Message = "chore(vault): auto-save $Date"
$CommitOutput = git commit -m $Message --no-gpg-sign 2>&1
$CommitExit = $LASTEXITCODE
$CommitOutput | ForEach-Object { Add-Content $ScriptLog "  $_" }

if ($CommitExit -ne 0) {
    Write-Log 0
}

# ====== PUSH WITH 3-LAYER FALLBACK ======
$AheadCount = & git rev-list --count "origin/$Branch..HEAD" 2>$null
if ($AheadCount -and $AheadCount -gt 0 -and $AheadCount -le 50) {
    # Try SSH first (fastest, no prompts)
    $remoteUrl = & git remote get-url origin 2>$null
    $sshUrl = $remoteUrl -replace '^https://github\.com/', 'git@github.com:'
    & git remote set-url origin $sshUrl 2>$null
    
    $PushOutput = git push origin $Branch 2>&1
    $PushExit = $LASTEXITCODE
    
    # Fallback to HTTPS if SSH fails
    if ($PushExit -ne 0) {
        & git remote set-url origin $remoteUrl 2>$null  # restore HTTPS
        $PushOutput = git push origin $Branch 2>&1
        $PushExit = $LASTEXITCODE
    }
    
    # Fallback to gh CLI
    if ($PushExit -ne 0) {
        $token = $(gh auth token 2>$null)
        if ($token) {
            $env:GIT_TERMINAL_PROMPT = "0"
            $PushOutput = gh push --repo $remoteUrl 2>&1
            $PushExit = $LASTEXITCODE
        }
    }
    
    $PushOutput | ForEach-Object { Add-Content $ScriptLog "  $_" }
    if ($PushExit -eq 0) {
        Add-Content $ScriptLog "[auto-commit] Push OK, $AheadCount commits"
        # Restore SSH for next run
        & git remote set-url origin $sshUrl 2>$null
    } else {
        Add-Content $ScriptLog "[auto-commit] All push methods failed (non-fatal)"
    }
} elseif ($AheadCount -and $AheadCount -gt 50) {
    Add-Content $ScriptLog "[auto-commit] $AheadCount commits ahead, push skipped"
} else {
    Add-Content $ScriptLog "[auto-commit] Nothing to push"
}

# ====== CLEANUP ======
# Release mutex so next instance can run
try { if ($script:Mutex) { $script:Mutex.ReleaseMutex(); $script:Mutex.Dispose() } } catch {}

Write-Log 0
