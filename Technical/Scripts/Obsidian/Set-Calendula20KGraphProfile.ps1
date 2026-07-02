[CmdletBinding()]
param(
    [ValidateSet('fast-backbone', 'people', 'current-year', 'diaries2026', 'full-danger')]
    [string]$Profile = 'fast-backbone',

    [switch]$OpenGraph,

    [switch]$AllowDanger,

    [string]$VaultPath = ''
)

$ErrorActionPreference = 'Stop'

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Value
    )
    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $json = $Value | ConvertTo-Json -Depth 32
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, ($json + [Environment]::NewLine), $encoding)
}

function Get-ProfileObject {
    param(
        [Parameter(Mandatory)]$Profiles,
        [Parameter(Mandatory)][string]$Name
    )
    $property = $Profiles.profiles.PSObject.Properties[$Name]
    if (-not $property) {
        throw "Graph profile '$Name' was not found."
    }
    return $property.Value
}

function Get-GraphSettings {
    param([Parameter(Mandatory)]$ProfileObject)
    $settingsProperty = $ProfileObject.PSObject.Properties['graphSettings']
    if ($settingsProperty) {
        return $settingsProperty.Value
    }
    return $ProfileObject
}

function Test-ProfilePolicy {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$ProfileObject,
        [switch]$AllowDanger
    )

    $startupAllowed = $ProfileObject.PSObject.Properties['startupAllowed']
    $danger = $ProfileObject.PSObject.Properties['danger']
    $requiresConfirmation = $ProfileObject.PSObject.Properties['requiresConfirmation']
    $renderer = $ProfileObject.PSObject.Properties['renderer']
    $graphSettings = Get-GraphSettings -ProfileObject $ProfileObject
    $search = $graphSettings.PSObject.Properties['search']

    if (($danger -and [bool]$danger.Value) -or ($requiresConfirmation -and [bool]$requiresConfirmation.Value)) {
        if (-not $AllowDanger) {
            throw "Profile '$Name' is dangerous and requires -AllowDanger."
        }
    }

    if ($Name -eq 'fast-backbone') {
        if ($startupAllowed -and -not [bool]$startupAllowed.Value) {
            throw "fast-backbone must be startupAllowed."
        }
        if (-not $search -or [string]::IsNullOrWhiteSpace([string]$search.Value)) {
            throw "fast-backbone must have a non-empty graph search."
        }
    }

    if ($Name -eq 'full-danger' -and $startupAllowed -and [bool]$startupAllowed.Value) {
        throw "full-danger cannot be startupAllowed."
    }

    if ($renderer -and $renderer.Value -eq 'native' -and $Name -ne 'full-danger') {
        if (-not $search -or [string]::IsNullOrWhiteSpace([string]$search.Value)) {
            throw "Native profile '$Name' must have a non-empty search."
        }
    }
}

$defaultVaultPath = Join-Path $PSScriptRoot '..\..\Calendula-20K'
if ([string]::IsNullOrWhiteSpace($VaultPath)) {
    $VaultPath = $defaultVaultPath
}

$vault = Resolve-Path -LiteralPath $VaultPath
$obsidian = Join-Path $vault '.obsidian'
$profilesPath = Join-Path $obsidian 'graph-profiles.json'
$graphPath = Join-Path $obsidian 'graph.json'
$workspacePath = Join-Path $obsidian 'workspace.json'
$corePluginsPath = Join-Path $obsidian 'core-plugins.json'
$communityPluginsPath = Join-Path $obsidian 'community-plugins.json'
$launchFile = Get-ChildItem -LiteralPath (Join-Path $vault 'Calendula') -Recurse -File -Filter '*.md' |
    Sort-Object FullName |
    Select-Object -First 1
$launchVaultPath = if ($launchFile) {
    $launchFile.FullName.Substring($vault.Path.Length + 1).Replace('\', '/')
} else {
    ''
}
$personFile = Get-ChildItem -LiteralPath $vault -Recurse -File -Filter 'Person-0001.md' |
    Sort-Object FullName |
    Select-Object -First 1
$personVaultPath = if ($personFile) {
    $personFile.FullName.Substring($vault.Path.Length + 1).Replace('\', '/')
} else {
    $null
}

$profiles = Read-JsonFile -Path $profilesPath
if (-not $profiles) {
    throw "Missing graph profiles file: $profilesPath"
}

$profileObject = Get-ProfileObject -Profiles $profiles -Name $Profile
Test-ProfilePolicy -Name $Profile -ProfileObject $profileObject -AllowDanger:$AllowDanger
$graphProfile = Get-GraphSettings -ProfileObject $profileObject
Write-JsonFile -Path $graphPath -Value $graphProfile

$corePlugins = Read-JsonFile -Path $corePluginsPath
if ($corePlugins) {
    $enabled = @('file-explorer', 'switcher', 'graph', 'command-palette', 'editor-status')
    foreach ($property in $corePlugins.PSObject.Properties) {
        $property.Value = $enabled -contains $property.Name
    }
    Write-JsonFile -Path $corePluginsPath -Value $corePlugins
}

$communityPlugins = @(
    'calendula-graph-guard',
    'calendula-ultra-graph'
)
Write-JsonFile -Path $communityPluginsPath -Value $communityPlugins

$workspace = Read-JsonFile -Path $workspacePath
if ($workspace) {
    $shouldOpenGraph = ($OpenGraph -or $Profile -ne 'full-danger') -and (-not ($profileObject.PSObject.Properties['danger'] -and [bool]$profileObject.danger))
    $leafId = if ($shouldOpenGraph) { 'calendula-20k-fast-graph' } else { 'calendula-20k-launch-note' }
    $leafState = if ($shouldOpenGraph) {
        [ordered]@{
            type = 'graph'
            state = [ordered]@{}
            icon = 'lucide-git-fork'
            title = "Graph: $Profile"
        }
    } else {
        [ordered]@{
            type = 'markdown'
            state = [ordered]@{
                file = $launchVaultPath
                mode = 'source'
                source = $false
            }
            icon = 'lucide-file'
            title = if ($launchFile) { $launchFile.BaseName } else { 'Calendula-20K' }
        }
    }

    $workspace.main = [ordered]@{
        id = 'calendula-20k-main'
        type = 'split'
        children = @(
            [ordered]@{
                id = 'calendula-20k-tabs'
                type = 'tabs'
                children = @(
                    [ordered]@{
                        id = $leafId
                        type = 'leaf'
                        state = $leafState
                    }
                )
                currentTab = 0
            }
        )
        direction = 'vertical'
    }
    $workspace.left = [ordered]@{
        id = 'calendula-20k-left'
        type = 'split'
        children = @(
            [ordered]@{
                id = 'calendula-20k-left-tabs'
                type = 'tabs'
                children = @(
                    [ordered]@{
                        id = 'calendula-20k-files'
                        type = 'leaf'
                        state = [ordered]@{
                            type = 'file-explorer'
                            state = [ordered]@{
                                sortOrder = 'alphabetical'
                                autoReveal = $false
                            }
                            icon = 'lucide-folder-closed'
                            title = 'Files'
                        }
                    }
                )
                currentTab = 0
            }
        )
        direction = 'horizontal'
        width = 260
        collapsed = $true
    }
    $workspace.right = [ordered]@{
        id = 'calendula-20k-right'
        type = 'split'
        children = @()
        direction = 'horizontal'
        width = 260
        collapsed = $true
    }
    $workspace.'left-ribbon' = [ordered]@{
        hiddenItems = [ordered]@{}
    }
    $workspace.active = $leafId
    $workspace.lastOpenFiles = @($launchVaultPath, $personVaultPath) | Where-Object { $_ }
    Write-JsonFile -Path $workspacePath -Value $workspace
}

Write-Output "Applied Calendula-20K graph profile '$Profile' to $vault"
