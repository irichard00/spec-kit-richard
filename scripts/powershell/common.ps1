#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh

function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }

    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

function Test-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# List all available spec folders in specs/ directory
# Returns array of folder names
function Get-SpecFolders {
    $repoRoot = Get-RepoRoot
    $specsDir = Join-Path $repoRoot "specs"
    $folders = @()

    if (Test-Path $specsDir) {
        Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
            if ($_.Name -match '^\d{3}-') {
                $folders += $_.Name
            }
        }
    }

    return $folders
}

# List spec folders as JSON array
function Get-SpecFoldersJson {
    $folders = Get-SpecFolders

    if ($folders.Count -eq 0) {
        return "[]"
    }

    $jsonItems = $folders | ForEach-Object { "`"$_`"" }
    return "[" + ($jsonItems -join ",") + "]"
}

# Validate that a spec folder exists
function Test-SpecFolder {
    param([string]$FolderName)

    $repoRoot = Get-RepoRoot
    $targetDir = Join-Path $repoRoot "specs/$FolderName"

    return (Test-Path -Path $targetDir -PathType Container)
}

# Get feature paths for a specific folder name
# If no folder provided, returns empty paths with available folders list
function Get-FeaturePathsEnv {
    param([string]$FolderName = "")

    $repoRoot = Get-RepoRoot
    $hasGit = Test-HasGit

    # If no folder specified, return empty paths with available folders
    if ([string]::IsNullOrEmpty($FolderName)) {
        $availableFolders = Get-SpecFoldersJson

        return [PSCustomObject]@{
            REPO_ROOT         = $repoRoot
            HAS_GIT           = $hasGit
            FEATURE_DIR       = ""
            FEATURE_SPEC      = ""
            IMPL_PLAN         = ""
            TASKS             = ""
            RESEARCH          = ""
            DATA_MODEL        = ""
            QUICKSTART        = ""
            CONTRACTS_DIR     = ""
            AVAILABLE_FOLDERS = $availableFolders
        }
    }

    $featureDir = Join-Path $repoRoot "specs/$FolderName"

    return [PSCustomObject]@{
        REPO_ROOT     = $repoRoot
        HAS_GIT       = $hasGit
        FEATURE_DIR   = $featureDir
        FEATURE_SPEC  = Join-Path $featureDir 'spec.md'
        IMPL_PLAN     = Join-Path $featureDir 'plan.md'
        TASKS         = Join-Path $featureDir 'tasks.md'
        RESEARCH      = Join-Path $featureDir 'research.md'
        DATA_MODEL    = Join-Path $featureDir 'data-model.md'
        QUICKSTART    = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR = Join-Path $featureDir 'contracts'
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

