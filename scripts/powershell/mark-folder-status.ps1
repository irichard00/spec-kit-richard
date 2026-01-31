# Marks a spec folder as complete or failed by renaming with status prefix

param(
    [string]$Folder,
    [ValidateSet("DONE", "FAILED")]
    [string]$Status,
    [switch]$Json,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: mark-folder-status.ps1 -Folder <folder-name> -Status <DONE|FAILED> [-Json]"
    Write-Host ""
    Write-Host "Marks a spec folder as complete or failed by adding a status prefix."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Folder <name>   The spec folder name (required)"
    Write-Host "  -Status <status> DONE or FAILED (required)"
    Write-Host "  -Json            Output in JSON format"
    Write-Host "  -Help            Show this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  mark-folder-status.ps1 -Folder 001-user-auth -Status DONE"
    Write-Host "  Result: specs/001-user-auth/ -> specs/DONE-001-user-auth/"
    exit 0
}

if (-not $Folder -or -not $Status) {
    Write-Error "ERROR: -Folder and -Status are required"
    Write-Host "Usage: mark-folder-status.ps1 -Folder <folder-name> -Status <DONE|FAILED> [-Json]"
    exit 1
}

# Find repository root
$RepoRoot = $null
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
} catch {}

if (-not $RepoRoot) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
}

$OldPath = Join-Path $RepoRoot "specs" $Folder
$NewFolderName = "${Status}-${Folder}"
$NewPath = Join-Path $RepoRoot "specs" $NewFolderName

# Validate folder exists
if (-not (Test-Path $OldPath)) {
    Write-Error "ERROR: Folder not found: $OldPath"
    exit 1
}

# Check if target already exists
if (Test-Path $NewPath) {
    Write-Error "ERROR: Target folder already exists: $NewPath"
    exit 1
}

# Rename the folder
Move-Item -Path $OldPath -Destination $NewPath

if ($Json) {
    $Output = @{
        OLD_PATH = $OldPath
        NEW_PATH = $NewPath
        OLD_NAME = $Folder
        NEW_NAME = $NewFolderName
        STATUS = $Status
    }
    $Output | ConvertTo-Json -Compress
} else {
    Write-Host "Marked $Folder as $Status"
    Write-Host "Renamed: $Folder -> $NewFolderName"
}
