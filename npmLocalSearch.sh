#!/bin/bash

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Set CSV file name with current date and time
csv_file="./logs/npm-local-configs-$(date +%Y-%m-%d_%H-%M).csv"

# Write CSV header
echo "title,package_manager,size,created,updated,path" > "$csv_file"

# Find root node_modules directories (excluding nested ones)
find /Users/user/Programms -type d -name "node_modules" | while read -r dir; do
    # Skip if parent directory contains node_modules (to avoid nested ones)
    if [[ "${dir%/*}" == *"node_modules"* ]]; then
        continue
    fi
    
    project_dir=$(dirname "$dir")
    title=$(basename "$project_dir")
    
    # Calculate size
    size=$(du -sm "$dir" | cut -f1)
    
    # Get timestamps
    created=$(stat -f "%SB" -t "%Y-%m-%d %H:%M:%S" "$dir")
    modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$dir")
    
    # Determine package manager
    pkg_manager="npm"
    if [ -f "$project_dir/yarn.lock" ]; then
        pkg_manager="npm_yarn"
    elif [ -f "$project_dir/pnpm-lock.yaml" ]; then
        pkg_manager="npm_pnpm"
    fi
    
    echo "$title,$pkg_manager,$size MB,$created,$modified,$project_dir" >> "$csv_file"
done

echo "Search complete. CSV file saved to: $csv_file"
