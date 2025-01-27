#!/bin/bash

# Get current folder name and timestamp
CURRENT_FOLDER=$(basename "$(pwd)")
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M")

# Function to count files by extension
count_skipped_files() {
    local dir="$1"
    echo "### Skipped Files Summary:" > "/tmp/skipped_summary.txt"
    echo "" >> "/tmp/skipped_summary.txt"
    
    # Images
    find "$dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" -o -name "*.ico" \) | wc -l | xargs -I {} echo "- Images (png|jpg|jpeg|gif|svg|ico): {} files" >> "/tmp/skipped_summary.txt"
    
    # Archives
    find "$dir" -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" -o -name "*.rar" \) | wc -l | xargs -I {} echo "- Archives (zip|tar|gz|rar): {} files" >> "/tmp/skipped_summary.txt"
    
    # Build artifacts
    find "$dir" -type f \( -name "*.pyc" -o -name "*.pyo" -o -name "*.pyd" -o -name "*.class" \) | wc -l | xargs -I {} echo "- Build artifacts (pyc|pyo|pyd|class): {} files" >> "/tmp/skipped_summary.txt"
    
    # Logs and databases
    find "$dir" -type f \( -name "*.log" -o -name "*.sqlite" -o -name "*.db" \) | wc -l | xargs -I {} echo "- Logs and databases (log|sqlite|db): {} files" >> "/tmp/skipped_summary.txt"
    
    echo "" >> "/tmp/skipped_summary.txt"
}

# Define ignore patterns for tree command
IGNORE_PATTERNS=(
    -I "node_modules|__pycache__|target|venv|.venv|dist|build|.git|coverage|.next"  # Folders
    -I "*.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico"  # Images
    -I "*.zip|*.tar|*.gz|*.rar"  # Archives
    -I "*.pyc|*.pyo|*.pyd|*.class"  # Build artifacts
    -I "*.log|*.sqlite|*.db"  # Logs and databases
    -I "*.min.js|*.min.css"  # Minified files
    -I ".DS_Store|Thumbs.db"  # System files
)

OUTPUT_FILE="treeAllFiles_${CURRENT_FOLDER}-${TIMESTAMP}.md"

# Count skipped files first
count_skipped_files "."

# Create markdown tree with folders and files
echo "# Directory Tree for ${CURRENT_FOLDER}" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Add skipped files summary at the top
cat "/tmp/skipped_summary.txt" >> "$OUTPUT_FILE"
echo "### Repository Structure:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Generate tree with ignore patterns
tree -L 4 "${IGNORE_PATTERNS[@]}" >> "$OUTPUT_FILE"

# Cleanup
rm "/tmp/skipped_summary.txt"

echo "Tree structure has been saved to ${OUTPUT_FILE}"