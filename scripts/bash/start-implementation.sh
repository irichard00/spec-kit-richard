#!/usr/bin/env bash
# Creates a branch for the selected spec folder and validates prerequisites

set -e

FOLDER_NAME=""
JSON_MODE=false
FROM_CURRENT_BRANCH=false

# Parse arguments
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --folder)
            i=$((i + 1))
            if [ $i -gt $# ]; then
                echo "ERROR: --folder requires a value" >&2
                exit 1
            fi
            FOLDER_NAME="${!i}"
            ;;
        --from-current-branch)
            FROM_CURRENT_BRANCH=true
            ;;
        --help|-h)
            echo "Usage: $0 --folder <folder-name> [--json]"
            echo ""
            echo "Creates a git branch for the selected spec folder."
            echo ""
            echo "Options:"
            echo "  --folder <name>      The spec folder name (required)"
            echo "  --json               Output in JSON format"
            echo "  --from-current-branch Create branch from current HEAD (stacking)"
            echo "  --help               Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --folder 001-user-auth --json"
            exit 0
            ;;
    esac
    i=$((i + 1))
done

if [ -z "$FOLDER_NAME" ]; then
    echo "ERROR: --folder argument required" >&2
    echo "Usage: $0 --folder <folder-name> [--json]" >&2
    exit 1
fi

# Find repository root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    HAS_GIT=false
fi

FEATURE_DIR="$REPO_ROOT/specs/$FOLDER_NAME"

# Validate folder exists
if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Spec folder not found: $FEATURE_DIR" >&2
    exit 1
fi

# Validate required files exist
if [ ! -f "$FEATURE_DIR/tasks.md" ]; then
    echo "ERROR: tasks.md not found in $FOLDER_NAME. Run /rr.tasks first." >&2
    exit 1
fi

# Create and checkout branch with same name as folder
BRANCH_NAME="$FOLDER_NAME"

if [ "$HAS_GIT" = true ]; then
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
        # Branch exists, just checkout
        git checkout "$BRANCH_NAME"
        >&2 echo "[implement] Switched to existing branch: $BRANCH_NAME"
    else
        # Determine base branch
        if [ "$FROM_CURRENT_BRANCH" = true ]; then
            BASE_REF="HEAD"
            BASE_MSG="current branch"
        else
            # Default to main if it exists, otherwise master
            if git show-ref --verify --quiet refs/heads/main; then
                BASE_REF="main"
            else
                BASE_REF="master"
            fi
            BASE_MSG="$BASE_REF"
        fi

        # Create new branch
        git checkout -b "$BRANCH_NAME" "$BASE_REF"
        >&2 echo "[implement] Created branch $BRANCH_NAME from $BASE_MSG"
    fi
else
    >&2 echo "[implement] Warning: Git repository not detected; skipped branch creation for $BRANCH_NAME"
fi

if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","FEATURE_DIR":"%s","HAS_GIT":%s}\n' "$BRANCH_NAME" "$FEATURE_DIR" "$HAS_GIT"
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "FEATURE_DIR: $FEATURE_DIR"
fi
