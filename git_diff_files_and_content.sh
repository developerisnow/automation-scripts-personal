#!/bin/bash

# Get current date and time in the required format
DATETIME=$(date +"%Y%m%d_%H%M")
# Get current commit hash
COMMIT_HASH=$(git rev-parse HEAD)
OUTPUT_DIR="_files/git"
OUTPUT_FILE="${OUTPUT_DIR}/git-diff-${DATETIME}-${COMMIT_HASH:0:7}.md"

# Function to create output directory if it doesn't exist
create_output_dir() {
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
    fi
}

# Function to generate git status and diff output
generate_output() {
    echo "\`\`\`bash"
    echo "=== Current Git Status ==="
    git status
    echo -e "\n=== Git Diff ==="
    git diff
    echo "\`\`\`"
}

# Check if --store option is provided
if [ "$1" = "--store" ]; then
    create_output_dir
    # Generate output and store it in file
    generate_output > "$OUTPUT_FILE"
    echo "Git diff has been stored in: $OUTPUT_FILE"
else
    # Just display the output
    generate_output
fi

exit 0