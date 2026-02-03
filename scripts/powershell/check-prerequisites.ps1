#!/usr/bin/env pwsh

# Consolidated prerequisite checking script (PowerShell)
#
# This script provides unified prerequisite checking for Spec-Driven Development workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: ./check-prerequisites.ps1 [OPTIONS] [FOLDER_NAME]
#
# OPTIONS:
#   -Json               Output in JSON format
#   -RequireTasks       Require tasks.md to exist (for implementation phase)
#   -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
#   -PathsOnly          Only output path variables (no validation)
#   -ListFolders        List available spec folders and exit
#   -Help, -h           Show help message
#
# FOLDER_NAME:
#   The name of the spec folder (e.g., "001-user-auth")
#   If not provided and not in -ListFolders mode, returns available folders

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$PathsOnly,
    [switch]$ListFolders,
    [switch]$Help,
    [Parameter(Position=0)]
    [string]$FolderName
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: check-prerequisites.ps1 [OPTIONS] [FOLDER_NAME]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  -Json               Output in JSON format
  -RequireTasks       Require tasks.md to exist (for implementation phase)
  -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
  -PathsOnly          Only output path variables (no prerequisite validation)
  -ListFolders        List available spec folders and exit
  -Help, -h           Show this help message

FOLDER_NAME:
  The name of the spec folder (e.g., "001-user-auth")
  If not provided, returns available folders for user selection

EXAMPLES:
  # List available spec folders
  .\check-prerequisites.ps1 -ListFolders -Json

  # Check prerequisites for a specific folder
  .\check-prerequisites.ps1 -Json 001-user-auth

  # Get feature paths only (no validation)
  .\check-prerequisites.ps1 -PathsOnly 001-user-auth

"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# If -ListFolders mode, list available folders and exit
if ($ListFolders) {
    if ($Json) {
        [PSCustomObject]@{
            AVAILABLE_FOLDERS = (Get-SpecFolders)
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "Available spec folders:"
        Get-SpecFolders | ForEach-Object { Write-Output "  $_" }
    }
    exit 0
}

# If no folder provided, return available folders with error
if ([string]::IsNullOrEmpty($FolderName)) {
    $folders = Get-SpecFolders
    if ($Json) {
        [PSCustomObject]@{
            FEATURE_DIR = ""
            AVAILABLE_FOLDERS = $folders
            ERROR = "No folder specified. Please provide a spec folder name."
        } | ConvertTo-Json -Compress
    } else {
        Write-Error "No spec folder specified."
        Write-Output "Available spec folders:"
        $folders | ForEach-Object { Write-Output "  $_" }
        Write-Output ""
        Write-Output "Usage: .\check-prerequisites.ps1 [OPTIONS] FOLDER_NAME"
    }
    exit 1
}

# Validate the folder exists
if (-not (Test-SpecFolder -FolderName $FolderName)) {
    $folders = Get-SpecFolders
    if ($Json) {
        [PSCustomObject]@{
            FEATURE_DIR = ""
            AVAILABLE_FOLDERS = $folders
            ERROR = "Folder not found: $FolderName"
        } | ConvertTo-Json -Compress
    } else {
        Write-Error "Spec folder not found: $FolderName"
        Write-Output "Available spec folders:"
        $folders | ForEach-Object { Write-Output "  $_" }
    }
    exit 1
}

# Get feature paths for the specified folder
$paths = Get-FeaturePathsEnv -FolderName $FolderName

# If paths-only mode, output paths and exit (support combined -Json -PathsOnly)
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT    = $paths.REPO_ROOT
            FEATURE_DIR  = $paths.FEATURE_DIR
            FEATURE_SPEC = $paths.FEATURE_SPEC
            IMPL_PLAN    = $paths.IMPL_PLAN
            TASKS        = $paths.TASKS
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# Validate required directories and files
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $($paths.FEATURE_DIR)"
    Write-Output "Run /rr.specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "ERROR: plan.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /rr.plan first to create the implementation plan."
    exit 1
}

# Check for tasks.md if required
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "ERROR: tasks.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /rr.tasks first to create the task list."
    exit 1
}

# Build list of available documents
$docs = @()

# Always check these optional docs
if (Test-Path $paths.RESEARCH) { $docs += 'research.md' }
if (Test-Path $paths.DATA_MODEL) { $docs += 'data-model.md' }

# Check contracts directory (only if it exists and has files)
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem -Path $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    $docs += 'contracts/'
}

if (Test-Path $paths.QUICKSTART) { $docs += 'quickstart.md' }

# Include tasks.md if requested and it exists
if ($IncludeTasks -and (Test-Path $paths.TASKS)) {
    $docs += 'tasks.md'
}

# Output results
if ($Json) {
    # JSON output
    [PSCustomObject]@{
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs
    } | ConvertTo-Json -Compress
} else {
    # Text output
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"

    # Show status of each potential document
    Test-FileExists -Path $paths.RESEARCH -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths.QUICKSTART -Description 'quickstart.md' | Out-Null

    if ($IncludeTasks) {
        Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    }
}
