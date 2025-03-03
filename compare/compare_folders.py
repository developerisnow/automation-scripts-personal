#!/usr/bin/env python3
"""
Folder Comparison Script

This script compares a main folder with one or more duplicate folders and generates
a CSV report of folders that are unique, larger, or more recently modified in the duplicates.
"""

import os
import csv
import time
import datetime
from pathlib import Path

# Configuration
# -------------
# Main folder path (source)
MAIN_FOLDER = os.path.expanduser("~/NextCloud2")
# MAIN_FOLDER = os.path.expanduser("~/__Repositories")

# List of duplicate folder paths to compare against
DUPLICATE_FOLDERS = [
    os.path.expanduser("~/NextCloud2_0"),
    # os.path.expanduser("~/__Repositories0"),
    # os.path.expanduser("~/__Repositories1")
]

# Output directory for the CSV report (defaults to script directory if empty)
OUTPUT_DIR = ""

def get_folder_info(folder_path):
    """Get information about a folder including creation time, modification time, and size."""
    try:
        path = Path(folder_path)
        if not path.exists() or not path.is_dir():
            return None
        
        stats = path.stat()
        created = stats.st_ctime
        modified = stats.st_mtime
        
        # Calculate total size
        total_size = 0
        for dirpath, dirnames, filenames in os.walk(folder_path):
            for f in filenames:
                fp = os.path.join(dirpath, f)
                if os.path.exists(fp):  # Skip if file doesn't exist (e.g., broken symlinks)
                    total_size += os.path.getsize(fp)
        
        return {
            "created": created,
            "modified": modified,
            "size": total_size
        }
    except Exception as e:
        print(f"Error getting info for {folder_path}: {e}")
        return None

def scan_directory(base_path):
    """Scan a directory and return a dictionary of folder information."""
    result = {}
    try:
        for item in os.listdir(base_path):
            full_path = os.path.join(base_path, item)
            if os.path.isdir(full_path):
                info = get_folder_info(full_path)
                if info:
                    result[item] = info
    except Exception as e:
        print(f"Error scanning directory {base_path}: {e}")
    return result

def format_timestamp(timestamp):
    """Convert a timestamp to a human-readable format."""
    return datetime.datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

def format_size(size_bytes):
    """Format size in bytes to a human-readable format."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"

def main():
    # Generate timestamp for the output filename
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    
    # Determine output directory
    output_directory = OUTPUT_DIR if OUTPUT_DIR else os.path.dirname(os.path.abspath(__file__))
    os.makedirs(output_directory, exist_ok=True)
    
    # Set output file path
    output_file = os.path.join(output_directory, f"compare_folders-{timestamp}.csv")
    
    # Scan main folder
    print(f"Scanning main folder: {MAIN_FOLDER}")
    main_folders = scan_directory(MAIN_FOLDER)
    
    # Prepare results list
    results = []
    
    # Scan and compare duplicate folders
    for dup_folder in DUPLICATE_FOLDERS:
        if not os.path.exists(dup_folder):
            print(f"Duplicate folder does not exist: {dup_folder}")
            continue
            
        print(f"Scanning duplicate folder: {dup_folder}")
        dup_folders = scan_directory(dup_folder)
        
        for folder_name, info in dup_folders.items():
            # Check if folder exists in main folder
            if folder_name not in main_folders:
                # Unique folder in duplicate
                results.append({
                    "folder": folder_name,
                    "created": info["created"],
                    "modified": info["modified"],
                    "size": info["size"],
                    "source": dup_folder,
                    "reason": "unique"
                })
            else:
                # Compare with main folder
                main_info = main_folders[folder_name]
                
                # Check if duplicate is newer
                if info["modified"] > main_info["modified"]:
                    results.append({
                        "folder": folder_name,
                        "created": info["created"],
                        "modified": info["modified"],
                        "size": info["size"],
                        "source": dup_folder,
                        "reason": "newer"
                    })
                # Check if duplicate is larger
                elif info["size"] > main_info["size"]:
                    results.append({
                        "folder": folder_name,
                        "created": info["created"],
                        "modified": info["modified"],
                        "size": info["size"],
                        "source": dup_folder,
                        "reason": "larger"
                    })
    
    # Write results to CSV
    if results:
        print(f"Writing {len(results)} results to {output_file}")
        with open(output_file, 'w', newline='') as csvfile:
            fieldnames = ['folder', 'created', 'modified', 'size', 'source', 'reason']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for result in results:
                writer.writerow({
                    'folder': result['folder'],
                    'created': format_timestamp(result['created']),
                    'modified': format_timestamp(result['modified']),
                    'size': format_size(result['size']),
                    'source': result['source'],
                    'reason': result['reason']
                })
        print(f"Report generated: {output_file}")
    else:
        print("No differences found.")

if __name__ == "__main__":
    main()
