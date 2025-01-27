#!/bin/bash

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Set CSV file name with current date and time
csv_file="./logs/python-local-configs-$(date +%Y-%m-%d_%H-%M).csv"

# Write CSV header
echo "title,file,created,updated,path" > "$csv_file"

# Function to run command and log output to CSV
run_and_log() {
    local file_type="$1"
    eval "$2" | while IFS= read -r file; do
        created=$(stat -f "%SB" -t "%Y-%m-%d %H:%M:%S" "$file")
        modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file")
        title=$(basename "$(dirname "$file")")
        echo "$title,$file_type,$created,$modified,$file" >> "$csv_file"
    done
}

# Search for pyproject.toml files
run_and_log "pyproject.toml" "find /Users/user/Programms -name pyproject.toml"

# Search for Pipfile files
run_and_log "Pipfile" "find /Users/user/Programms -name Pipfile"

echo "Search complete. CSV file saved to: $csv_file"