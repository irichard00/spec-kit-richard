#!/usr/bin/env bash
# Common functions and variables for all scripts

# Get repository root, with fallback for non-git repositories
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fall back to script location for non-git repos
        local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

# List all available spec folders in specs/ directory
# Returns JSON array of folder names
list_spec_folders() {
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"
    local folders=()

    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                # Only include folders matching NNN-* pattern
                if [[ "$dirname" =~ ^[0-9]{3}- ]]; then
                    folders+=("$dirname")
                fi
            fi
        done
    fi

    # Output as JSON array
    if [[ ${#folders[@]} -eq 0 ]]; then
        echo "[]"
    else
        local json_array=$(printf '"%s",' "${folders[@]}")
        echo "[${json_array%,}]"
    fi
}

# List spec folders in human-readable format (one per line)
list_spec_folders_text() {
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^[0-9]{3}- ]]; then
                    echo "$dirname"
                fi
            fi
        done
    fi
}

# Validate that a spec folder exists
# Returns 0 if valid, 1 if not
validate_spec_folder() {
    local folder_name="$1"
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"
    local target_dir="$specs_dir/$folder_name"

    if [[ -d "$target_dir" ]]; then
        return 0
    else
        return 1
    fi
}

# Get feature paths for a specific folder name
# Usage: eval $(get_feature_paths "001-feature-name")
# If no folder provided, outputs FEATURE_DIR as empty and AVAILABLE_FOLDERS list
get_feature_paths() {
    local folder_name="${1:-}"
    local repo_root=$(get_repo_root)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # If no folder specified, return empty paths with available folders
    if [[ -z "$folder_name" ]]; then
        local available_folders=$(list_spec_folders)
        cat <<EOF
REPO_ROOT='$repo_root'
HAS_GIT='$has_git_repo'
FEATURE_DIR=''
FEATURE_SPEC=''
IMPL_PLAN=''
TASKS=''
RESEARCH=''
DATA_MODEL=''
QUICKSTART=''
CONTRACTS_DIR=''
AVAILABLE_FOLDERS='$available_folders'
EOF
        return
    fi

    local feature_dir="$repo_root/specs/$folder_name"

    cat <<EOF
REPO_ROOT='$repo_root'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

