#!/usr/bin/env pwsh
# Setup implementation plan for a feature

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$ListFolders,
    [switch]$Help,
    [Parameter(Position=0)]
    [string]$FolderName
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: setup-plan.ps1 [OPTIONS] [FOLDER_NAME]

Setup planning phase for a spec folder.

OPTIONS:
  -Json          Output results in JSON format
  -ListFolders   List available spec folders and exit
  -Help, -h      Show this help message

FOLDER_NAME:
  The name of the spec folder (e.g., "001-user-auth")
  Required unless using -ListFolders

EXAMPLES:
  # List available spec folders
  .\setup-plan.ps1 -ListFolders -Json

  # Setup planning for a specific folder
  .\setup-plan.ps1 -Json 001-user-auth

"@
    exit 0
}

# Load common functions
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
        Write-Output "Usage: .\setup-plan.ps1 [OPTIONS] FOLDER_NAME"
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

# Get all paths and variables from common functions
$paths = Get-FeaturePathsEnv -FolderName $FolderName

# Ensure the feature directory exists
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# Copy plan template if it exists, otherwise note it or create empty file
$template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template.md'
if (Test-Path $template) {
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Host "Copied plan template to $($paths.IMPL_PLAN)" -ForegroundColor Gray
} else {
    Write-Warning "Plan template not found at $template"
    # Create a basic plan file if template doesn't exist
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

# Output results
if ($Json) {
    $result = [PSCustomObject]@{
        FEATURE_SPEC = $paths.FEATURE_SPEC
        IMPL_PLAN = $paths.IMPL_PLAN
        SPECS_DIR = $paths.FEATURE_DIR
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
}
