#!/bin/bash

# Get the root directory from argument or use current directory
ROOT_DIR="${1:-.}"
# Clean up the folder name for the output file
FOLDER_NAME=$(basename "$(cd "$ROOT_DIR" && pwd)")
OUTPUT_FILE="tree_${FOLDER_NAME}.md"

# Function to create tree structure
create_tree() {
    local dir="$1"
    local prefix="$2"
    
    # Modified directory listing approach
    for d in "$dir"/*/; do
        # Skip if no directories found
        [ -d "$d" ] || continue
        
        # Get directory name
        local name=$(basename "$d")
        
        # Print directory name with prefix
        echo "${prefix}- ${name}"
        
        # Check if it's a git repository
        if [ ! -d "$d/.git" ]; then
            # If not a git repo, recurse into subdirectories
            create_tree "$d" "  ${prefix}"
        fi
    done
}

# Create the markdown file with a header
echo "# Directory Tree for ${FOLDER_NAME}" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Generate the tree and append to the file
create_tree "$ROOT_DIR" "" >> "$OUTPUT_FILE"

echo "Tree structure has been saved to $OUTPUT_FILE"