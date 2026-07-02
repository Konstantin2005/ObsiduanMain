# test-repos.ps1 - Integration tests for real git repos

. (Join-Path $PSScriptRoot "..\..\system\core.ps1")

$failed = 0
$passed = 0

function Write-TestResult {
    param([string]$Name, [bool]$Result, [string]$Detail = "")
    if ($Result) { $script:passed++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:failed++; Write-Host "  [FAIL] $Name : $Detail" -ForegroundColor Red }
}

Write-Host "=== Integration Tests ===" -ForegroundColor Cyan

Write-Host "--- Vault Repo ---" -ForegroundColor Yellow
$vaultPath = "C:\obsidian\Main"

$status = Test-GitRepo -RepoPath $vaultPath
Write-TestResult "Repo exists and valid" ($status.Status -eq "OK")

$remote = Test-Remote -RepoPath $vaultPath
Write-TestResult "Remote origin configured" ($remote.Status -eq "OK")

$gitignore = Get-Content "$vaultPath\.gitignore" -Encoding UTF8 -ErrorAction SilentlyContinue
Write-TestResult ".gitignore exists" (-not [string]::IsNullOrEmpty($gitignore))
Write-TestResult ".gitignore has *.log" (($gitignore -match '\*\.log').Count -gt 0)
Write-TestResult ".gitignore has *.apk" (($gitignore -match '\*\.apk').Count -gt 0)
Write-TestResult ".gitignore has Calendula" (($gitignore -match 'Calendula/').Count -gt 0)

$trackedApk = Invoke-Git -RepoPath $vaultPath -Arguments @("ls-files", "*.apk")
Write-TestResult "No .apk files tracked" (-not $trackedApk)

$trackedLogs = Invoke-Git -RepoPath $vaultPath -Arguments @("ls-files", "Technical/Scripts/Logs/")
Write-TestResult "Log files not tracked" (-not $trackedLogs)

$lockResult = Test-LockFile -RepoPath $vaultPath
Write-TestResult "No stale lock files" ($lockResult.Status -eq "OK" -or $lockResult.Status -eq "LOCKED") "Status: $($lockResult.Status)"

$ahead = Get-AheadCount -RepoPath $vaultPath
Write-TestResult "Ahead count is manageable" ($ahead -le 50) "Ahead: $ahead"

$remoteUrl = Invoke-Git -RepoPath $vaultPath -Arguments @("remote", "get-url", "origin")
Write-TestResult "Remote is SSH" (($remoteUrl -match "^git@github\.com").Count -gt 0 -or $remoteUrl -match "^git@github\.com")

$obsidianFiles = Invoke-Git -RepoPath $vaultPath -Arguments @("ls-files", ".obsidian/")
Write-TestResult "No .obsidian tracked in root" (-not $obsidianFiles)

Write-Host "--- Parent Repo ---" -ForegroundColor Yellow
$parentPath = "C:\obsidian"

$status = Test-GitRepo -RepoPath $parentPath
Write-TestResult "Parent repo exists and valid" ($status.Status -eq "OK")
$remote = Test-Remote -RepoPath $parentPath
Write-TestResult "Parent remote origin configured" ($remote.Status -eq "OK")
$lockResult = Test-LockFile -RepoPath $parentPath
Write-TestResult "No stale locks in parent" ($lockResult.Status -eq "OK" -or $lockResult.Status -eq "LOCKED") "Status: $($lockResult.Status)"
$parentGitignore = Get-Content "$parentPath\.gitignore" -Encoding UTF8 -ErrorAction SilentlyContinue
Write-TestResult "Parent .gitignore exists" (-not [string]::IsNullOrEmpty($parentGitignore))

Write-Host "--- System Files ---" -ForegroundColor Yellow
$systemFiles = @(
    "C:\obsidian\Main\Technical\Scripts\system\core.ps1",
    "C:\obsidian\Main\Technical\Scripts\system\health-monitor.ps1",
    "C:\obsidian\Main\Technical\Scripts\system\self-healer.ps1",
    "C:\obsidian\Main\vault\auto-commit.ps1",
    "C:\obsidian\Main\vault\git-worker.ps1",
    "C:\obsidian\Main\.gitignore"
)
foreach ($file in $systemFiles) {
    Write-TestResult "File: $(Split-Path $file -Leaf)" (Test-Path $file)
}

foreach ($script in @("auto-commit.ps1", "git-worker.ps1")) {
    $path = "C:\obsidian\Main\vault\$script"
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$parseErrors)
    Write-TestResult "$script valid PowerShell" ($parseErrors.Count -eq 0) "Parse errors: $($parseErrors.Count)"
}

Write-Host "--- Git Config ---" -ForegroundColor Yellow
$credHelper = git config --global credential.helper 2>$null
Write-TestResult "credential.helper set" (-not [string]::IsNullOrEmpty($credHelper))
$interactive = git config --global --get-all credential.github.com.interactive 2>$null
Write-TestResult "GitHub interactive=never" ($interactive -match "never")

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "INTEGRATION RESULTS: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "=====================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
