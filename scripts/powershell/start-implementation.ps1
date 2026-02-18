# Creates a branch for the selected spec folder and validates prerequisites

param(
    [string]$Folder,
    [switch]$Json,
    [switch]$Help,
    [switch]$FromCurrentBranch
)

if ($Help) {
    Write-Host "Usage: start-implementation.ps1 -Folder <folder-name> [-Json]"
    Write-Host ""
    Write-Host "Creates a git branch for the selected spec folder."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Folder <name>  The spec folder name (required)"
    Write-Host "  -Json           Output in JSON format"
    Write-Host "  -FromCurrentBranch Create branch from current HEAD (stacking)"
    Write-Host "  -Help           Show this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  start-implementation.ps1 -Folder 001-user-auth -Json"
    exit 0
}

if (-not $Folder) {
    Write-Error "ERROR: -Folder argument required"
    Write-Host "Usage: start-implementation.ps1 -Folder <folder-name> [-Json]"
    exit 1
}

# Find repository root
$RepoRoot = $null
$HasGit = $false
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if ($RepoRoot) { $HasGit = $true }
} catch {}

if (-not $RepoRoot) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
}

$FeatureDir = Join-Path $RepoRoot "specs" $Folder

# Validate folder exists
if (-not (Test-Path $FeatureDir)) {
    Write-Error "ERROR: Spec folder not found: $FeatureDir"
    exit 1
}

# Validate required files exist
$TasksFile = Join-Path $FeatureDir "tasks.md"
if (-not (Test-Path $TasksFile)) {
    Write-Error "ERROR: tasks.md not found in $Folder. Run /rr.tasks first."
    exit 1
}

# Create and checkout branch with same name as folder
$BranchName = $Folder

if ($HasGit) {
    # Check if branch already exists
    $BranchExists = git show-ref --verify --quiet "refs/heads/$BranchName" 2>$null
    if ($LASTEXITCODE -eq 0) {
        # Branch exists, just checkout
        git checkout $BranchName
        Write-Host "[implement] Switched to existing branch: $BranchName" -ForegroundColor Yellow
    } else {
    } else {
        # Determine base branch
        $BaseRef = ""
        $BaseMsg = ""
        
        if ($FromCurrentBranch) {
            $BaseRef = "HEAD"
            $BaseMsg = "current branch"
        } else {
            # Default to main if it exists, otherwise master
            $MainExists = git show-ref --verify --quiet refs/heads/main
            if ($LASTEXITCODE -eq 0) {
                $BaseRef = "main"
            } else {
                $BaseRef = "master"
            }
            $BaseMsg = $BaseRef
        }

        # Create new branch
        git checkout -b $BranchName $BaseRef
        Write-Host "[implement] Created branch $BranchName from $BaseMsg" -ForegroundColor Green
    }
} else {
    Write-Host "[implement] Warning: Git repository not detected; skipped branch creation for $BranchName" -ForegroundColor Yellow
}

if ($Json) {
    $Output = @{
        BRANCH_NAME = $BranchName
        FEATURE_DIR = $FeatureDir
        HAS_GIT = $HasGit
    }
    $Output | ConvertTo-Json -Compress
} else {
    Write-Host "BRANCH_NAME: $BranchName"
    Write-Host "FEATURE_DIR: $FeatureDir"
}
