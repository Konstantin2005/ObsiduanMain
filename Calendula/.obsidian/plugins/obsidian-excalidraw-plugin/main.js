# Git Commit/Push Automation Monitor
# Monitors and logs git commit/push operations with detailed failure tracking

param(
    [string]$MonitorLogPath = "C:\obsidian\Main\Calendula\logs\git-monitor.log",
    [string]$FailureLogPath = "C:\obsidian\Main\Calendula\logs\git-failures.log",
    [string]$ExpectedCommitPattern = "Automated commit",
    [int]$ExpectedCommitIntervalHours = 6,
    [int]$MaxCommitsPerDay = 4,
    [switch]$EnableVerboseLogging
)

# Create log directories if they don't exist
$logDir = Split-Path -Path $MonitorLogPath -Parent
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$failureLogDir = Split-Path -Path $FailureLogPath -Parent
if (-not (Test-Path -Path $failureLogDir)) {
    New-Item -ItemType Directory -Path $failureLogDir -Force | Out-Null
}

function Write-MonitorLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Host $logEntry
    Add-Content -Path $MonitorLogPath -Value $logEntry
}

function Write-FailureLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $failureEntry = "$timestamp - FAILURE: $Message"
    Write-Host "FAILURE: $Message" -ForegroundColor Red
    Add-Content -Path $FailureLogPath -Value $failureEntry
}

function Initialize-Monitor {
    Write-MonitorLog "=== Git Commit/Push Automation Monitor Started ==="
    Write-MonitorLog "Expected commit pattern: $ExpectedCommitPattern"
    Write-MonitorLog "Expected commit interval: $ExpectedCommitIntervalHours hours"
    Write-MonitorLog "Maximum commits per day: $MaxCommitsPerDay"
}

function Check-RepositoryHealth {
    try {
        $branch = git rev-parse --abbrev-ref HEAD
        Write-MonitorLog "Current branch: $branch"
        
        $remoteUrl = git config --get remote.origin.url
        if ($remoteUrl) {
            Write-MonitorLog "Remote URL: $remoteUrl"
        } else {
            Write-FailureLog "No remote.origin.url configured"
        }
        
        $logCount = git log --oneline --since="24 hours ago" | Measure-Object -Line
        Write-MonitorLog "Commits in last 24 hours: $logCount"
        
        if ($logCount -eq 0) {
            Write-FailureLog "No commits in last 24 hours (expected at least one)"
        }
        
    } catch {
        Write-FailureLog "Failed to check repository health: $($_.Exception.Message)"
    }
}

function Analyze-LastCommit {
    try {
        $lastCommit = git log -1 --format="%H %s %ci"
        if ($lastCommit) {
            $commitHash = $lastCommit.Split(' ')[0]
            $commitMessage = $lastCommit.Split(' ')[1..($lastCommit.Split(' ').Count - 1)] -join ' '
            $commitTime = $lastCommit.Split(' ')[$lastCommit.Split(' ').Count - 1]
            
            Write-MonitorLog "Last commit: $commitHash - $commitMessage at $commitTime"
            
            $lastCommitTime = [DateTime]::ParseExact($commitTime, "yyyy-MM-dd HH:mm:ss", $null)
            $timeSinceLastCommit = (Get-Date) - $lastCommitTime
            
            if ($timeSinceLastCommit.TotalHours -gt ($ExpectedCommitIntervalHours * 2)) {
                Write-FailureLog "Commit overdue: Last commit was $($timeSinceLastCommit.TotalHours) hours ago (expected every $ExpectedCommitIntervalHours hours)"
            }
            
            if ($commitMessage -notlike "*$ExpectedCommitPattern*" -and $commitMessage -notlike "*Automated*") {
                Write-FailureLog "Unexpected commit message: '$commitMessage' (expected: '$ExpectedCommitPattern')"
            }
            
            $todayCommits = git log --oneline --since="00:00:00" | Measure-Object -Line
            if ($todayCommits -gt $MaxCommitsPerDay) {
                Write-FailureLog "Too many commits today: $todayCommits (maximum: $MaxCommitsPerDay)"
            }
            
        } else {
            Write-FailureLog "No commits found in repository"
        }
    } catch {
        Write-FailureLog "Failed to analyze last commit: $($_.Exception.Message)"
    }
}

function Check-UncommittedChanges {
    try {
        $remoteStatus = git status --porcelain
        if ($remoteStatus) {
            Write-MonitorLog "Repository has uncommitted changes: $remoteStatus"
            Write-FailureLog "Uncommitted changes detected: $remoteStatus"
        } else {
            Write-MonitorLog "Repository is clean"
        }
    } catch {
        Write-FailureLog "Failed to check uncommitted changes: $($_.Exception.Message)"
    }
}

function Check-ExpectedCommitSchedule {
    try {
        $today = Get-Date -Format "yyyy-MM-dd"
        $todayCommits = git log --oneline --since="$today 00:00:00" --until="$today 23:59:59"
        $commitCount = $todayCommits | Measure-Object -Line
        
        Write-MonitorLog "Expected commits today: $MaxCommitsPerDay"
        Write-MonitorLog "Actual commits today: $commitCount"
        
        if ($commitCount -eq 0) {
            Write-FailureLog "No commits today (expected at least one)"
        } elseif ($commitCount -lt ($MaxCommitsPerDay / 2)) {
            Write-MonitorLog "Low commit count today: $commitCount (expected at least $($MaxCommitsPerDay / 2))"
        }
        
    } catch {
        Write-FailureLog "Failed to check expected commit schedule: $($_.Exception.Message)"
    }
}

function Log-ExpectedVsActual {
    try {
        $expectedCommits = @()
        $actualCommits = @()
        
        $today = Get-Date -Format "yyyy-MM-dd"
        $yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
        
        $expectedCommits = @(
            "$yesterday 12:00:00 - $ExpectedCommitPattern",
            "$yesterday 18:00:00 - $ExpectedCommitPattern",
            "$today 09:00:00 - $ExpectedCommitPattern",
            "$today 15:00:00 - $ExpectedCommitPattern"
        )
        
        $actualCommits = git log --oneline --since="$yesterday 00:00:00" --until="$today 23:59:59"
        
        Write-MonitorLog "=== Expected vs Actual Commits ==="
        foreach ($expected in $expectedCommits) {
            Write-MonitorLog "Expected: $expected"
        }
        
        Write-MonitorLog "=== Actual Commits ==="
        foreach ($actual in $actualCommits) {
            Write-MonitorLog "Actual: $actual"
        }
        
        $missedExpected = $expectedCommits | Where-Object { $_ -notin $actualCommits }
        if ($missedExpected) {
            Write-FailureLog "Missed expected commits: $($missedExpected -join ', ')"
        }
        
    } catch {
        Write-FailureLog "Failed to log expected vs actual commits: $($_.Exception.Message)"
    }
}

function Main-Monitor {
    Initialize-Monitor
    Check-RepositoryHealth
    Analyze-LastCommit
    Check-UncommittedChanges
    Check-ExpectedCommitSchedule
    Log-ExpectedVsActual
    
    Write-MonitorLog "=== Git Commit/Push Automation Monitor Completed ==="
}

Main-Monitor