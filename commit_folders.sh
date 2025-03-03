#!/bin/bash

# This script commits untracked files by directory

# Make the script exit if any command fails
set -e

# Function to get the list of untracked directories at the first level
get_untracked_directories() {
  git status --porcelain | grep "^??" | cut -d" " -f2 | cut -d"/" -f1 | sort | uniq
}

# Function to commit a specific directory
commit_directory() {
  local dir="$1"
  
  # Skip if not a directory or empty
  if [ ! -d "$dir" ] || [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    echo "Skipping $dir (not a directory or empty)"
    return
  fi
  
  echo "Processing directory: $dir"
  
  # Add all files in the directory
  git add "$dir/"
  
  # Create commit message based on directory name
  local commit_message="Add files in $dir"
  
  # Commit the changes
  git commit -m "$commit_message"
  
  echo "Committed $dir successfully"
  echo "------------------------"
}

# Main execution
echo "Starting folder-by-folder commit process..."
echo "------------------------"

# Get the list of untracked directories
directories=$(get_untracked_directories)

# Check if there are any untracked directories
if [ -z "$directories" ]; then
  echo "No untracked directories found. Nothing to commit."
  exit 0
fi

# Process each directory
for dir in $directories; do
  commit_directory "$dir"
done

echo "All directories committed successfully!" 