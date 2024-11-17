#!/bin/bash

# Get the list of modified and untracked files
files=$(git status --porcelain | awk '{print $2}')

# Loop through each file and get the last modified date
for file in $files; do
    if [ -f "$file" ]; then
        last_modified=$(git log -1 --format="%ci" -- "$file")
        echo "$file - Last modified: $last_modified"
    else
        echo "$file - File does not exist"
    fi
done