# Git Automation Monitor Script
# Monitors and logs git commit/push operations

param(
    [string]$LogPath = "C:\obsidian\Main\Calendula\git-monitor.log",
    [string]$FailureLogPath = "C:\obsidian\Main\Calendula\git-failures.log",
    [int]$ExpectedCommitIntervalHours = 6,
    [string]$ExpectedCommitMessage = "Automated commit"
)

# Create log directories if they don't exist
$logDir = Split-Path -Path $LogPath -Parent
if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$failureLogDir = Split-Path -Path $FailureLogPath -Parent
if (-not (Test-Path -Path $failureLogDir)) {
    New-Item -ItemType Directory -Path $failureLogDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}

function Write-FailureLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $failureEntry = "$timestamp - FAILURE: $Message"
    Write-Host "FAILURE: $Message"
    Add-Content -Path $FailureLogPath -Value $failureEntry
}

function Check-LastCommit {
    try {
        $lastCommit = git log -1 --format="%H %s %ci"
        if ($lastCommit) {
            $commitHash = $lastCommit.Split(' ')[0]
            $commitMessage = $lastCommit.Split(' ')[1..($lastCommit.Split(' ').Count - 1)] -join ' '
            $commitTime = $lastCommit.Split(' ')[$lastCommit.Split(' ').Count - 1]
            
            Write-Log "Last commit: $commitHash - $commitMessage at $commitTime"
            
            # Parse date with timezone offset
            $commitTime = $commitTime.Trim()
            if ($commitTime -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (.+)$") {
                $datePart = $matches[1]
                $timeZonePart = $matches[2]
                $lastCommitTime = [DateTime]::ParseExact($datePart, "yyyy-MM-dd HH:mm:ss", $null)
                $timeSinceLastCommit = (Get-Date) - $lastCommitTime
                
                if ($timeSinceLastCommit.TotalHours -gt ($ExpectedCommitIntervalHours * 2)) {
                    Write-FailureLog "Commit overdue: Last commit was $($timeSinceLastCommit.TotalHours) hours ago (expected every $ExpectedCommitIntervalHours hours)"
                }
            }
            
            if ($commitMessage -notlike "*$ExpectedCommitMessage*" -and $commitMessage -notlike "*Automated*") {
                Write-FailureLog "Unexpected commit message: '$commitMessage' (expected: '$ExpectedCommitMessage')"
            }
        } else {
            Write-FailureLog "No commits found in repository"
        }
    } catch {
        Write-FailureLog "Failed to check last commit: $($_.Exception.Message)"
    }
}

function Check-RemoteStatus {
    try {
        $remoteStatus = git status --porcelain
        if ($remoteStatus) {
            Write-Log "Repository has uncommitted changes: $remoteStatus"
            Write-FailureLog "Uncommitted changes detected: $remoteStatus"
        } else {
            Write-Log "Repository is clean"
        }
    } catch {
        Write-FailureLog "Failed to check remote status: $($_.Exception.Message)"
    }
}

function Check-RepositoryHealth {
    try {
        $branch = git rev-parse --abbrev-ref HEAD
        Write-Log "Current branch: $branch"
        
        $remoteUrl = git config --get remote.origin.url
        if ($remoteUrl) {
            Write-Log "Remote URL: $remoteUrl"
        } else {
            Write-FailureLog "No remote.origin.url configured"
        }
        
        $logCount = git log --oneline --since="24 hours ago" | Measure-Object -Line
        $logCount = $logCount.Count
        Write-Log "Commits in last 24 hours: $logCount"
        
        if ($logCount -eq 0) {
            Write-FailureLog "No commits in last 24 hours (expected at least one)"
        }
        
    } catch {
        Write-FailureLog "Failed to check repository health: $($_.Exception.Message)"
    }
}

function Main {
    Write-Log "=== Git Automation Monitor Started ==="
    Write-Log "Expected commit interval: $ExpectedCommitIntervalHours hours"
    Write-Log "Expected commit message pattern: $ExpectedCommitMessage"
    
    Check-LastCommit
    Check-RemoteStatus
    Check-RepositoryHealth
    
    Write-Log "=== Git Automation Monitor Completed ==="
}

Main