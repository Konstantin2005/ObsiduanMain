param(
    [string]$RepoPath = "C:\obsidian\Main"
)

Set-Location $RepoPath

$date = Get-Date -Format "yyyy-MM-dd"

git add -A

$changes = git status --porcelain
if (-not $changes) {
    exit 0
}

git commit -m $date
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

git push
exit $LASTEXITCODE
