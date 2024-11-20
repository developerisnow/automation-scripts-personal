#!/bin/bash

# Default values
MODE="md"
ROOT_DIR="."

# Parse arguments
for arg in "$@"; do
    case $arg in
        --mode=*)
        MODE="${arg#*=}"
        shift
        ;;
        *)
        ROOT_DIR="$arg"
        ;;
    esac
done

# Clean up the folder name for the output file
FOLDER_NAME=$(basename "$(cd "$ROOT_DIR" && pwd)")
OUTPUT_FILE="tree_${FOLDER_NAME}.${MODE}"

# Function to count folders inside
count_folders() {
    local dir="$1"
    find "$dir" -type d | wc -l
}

# Function to count files inside
count_files() {
    local dir="$1"
    find "$dir" -type f | wc -l
}

# Function to get folder size in MB
get_folder_size() {
    local dir="$1"
    du -sm "$dir" | cut -f1
}

# Function to get folder creation time with formatted date
get_folder_created() {
    local dir="$1"
    stat -f "%SB" "$dir" | xargs -I {} date -j -f "%b %d %H:%M:%S %Y" "{}" "+%Y-%m-%d_%H-%M"
}

# Function to get folder modified time with formatted date
get_folder_modified() {
    local dir="$1"
    stat -f "%Sm" "$dir" | xargs -I {} date -j -f "%b %d %H:%M:%S %Y" "{}" "+%Y-%m-%d_%H-%M"
}

# Function to create CSV structure
create_csv() {
    local dir="$1"
    local temp_file="${OUTPUT_FILE}.tmp"
    
    # Write header only if this is the root call (not a recursive call)
    if [ "$dir" = "$ROOT_DIR" ]; then
        echo "folderTitle,folderSizeMb,folderCreated,folderModified,folderPath,FoldersInsideFoldersAmount,FilesInsideFolderAmount" > "$OUTPUT_FILE"
    fi
    
    # Process directories
    for d in "$dir"/*/; do
        [ -d "$d" ] || continue
        
        local name=$(basename "$d")
        local size=$(get_folder_size "$d")
        local created=$(get_folder_created "$d")
        local modified=$(get_folder_modified "$d")
        local path="${d#./}"
        local folders_count=$(($(count_folders "$d") - 1))
        local files_count=$(count_files "$d")
        
        # Write to temp file
        echo "$name,$size,\"$created\",\"$modified\",\"$path\",$folders_count,$files_count" >> "$temp_file"
        
        # Recurse only if not a git repository
        if [ ! -d "$d/.git" ]; then
            create_csv "$d"
        fi
    done
    
    # Sort and append only if this is the root call
    if [ "$dir" = "$ROOT_DIR" ] && [ -f "$temp_file" ]; then
        sort -t',' -k3 "$temp_file" >> "$OUTPUT_FILE"
        rm "$temp_file"
    fi
}

# Function to create tree structure (existing markdown version)
create_tree() {
    local dir="$1"
    local prefix="$2"
    
    for d in "$dir"/*/; do
        [ -d "$d" ] || continue
        
        local name=$(basename "$d")
        echo "${prefix}- ${name}"
        
        if [ ! -d "$d/.git" ]; then
            create_tree "$d" "  ${prefix}"
        fi
    done
}

# Create the output file based on mode
if [ "$MODE" = "md" ]; then
    echo "# Directory Tree for ${FOLDER_NAME}" > "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    create_tree "$ROOT_DIR" "" >> "$OUTPUT_FILE"
elif [ "$MODE" = "csv" ]; then
    create_csv "$ROOT_DIR"
else
    echo "Invalid mode. Use --mode=md or --mode=csv"
    exit 1
fi

echo "Structure has been saved to $OUTPUT_FILE"