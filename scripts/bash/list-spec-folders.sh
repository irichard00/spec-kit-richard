#!/usr/bin/env bash
# Lists spec folders available for implementation
# Excludes folders marked as complete (DONE-) or failed (FAILED-)

set -e

JSON_MODE=false
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h)
            echo "Usage: $0 [--json]"
            echo ""
            echo "Lists spec folders available for implementation."
            echo "Excludes folders with DONE- or FAILED- prefix."
            echo ""
            echo "Options:"
            echo "  --json    Output in JSON format"
            echo "  --help    Show this help message"
            exit 0
            ;;
    esac
done

# Find repository root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

SPECS_DIR="$REPO_ROOT/specs"

folders=()
if [ -d "$SPECS_DIR" ]; then
    for dir in "$SPECS_DIR"/[0-9][0-9][0-9]-*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        # Skip folders already marked as complete or failed (prefix-based)
        [[ "$dirname" == DONE-* ]] && continue
        [[ "$dirname" == FAILED-* ]] && continue
        folders+=("$dirname")
    done
fi

# Sort folders by numeric prefix
IFS=$'\n' sorted_folders=($(sort <<<"${folders[*]}")); unset IFS

if $JSON_MODE; then
    printf '{"SPECS_DIR":"%s","FOLDERS":[' "$SPECS_DIR"
    first=true
    for f in "${sorted_folders[@]}"; do
        $first || printf ','
        printf '"%s"' "$f"
        first=false
    done
    printf ']}\n'
else
    if [ ${#sorted_folders[@]} -eq 0 ]; then
        echo "No spec folders available for implementation."
    else
        echo "Available spec folders:"
        for i in "${!sorted_folders[@]}"; do
            printf "  %d. %s\n" "$((i+1))" "${sorted_folders[$i]}"
        done
    fi
fi
