#!/usr/bin/env bash

set -e

# Parse command line arguments
JSON_MODE=false
LIST_FOLDERS=false
FOLDER_NAME=""

for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        --list-folders)
            LIST_FOLDERS=true
            ;;
        --help|-h)
            cat << 'EOF'
Usage: setup-plan.sh [OPTIONS] [FOLDER_NAME]

Setup planning phase for a spec folder.

OPTIONS:
  --json          Output results in JSON format
  --list-folders  List available spec folders and exit
  --help, -h      Show this help message

FOLDER_NAME:
  The name of the spec folder (e.g., "001-user-auth")
  Required unless using --list-folders

EXAMPLES:
  # List available spec folders
  ./setup-plan.sh --list-folders --json

  # Setup planning for a specific folder
  ./setup-plan.sh --json 001-user-auth

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

# Get script directory and load common functions
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

# If no folder provided, return available folders with error
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

# Get all paths and variables from common functions
eval $(get_feature_paths "$FOLDER_NAME")

# Ensure the feature directory exists
mkdir -p "$FEATURE_DIR"

# Copy plan template if it exists
TEMPLATE="$REPO_ROOT/.specify/templates/plan-template.md"
if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$IMPL_PLAN"
    echo "Copied plan template to $IMPL_PLAN" >&2
else
    echo "Warning: Plan template not found at $TEMPLATE" >&2
    # Create a basic plan file if template doesn't exist
    touch "$IMPL_PLAN"
fi

# Output results
if $JSON_MODE; then
    printf '{"FEATURE_SPEC":"%s","IMPL_PLAN":"%s","SPECS_DIR":"%s","HAS_GIT":"%s"}\n' \
        "$FEATURE_SPEC" "$IMPL_PLAN" "$FEATURE_DIR" "$HAS_GIT"
else
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "IMPL_PLAN: $IMPL_PLAN"
    echo "SPECS_DIR: $FEATURE_DIR"
    echo "HAS_GIT: $HAS_GIT"
fi

