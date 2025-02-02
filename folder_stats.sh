#!/bin/bash
#
# folder_stats.sh: Display a directory tree with file size (KB) and line counts.
#
# Usage: ./folder_stats.sh <directory>

# Ensure a directory is provided
if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") <directory>"
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: $TARGET_DIR is not a directory."
    exit 1
fi

# Recursive function to print directory tree stats.
function print_tree {
    local dir="$1"
    local indent="${2:-}"
    for entry in "$dir"/*; do
        if [ -d "$entry" ]; then
            # For directories, get total size in KB (recursive sum)
            local dsize=$(du -sk "$entry" 2>/dev/null | cut -f1)
            echo "${indent}$(basename "$entry")/ [${dsize} KB]"
            print_tree "$entry" "    $indent"
        elif [ -f "$entry" ]; then
            # For files, get file size in KB and count the number of lines.
            local fsize=$(du -k "$entry" 2>/dev/null | cut -f1)
            local lines=$(wc -l < "$entry" 2>/dev/null)
            echo "${indent}$(basename "$entry") [${fsize} KB, ${lines} lines]"
        fi
    done
}

echo "Directory Stats for: $TARGET_DIR"
print_tree "$TARGET_DIR"