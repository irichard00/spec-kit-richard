#!/usr/bin/env bash
# Marks a spec folder as complete or failed by renaming with status prefix

set -e

FOLDER_NAME=""
STATUS=""
JSON_MODE=false

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
        --status)
            i=$((i + 1))
            if [ $i -gt $# ]; then
                echo "ERROR: --status requires a value" >&2
                exit 1
            fi
            STATUS="${!i}"
            ;;
        --help|-h)
            echo "Usage: $0 --folder <folder-name> --status <DONE|FAILED> [--json]"
            echo ""
            echo "Marks a spec folder as complete or failed by adding a status prefix."
            echo ""
            echo "Options:"
            echo "  --folder <name>  The spec folder name (required)"
            echo "  --status <status> DONE or FAILED (required)"
            echo "  --json           Output in JSON format"
            echo "  --help           Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --folder 001-user-auth --status DONE"
            echo "  Result: specs/001-user-auth/ -> specs/DONE-001-user-auth/"
            exit 0
            ;;
    esac
    i=$((i + 1))
done

if [ -z "$FOLDER_NAME" ] || [ -z "$STATUS" ]; then
    echo "ERROR: --folder and --status are required" >&2
    echo "Usage: $0 --folder <folder-name> --status <DONE|FAILED> [--json]" >&2
    exit 1
fi

# Validate status value
if [[ "$STATUS" != "DONE" && "$STATUS" != "FAILED" ]]; then
    echo "ERROR: --status must be DONE or FAILED" >&2
    exit 1
fi

# Find repository root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

OLD_PATH="$REPO_ROOT/specs/$FOLDER_NAME"
NEW_FOLDER_NAME="${STATUS}-${FOLDER_NAME}"
NEW_PATH="$REPO_ROOT/specs/$NEW_FOLDER_NAME"

# Validate folder exists
if [ ! -d "$OLD_PATH" ]; then
    echo "ERROR: Folder not found: $OLD_PATH" >&2
    exit 1
fi

# Check if target already exists
if [ -d "$NEW_PATH" ]; then
    echo "ERROR: Target folder already exists: $NEW_PATH" >&2
    exit 1
fi

# Rename the folder
mv "$OLD_PATH" "$NEW_PATH"

if $JSON_MODE; then
    printf '{"OLD_PATH":"%s","NEW_PATH":"%s","OLD_NAME":"%s","NEW_NAME":"%s","STATUS":"%s"}\n' \
        "$OLD_PATH" "$NEW_PATH" "$FOLDER_NAME" "$NEW_FOLDER_NAME" "$STATUS"
else
    echo "Marked $FOLDER_NAME as $STATUS"
    echo "Renamed: $FOLDER_NAME -> $NEW_FOLDER_NAME"
fi
