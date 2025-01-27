#!/bin/bash

# Ensure the script exits on any error
set -e

# Create logs directory if it doesn't exist
mkdir -p logs

# Define output CSV files
pythons_csv="logs/pythons.csv"
python_packages_csv="logs/python-packages.csv"

# Create or overwrite the CSV files with headers
echo "python_version,source,size_mb" > "$pythons_csv"
echo "package_name,version,environment,size_mb" > "$python_packages_csv"

# Function to convert size to MB
convert_to_mb() {
    local size=$1
    local unit=$2
    if [ "$unit" = "G" ]; then
        echo "scale=2; $size * 1024" | bc
    elif [ "$unit" = "K" ]; then
        echo "scale=2; $size / 1024" | bc
    else
        echo "$size"
    fi
}

# Create temporary files for find output
python_paths_tmp=$(mktemp)
package_paths_tmp=$(mktemp)

# Find Python installations and save to temp file
find /usr/local/lib /opt/homebrew/lib ~/.pyenv/versions -type d -name "python3.*" -ls 2>/dev/null > "$python_paths_tmp" || true

# Parse Python versions and sizes
while read -r line; do
    # Match lines with size information for Python installations
    if echo "$line" | grep -E "([0-9.]+[MGK])[[:space:]]+(.*/python3\.[0-9]+)" > /dev/null; then
        size_raw=$(echo "$line" | grep -Eo "[0-9.]+[MGK]" | head -1)
        path=$(echo "$line" | grep -Eo "/.*python3\.[0-9]+")
        
        # Extract size value and unit
        size_value=$(echo "$size_raw" | sed 's/[GMK]$//')
        size_unit=$(echo "$size_raw" | grep -o '[GMK]')
        
        # Convert size to MB
        size_mb=$(convert_to_mb "$size_value" "$size_unit")
        
        # Extract Python version from path
        version=$(echo "$path" | grep -Eo "python3\.[0-9]+" | sed 's/python//')
        if [ -n "$version" ]; then
            echo "$version,system,$size_mb" >> "$pythons_csv"
        fi
    fi
done < "$python_paths_tmp"

# Find package installations and save to temp file
find ~/.local/share/virtualenvs /usr/local/lib/python* /opt/homebrew/lib/python* -type d -name "*.dist-info" 2>/dev/null > "$package_paths_tmp" || true

# Parse installed packages
while read -r line; do
    # Extract package name and version from dist-info directory
    package_info=$(basename "$line" .dist-info)
    if echo "$package_info" | grep -E "^[A-Za-z0-9._-]+-[0-9.]+" > /dev/null; then
        package_name=$(echo "$package_info" | sed -E 's/-[0-9.]+$//')
        version=$(echo "$package_info" | grep -Eo '[0-9.]+$')
        
        # Get package size if available
        package_dir=$(dirname "$line")/"$package_name"
        if [ -d "$package_dir" ]; then
            size_output=$(du -sh "$package_dir" 2>/dev/null || echo "0M")
            if echo "$size_output" | grep -E "^[0-9.]+[MGK]" > /dev/null; then
                size_value=$(echo "$size_output" | grep -Eo "^[0-9.]+" | head -1)
                size_unit=$(echo "$size_output" | grep -Eo "[MGK]" | head -1)
                size_mb=$(convert_to_mb "$size_value" "$size_unit")
                
                # Determine environment from path
                if echo "$line" | grep -q "virtualenvs/"; then
                    env=$(echo "$line" | grep -Eo "virtualenvs/[^/]+" | cut -d/ -f2)
                else
                    env="system"
                fi
                
                echo "$package_name,$version,$env,$size_mb" >> "$python_packages_csv"
            fi
        fi
    fi
done < "$package_paths_tmp"

# Clean up temporary files
rm -f "$python_paths_tmp" "$package_paths_tmp"

echo "Reports generated successfully:"
echo "- $pythons_csv"
echo "- $python_packages_csv"