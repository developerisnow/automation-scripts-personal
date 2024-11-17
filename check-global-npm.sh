#!/bin/bash

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Set CSV file name with current date and time
csv_file="./logs/npm-global-packages-$(date +%Y-%m-%d_%H-%M).csv"

# Write CSV header
echo "node_version,package,version,size,location" > "$csv_file"

# Function to check global packages for a specific Node version
check_node_version() {
    local node_version=$1
    local node_path=$2
    
    echo "Checking Node.js $node_version..."
    
    # Get global npm packages directory for this Node version
    local npm_global_dir="$node_path/lib/node_modules"
    
    # Find all package.json files in the global directory
    find "$npm_global_dir" -maxdepth 2 -name "package.json" | while read -r pkg_json; do
        local pkg_dir=$(dirname "$pkg_json")
        local pkg_name=$(basename "$pkg_dir")
        
        # Skip the root node_modules directory itself
        if [ "$pkg_name" = "node_modules" ]; then
            continue
        fi
        
        # Get package version
        local version=$(node -p "require('$pkg_json').version")
        
        # Calculate size in MB
        local size=$(du -sm "$pkg_dir" | cut -f1)
        
        echo "$node_version,$pkg_name,$version,$size MB,$pkg_dir" >> "$csv_file"
    done
}

# Check if NVM is available
if [ -n "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
    # Source NVM
    . "$NVM_DIR/nvm.sh"
    
    echo "Found NVM installation. Checking all Node.js versions..."
    
    # Get list of installed Node versions
    versions=$(nvm ls --no-colors | grep "v[0-9]" | awk '{print $1}' | sed 's/->/ /' | tr -d ' ')
    
    # Check each version
    for version in $versions; do
        node_path="$NVM_DIR/versions/node/$version"
        if [ -d "$node_path" ]; then
            check_node_version "$version" "$node_path"
        fi
    done
else
    # Fallback for system Node.js
    echo "Checking system Node.js..."
    node_version=$(node --version)
    npm_path=$(which npm)
    node_path=$(dirname $(dirname "$npm_path"))
    check_node_version "$node_version" "$node_path"
fi

# Sort by size (descending) and create a sorted file
sort -t',' -k4 -nr "$csv_file" > "${csv_file%.csv}_sorted.csv"

# Generate summary report
echo -e "\nSummary Report:" > "${csv_file%.csv}_summary.txt"
echo "----------------" >> "${csv_file%.csv}_summary.txt"
echo "Total packages by Node version:" >> "${csv_file%.csv}_summary.txt"
awk -F',' 'NR>1 {count[$1]++; size[$1]+=$4} END {for (v in count) printf "%s: %d packages (%d MB)\n", v, count[v], size[$1]}' "$csv_file" >> "${csv_file%.csv}_summary.txt"

echo -e "\nLargest packages:" >> "${csv_file%.csv}_summary.txt"
head -n 6 "${csv_file%.csv}_sorted.csv" | awk -F',' '{printf "%s (%s): %s\n", $2, $1, $4}' >> "${csv_file%.csv}_summary.txt"

echo "Search complete. Files saved:"
echo "1. All packages: ${csv_file}"
echo "2. Sorted by size: ${csv_file%.csv}_sorted.csv"
echo "3. Summary report: ${csv_file%.csv}_summary.txt"

# Display summary
cat "${csv_file%.csv}_summary.txt"