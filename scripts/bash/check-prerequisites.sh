#!/usr/bin/env bash

# Consolidated prerequisite checking script
#
# This script provides unified prerequisite checking for Spec-Driven Development workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: ./check-prerequisites.sh [OPTIONS] [FOLDER_NAME]
#
# OPTIONS:
#   --json              Output in JSON format
#   --require-tasks     Require tasks.md to exist (for implementation phase)
#   --include-tasks     Include tasks.md in AVAILABLE_DOCS list
#   --paths-only        Only output path variables (no validation)
#   --list-folders      List available spec folders and exit
#   --help, -h          Show help message
#
# FOLDER_NAME:
#   The name of the spec folder (e.g., "001-user-auth")
#   If not provided and not in --list-folders mode, returns available folders
#
# OUTPUTS:
#   JSON mode: {"FEATURE_DIR":"...", "AVAILABLE_DOCS":["..."]}
#   Text mode: FEATURE_DIR:... \n AVAILABLE_DOCS: \n ✓/✗ file.md
#   Paths only: REPO_ROOT: ... \n FEATURE_DIR: ... etc.
#   List folders: Returns available spec folders

set -e

# Parse command line arguments
JSON_MODE=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
PATHS_ONLY=false
LIST_FOLDERS=false
FOLDER_NAME=""

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --require-tasks)
            REQUIRE_TASKS=true
            ;;
        --include-tasks)
            INCLUDE_TASKS=true
            ;;
        --paths-only)
            PATHS_ONLY=true
            ;;
        --list-folders)
            LIST_FOLDERS=true
            ;;
        --help|-h)
            cat << 'EOF'
Usage: check-prerequisites.sh [OPTIONS] [FOLDER_NAME]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  --json              Output in JSON format
  --require-tasks     Require tasks.md to exist (for implementation phase)
  --include-tasks     Include tasks.md in AVAILABLE_DOCS list
  --paths-only        Only output path variables (no prerequisite validation)
  --list-folders      List available spec folders and exit
  --help, -h          Show this help message

FOLDER_NAME:
  The name of the spec folder (e.g., "001-user-auth")
  If not provided, returns available folders for user selection

EXAMPLES:
  # List available spec folders
  ./check-prerequisites.sh --list-folders --json

  # Check prerequisites for a specific folder
  ./check-prerequisites.sh --json 001-user-auth

  # Get feature paths only (no validation)
  ./check-prerequisites.sh --paths-only 001-user-auth

EOF
            exit 0
            ;;
        -*)
            echo "ERROR: Unknown option '$arg'. Use --help for usage information." >&2
            exit 1
            ;;
        *)
            # Non-option argument is the folder name
            if [[ -z "$FOLDER_NAME" ]]; then
                FOLDER_NAME="$arg"
            else
                echo "ERROR: Multiple folder names provided. Only one allowed." >&2
                exit 1
            fi
            ;;
    esac
done

# Source common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# If --list-folders mode, list available folders and exit
if $LIST_FOLDERS; then
    if $JSON_MODE; then
        printf '{"AVAILABLE_FOLDERS":%s}\n' "$(list_spec_folders)"
    else
        echo "Available spec folders:"
        list_spec_folders_text
    fi
    exit 0
fi

# If no folder provided, return available folders
if [[ -z "$FOLDER_NAME" ]]; then
    if $JSON_MODE; then
        printf '{"FEATURE_DIR":"","AVAILABLE_FOLDERS":%s,"ERROR":"No folder specified. Please provide a spec folder name."}\n' "$(list_spec_folders)"
    else
        echo "ERROR: No spec folder specified." >&2
        echo "Available spec folders:" >&2
        list_spec_folders_text >&2
        echo "" >&2
        echo "Usage: $0 [OPTIONS] FOLDER_NAME" >&2
    fi
    exit 1
fi

# Validate the folder exists
if ! validate_spec_folder "$FOLDER_NAME"; then
    if $JSON_MODE; then
        printf '{"FEATURE_DIR":"","AVAILABLE_FOLDERS":%s,"ERROR":"Folder not found: %s"}\n' "$(list_spec_folders)" "$FOLDER_NAME"
    else
        echo "ERROR: Spec folder not found: $FOLDER_NAME" >&2
        echo "Available spec folders:" >&2
        list_spec_folders_text >&2
    fi
    exit 1
fi

# Get feature paths for the specified folder
eval $(get_feature_paths "$FOLDER_NAME")

# If paths-only mode, output paths and exit (support JSON + paths-only combined)
if $PATHS_ONLY; then
    if $JSON_MODE; then
        # Minimal JSON paths payload (no validation performed)
        printf '{"REPO_ROOT":"%s","FEATURE_DIR":"%s","FEATURE_SPEC":"%s","IMPL_PLAN":"%s","TASKS":"%s"}\n' \
            "$REPO_ROOT" "$FEATURE_DIR" "$FEATURE_SPEC" "$IMPL_PLAN" "$TASKS"
    else
        echo "REPO_ROOT: $REPO_ROOT"
        echo "FEATURE_DIR: $FEATURE_DIR"
        echo "FEATURE_SPEC: $FEATURE_SPEC"
        echo "IMPL_PLAN: $IMPL_PLAN"
        echo "TASKS: $TASKS"
    fi
    exit 0
fi

# Validate required directories and files
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "ERROR: Feature directory not found: $FEATURE_DIR" >&2
    echo "Run /rr.specify first to create the feature structure." >&2
    exit 1
fi

if [[ ! -f "$IMPL_PLAN" ]]; then
    echo "ERROR: plan.md not found in $FEATURE_DIR" >&2
    echo "Run /rr.plan first to create the implementation plan." >&2
    exit 1
fi

# Check for tasks.md if required
if $REQUIRE_TASKS && [[ ! -f "$TASKS" ]]; then
    echo "ERROR: tasks.md not found in $FEATURE_DIR" >&2
    echo "Run /rr.tasks first to create the task list." >&2
    exit 1
fi

# Build list of available documents
docs=()

# Always check these optional docs
[[ -f "$RESEARCH" ]] && docs+=("research.md")
[[ -f "$DATA_MODEL" ]] && docs+=("data-model.md")

# Check contracts directory (only if it exists and has files)
if [[ -d "$CONTRACTS_DIR" ]] && [[ -n "$(ls -A "$CONTRACTS_DIR" 2>/dev/null)" ]]; then
    docs+=("contracts/")
fi

[[ -f "$QUICKSTART" ]] && docs+=("quickstart.md")

# Include tasks.md if requested and it exists
if $INCLUDE_TASKS && [[ -f "$TASKS" ]]; then
    docs+=("tasks.md")
fi

# Output results
if $JSON_MODE; then
    # Build JSON array of documents
    if [[ ${#docs[@]} -eq 0 ]]; then
        json_docs="[]"
    else
        json_docs=$(printf '"%s",' "${docs[@]}")
        json_docs="[${json_docs%,}]"
    fi
    
    printf '{"FEATURE_DIR":"%s","AVAILABLE_DOCS":%s}\n' "$FEATURE_DIR" "$json_docs"
else
    # Text output
    echo "FEATURE_DIR:$FEATURE_DIR"
    echo "AVAILABLE_DOCS:"
    
    # Show status of each potential document
    check_file "$RESEARCH" "research.md"
    check_file "$DATA_MODEL" "data-model.md"
    check_dir "$CONTRACTS_DIR" "contracts/"
    check_file "$QUICKSTART" "quickstart.md"
    
    if $INCLUDE_TASKS; then
        check_file "$TASKS" "tasks.md"
    fi
fi
