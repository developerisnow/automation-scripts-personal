#!/bin/bash

# Input and output files
input_csv="./logs/npm-local-configs-to-delete.csv"
temp_csv="./logs/npm-local-configs-to-delete.tmp"

# Copy header
head -n 1 "$input_csv" > "$temp_csv"

# Process each line (skipping header)
tail -n +2 "$input_csv" | while IFS=, read -r title package_manager size created updated deleted path; do
    # Remove quotes if present
    path=$(echo "$path" | tr -d '"')
    node_modules_path="${path}/node_modules"
    
    # Check if node_modules exists
    if [ -d "$node_modules_path" ]; then
        # Delete node_modules
        rm -rf "$node_modules_path"
        
        # Get current timestamp in the same format as 'created'
        deleted_time=$(date "+%Y-%m-%d %H:%M:%S")
        
        # Write updated line to temp file
        echo "$title,$package_manager,$size,$created,$updated,$deleted_time,$path" >> "$temp_csv"
    else
        # Keep original line if no node_modules found
        echo "$title,$package_manager,$size,$created,$updated,$deleted,$path" >> "$temp_csv"
    fi
done

# Replace original file with updated one
mv "$temp_csv" "$input_csv"

echo "Process complete. CSV updated with deletion timestamps."
