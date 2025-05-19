#!/bin/bash

# Function to create timestamp
get_timestamp() {
    date "+%Y-%m-%d-%H%M"
}

# Function to create archive directory if it doesn't exist
ensure_archive_dir() {
    mkdir -p .references/symlinks/_outputs/_logs
}

# Archive logs with XZ compression
archive_logs_xz() {
    local timestamp=$(get_timestamp)
    pwd
    tar -cJf "logs-$timestamp.tar.xz" logs
    ensure_archive_dir
    mv "logs-$timestamp.tar.xz" .references/symlinks/_outputs/_logs/
    echo "Created archive: .references/symlinks/_outputs/_logs/logs-$timestamp.tar.xz"
}

# Archive logs with ZSTD compression
archive_logs_zstd() {
    local timestamp=$(get_timestamp)
    pwd
    tar --zstd -cf "logs-$timestamp.tar.zst" logs
    ensure_archive_dir
    mv "logs-$timestamp.tar.zst" .references/symlinks/_outputs/_logs/
    echo "Created archive: .references/symlinks/_outputs/_logs/logs-$timestamp.tar.zst"
}

# Generic XZ compression for any path
archive_path_xz() {
    if [ -z "$1" ]; then
        echo "Error: No path provided"
        return 1
    fi
    local path="$1"
    local basename=$(basename "$path")
    tar -cJf "${basename}.tar.xz" "$path"
    echo "Created archive: ${basename}.tar.xz"
}

# Generic ZSTD compression for any path
archive_path_zstd() {
    if [ -z "$1" ]; then
        echo "Error: No path provided"
        return 1
    fi
    local path="$1"
    local basename=$(basename "$path")
    tar --zstd -cf "${basename}.tar.zst" "$path"
    echo "Created archive: ${basename}.tar.zst"
}

# Generic XZ unpack for .tar.xz or .xz archives
unxz_path() {
    if [ -z "$1" ]; then
        echo "Error: No archive provided"
        return 1
    fi
    local archive="$1"
    case "$archive" in
        *.tar.xz|*.txz)
            tar -xJf "$archive"
            ;;
        *.xz)
            unxz "$archive"
            ;;
        *)
            echo "Error: Unsupported archive extension for XZ unpack: $archive"
            return 1
            ;;
    esac
    echo "Unpacked archive: $archive"
}

# Backup repository excluding common large directories
backup_repo() {
    if [ -z "$1" ]; then
        echo "Error: No repository path provided"
        echo "Usage: backup_repo /path/to/repository"
        echo "Example: backup_repo "
        return 1
    fi
    
    local repo_path="$1"
    local timestamp=$(get_timestamp)
    local repo_name=$(basename "$repo_path")
    local parent_dir=$(dirname "$repo_path")
    local archive_name="${repo_name}-${timestamp}.tar.xz"
    
    if [ ! -d "$repo_path" ]; then
        echo "Error: Directory $repo_path does not exist"
        return 1
    fi
    
    cd "$repo_path" && \
    tar --exclude='.references' \
        --exclude='node_modules' \
        -cJf "$parent_dir/$archive_name" .
    
    echo "Created archive: $parent_dir/$archive_name"
}

# Command router
case "$1" in
    "rmlogsXZ") archive_logs_xz ;;
    "rmlogsZSTD") archive_logs_zstd ;;
    "xz") archive_path_xz "$2" ;;
    "zstd") archive_path_zstd "$2" ;;
    "unxz") unxz_path "$2" ;;
    "backup") backup_repo "$2" ;;
    *) echo "Usage: $0 {rmlogsXZ|rmlogsZSTD|xz path|zstd path|unxz archive|backup repo_path}"
       echo ""
       echo "Examples:"
       echo "  $0 backup LLMs-"
       echo "  $0 xz some_folder"
       echo "  $0 rmlogsXZ"
       echo "  $0 unxz logs-2025-05-10-1553.tar.xz"
       ;;
esac 