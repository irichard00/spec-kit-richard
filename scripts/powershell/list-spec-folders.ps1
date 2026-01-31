# Lists spec folders available for implementation
# Excludes folders marked as complete (DONE-) or failed (FAILED-)

param(
    [switch]$Json,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: list-spec-folders.ps1 [-Json]"
    Write-Host ""
    Write-Host "Lists spec folders available for implementation."
    Write-Host "Excludes folders with DONE- or FAILED- prefix."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Json    Output in JSON format"
    Write-Host "  -Help    Show this help message"
    exit 0
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

$SpecsDir = Join-Path $RepoRoot "specs"

$Folders = @()
if (Test-Path $SpecsDir) {
    Get-ChildItem -Path $SpecsDir -Directory | Where-Object {
        $_.Name -match '^\d{3}-' -and
        $_.Name -notmatch '^DONE-' -and
        $_.Name -notmatch '^FAILED-'
    } | Sort-Object Name | ForEach-Object {
        $Folders += $_.Name
    }
}

if ($Json) {
    $Output = @{
        SPECS_DIR = $SpecsDir
        FOLDERS = $Folders
    }
    $Output | ConvertTo-Json -Compress
} else {
    if ($Folders.Count -eq 0) {
        Write-Host "No spec folders available for implementation."
    } else {
        Write-Host "Available spec folders:"
        for ($i = 0; $i -lt $Folders.Count; $i++) {
            Write-Host ("  {0}. {1}" -f ($i + 1), $Folders[$i])
        }
    }
}
