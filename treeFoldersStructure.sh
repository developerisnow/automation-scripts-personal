#!/bin/bash

# Default values
MODE="both"
ROOT_DIR="."
SCAN_IGNORE_FILE=".scanignore"
MAX_LEVEL=-1  # -1 means unlimited levels

# Function to display help
show_help() {
    echo "Usage: $0 [options] [directory]"
    echo ""
    echo "Options:"
    echo "  --mode=md|csv|both   Specify output mode. Default is 'both'."
    echo "  --path=PATH          Specify absolute or relative path to scan."
    echo "  -L, --level=N        Maximum depth level to scan (default: unlimited)."
    echo "  --help               Show this help message."
    echo ""
    echo "Features:"
    echo "  - Scans directories with at least one underscore '_'"
    echo "  - Reads ignore patterns from .scanignore"
    echo "  - Controls depth with -L option"
    echo ""
    echo "Examples:"
    echo "  $0 --mode=md"
    echo "  $0 --mode=csv --path=/path/to/directory"
    echo "  $0 --mode=both -L 2"
    echo "  $0 --level=3"
}

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

# Function to check if directory should be skipped
should_skip_directory() {
    local dir="$1"
    local name=$(basename "$dir")
    
    # Skip directories that do NOT start with an underscore
    [[ "$name" != "_"* ]] && return 0
    
    # Check against ignore patterns from .scanignore
    if [ -f "$SCAN_IGNORE_FILE" ]; then
        while IFS= read -r pattern; do
            # Skip empty lines and comments
            [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
            [[ "$dir" == *"$pattern"* ]] && return 0
        done < "$SCAN_IGNORE_FILE"
    fi
    
    return 1
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --mode=*)
        MODE="${arg#*=}"
        shift
        ;;
        --path=*)
        ROOT_DIR="${arg#*=}"
        shift
        ;;
        -L=*|--level=*)
        MAX_LEVEL="${arg#*=}"
        shift
        ;;
        -L*)  # Handle -L2 format
        MAX_LEVEL="${arg#-L}"
        shift
        ;;
        --help)
        show_help
        exit 0
        ;;
    esac
done

# Clean up the folder name for the output file
FOLDER_NAME=$(basename "$(cd "$ROOT_DIR" && pwd)")
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M")
OUTPUT_FILE_MD="treeFolders_${FOLDER_NAME}-${TIMESTAMP}.md"
OUTPUT_FILE_CSV="treeFolders_${FOLDER_NAME}-${TIMESTAMP}.csv"
OUTPUT_FILE_YAML="treeFolders_${FOLDER_NAME}-${TIMESTAMP}.yaml"

# Function to create tree structure
create_tree() {
    local dir="$1"
    local prefix="$2"
    local current_level="$3"
    
    # Check if we've reached the maximum level
    if [ $MAX_LEVEL -ge 0 ] && [ $current_level -gt $MAX_LEVEL ]; then
        return
    fi
    
    for d in "$dir"/*/; do
        [ -d "$d" ] || continue
        
        # Skip if directory matches patterns
        if should_skip_directory "$d"; then
            continue
        fi
        
        local name=$(basename "$d")
        # Remove any leading './' from the name
        name="${name#./}"
        echo "${prefix}- ${name}"
        
        if [ ! -d "$d/.git" ]; then
            create_tree "$d" "  ${prefix}" $((current_level + 1))
        fi
    done
}

# Function to create CSV structure
create_csv() {
    local dir="$1"
    local current_level="$2"
    local temp_file="${OUTPUT_FILE_CSV}.tmp"
    
    # Check if we've reached the maximum level
    if [ $MAX_LEVEL -ge 0 ] && [ $current_level -gt $MAX_LEVEL ]; then
        return
    fi
    
    # Write header only if this is the root call (not a recursive call)
    if [ "$dir" = "$ROOT_DIR" ]; then
        echo "folderTitle,folderSizeMb,folderCreated,folderModified,folderPath,FoldersInsideFoldersAmount,FilesInsideFolderAmount" > "$OUTPUT_FILE_CSV"
    fi
    
    # Process directories
    for d in "$dir"/*/; do
        [ -d "$d" ] || continue
        
        # Skip if directory matches patterns
        if should_skip_directory "$d"; then
            continue
        fi
        
        local name=$(basename "$d")
        # Remove any leading './' from the name
        name="${name#./}"
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
            create_csv "$d" $((current_level + 1))
        fi
    done
    
    # Sort and append only if this is the root call
    if [ "$dir" = "$ROOT_DIR" ] && [ -f "$temp_file" ]; then
        sort -t',' -k3 "$temp_file" >> "$OUTPUT_FILE_CSV"
        rm "$temp_file"
    fi
}

# Add new function for YAML creation
create_yaml() {
    local dir="$1"
    local indent="$2"
    local current_level="$3"
    
    # Check if we've reached the maximum level
    if [ $MAX_LEVEL -ge 0 ] && [ $current_level -gt $MAX_LEVEL ]; then
        return
    fi
    
    for d in "$dir"/*/; do
        [ -d "$d" ] || continue
        
        # Skip if directory matches patterns
        if should_skip_directory "$d"; then
            continue
        fi
        
        local name=$(basename "$d")
        local path="${d#./}"
        local size=$(get_folder_size "$d")
        local created=$(get_folder_created "$d")
        local modified=$(get_folder_modified "$d")
        local folders_count=$(($(count_folders "$d") - 1))
        local files_count=$(count_files "$d")
        
        echo "${indent}- name: \"${name}\""
        echo "${indent}  path: \"${path}\""
        echo "${indent}  size_mb: ${size}"
        echo "${indent}  created: \"${created}\""
        echo "${indent}  modified: \"${modified}\""
        echo "${indent}  folders_count: ${folders_count}"
        echo "${indent}  files_count: ${files_count}"
        
        if [ ! -d "$d/.git" ]; then
            if [ -d "$d" ]; then
                echo "${indent}  children:"
                create_yaml "$d" "  ${indent}" $((current_level + 1))
            fi
        fi
    done
}

# Create the output files based on mode
if [ "$MODE" = "md" ] || [ "$MODE" = "both" ]; then
    echo "# Directory Tree for ${FOLDER_NAME} (Underscore Folders)" > "$OUTPUT_FILE_MD"
    echo "" >> "$OUTPUT_FILE_MD"
    create_tree "$ROOT_DIR" "" 0 >> "$OUTPUT_FILE_MD"
    echo "Markdown structure has been saved to $OUTPUT_FILE_MD"
fi

if [ "$MODE" = "csv" ] || [ "$MODE" = "both" ]; then
    create_csv "$ROOT_DIR" 0
    echo "CSV structure has been saved to $OUTPUT_FILE_CSV"
fi

if [ "$MODE" = "yaml" ] || [ "$MODE" = "both" ]; then
    echo "folders:" > "$OUTPUT_FILE_YAML"
    create_yaml "$ROOT_DIR" "  " 0 >> "$OUTPUT_FILE_YAML"
    echo "YAML structure has been saved to $OUTPUT_FILE_YAML"
fi

if [ "$MODE" != "md" ] && [ "$MODE" != "csv" ] && [ "$MODE" != "yaml" ] && [ "$MODE" != "both" ]; then
    echo "Invalid mode. Use --mode=md, --mode=csv, --mode=yaml, or --mode=both"
    exit 1
fi