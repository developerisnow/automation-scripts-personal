#!/usr/bin/env python3
"""
Script to analyze markdown files in _inputs directories and generate a CSV report.
This is the analysis phase of the markdown note reorganization project.
"""

import os
import csv
import datetime
import argparse
import re
from pathlib import Path

# Regular expression to detect existing date patterns in filenames
DATE_PATTERN_REGEX = re.compile(r'^(\d{4}-\d{2}-\d{2}|\d{4}-\d{2}-\d{2}-\d{4})')

def get_file_info(file_path):
    """Get information about a file."""
    # Skip symlinks
    if os.path.islink(file_path):
        return None
        
    # Check if file exists
    if not os.path.exists(file_path):
        return None
        
    stat = os.stat(file_path)
    created_time = datetime.datetime.fromtimestamp(stat.st_ctime)
    modified_time = datetime.datetime.fromtimestamp(stat.st_mtime)
    
    # Count lines in the file
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        try:
            line_count = sum(1 for _ in f)
        except UnicodeDecodeError:
            line_count = -1  # Indicate error in reading
        except Exception as e:
            print(f"Error reading file {file_path}: {e}")
            line_count = -1
    
    # Calculate size in KB
    size_kb = stat.st_size / 1024
    
    return {
        'filename': os.path.basename(file_path),
        'lines': line_count,
        'size_kb': round(size_kb, 2),
        'created': created_time.strftime('%Y-%m-%d %H:%M:%S'),
        'modified': modified_time.strftime('%Y-%m-%d %H:%M:%S'),
        'path': file_path
    }

def find_markdown_files(base_dir, pattern="_inputs"):
    """Find all markdown files in directories matching the pattern."""
    markdown_files = []
    symlinks_found = []
    
    for root, dirs, files in os.walk(base_dir):
        # Check if the current directory path contains the pattern
        if pattern in root:
            for file in files:
                if file.lower().endswith('.md'):
                    file_path = os.path.join(root, file)
                    
                    # Check if it's a symlink
                    if os.path.islink(file_path):
                        symlinks_found.append(file_path)
                        continue
                        
                    # Skip if file doesn't exist (broken link or other issue)
                    if not os.path.exists(file_path):
                        continue
                        
                    markdown_files.append(file_path)
    
    return markdown_files, symlinks_found

def extract_project_folder_name(file_path, pattern="_inputs"):
    """Extract the project folder name from the file path."""
    # Convert to Path object for easier manipulation
    path = Path(file_path)
    
    # Find the _inputs part of the path
    inputs_index = -1
    for i, part in enumerate(path.parts):
        if pattern in part:
            inputs_index = i
            break
    
    if inputs_index > 0:
        # Get the parent folder of _inputs
        project_folder = path.parts[inputs_index-1]
        # Remove leading underscores
        if project_folder.startswith('_'):
            project_folder = project_folder.lstrip('_')
        
        return project_folder
    
    return "Unknown"

def has_date_pattern(filename):
    """Check if filename already has a date pattern at the beginning."""
    return bool(DATE_PATTERN_REGEX.match(filename))

def generate_new_filename(file_info, project_folder):
    """Generate new filename based on requirements."""
    original_filename = file_info['filename']
    
    # Remove file extension for processing
    basename = os.path.splitext(original_filename)[0]
    
    # Check if filename already starts with a date pattern
    if has_date_pattern(basename):
        # If it already has a date pattern, don't add another one
        new_filename = f"{basename}__{project_folder}.md"
    else:
        # Extract creation date and time
        created_dt = datetime.datetime.strptime(file_info['created'], '%Y-%m-%d %H:%M:%S')
        date_part = created_dt.strftime('%Y-%m-%d-%H%M')
        
        # Format: YYYY-MM-DD-hhmm-<title>__<project-foldername>.md
        new_filename = f"{date_part}-{basename}__{project_folder}.md"
    
    return new_filename

def log_symlinks(symlinks_found, log_file="symlinks_skipped.log"):
    """Log symlinks that were skipped."""
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"Found {len(symlinks_found)} symlinks that were skipped:\n\n")
        for link in symlinks_found:
            try:
                target = os.readlink(link)
                f.write(f"{link} -> {target}\n")
            except:
                f.write(f"{link} (could not resolve target)\n")

def main():
    parser = argparse.ArgumentParser(description='Analyze markdown files in _inputs directories.')
    parser.add_argument('--base-dir', type=str, required=True, 
                      help='Base directory to start the search from')
    parser.add_argument('--output', type=str, default='markdown_files_analysis.csv',
                      help='Output CSV file name')
    parser.add_argument('--pattern', type=str, default='_inputs',
                      help='Pattern to match in directory names')
    parser.add_argument('--symlinks-log', type=str, default='symlinks_skipped.log',
                      help='Log file for skipped symlinks')
    
    args = parser.parse_args()
    
    base_dir = args.base_dir
    output_file = args.output
    pattern = args.pattern
    symlinks_log = args.symlinks_log
    
    print(f"Searching for markdown files in {base_dir} with pattern '{pattern}'...")
    
    # Find all markdown files and symlinks
    markdown_files, symlinks_found = find_markdown_files(base_dir, pattern)
    
    print(f"Found {len(markdown_files)} markdown files.")
    print(f"Skipped {len(symlinks_found)} symlinks.")
    
    # Log symlinks that were skipped
    log_symlinks(symlinks_found, symlinks_log)
    print(f"Symlinks logged to {symlinks_log}")
    
    # Get information for each file and generate proposed new filename
    file_info_list = []
    for file_path in markdown_files:
        info = get_file_info(file_path)
        if info:  # Skip if info is None (e.g., file is a symlink or doesn't exist)
            project_folder = extract_project_folder_name(file_path, pattern)
            new_filename = generate_new_filename(info, project_folder)
            
            info['project_folder'] = project_folder
            info['new_filename'] = new_filename
            file_info_list.append(info)
    
    # Write to CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['filename', 'lines', 'size_kb', 'created', 'modified', 'path', 'project_folder', 'new_filename']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for info in file_info_list:
            writer.writerow(info)
    
    print(f"Analysis complete. Results written to {output_file}")
    print(f"Files to process: {len(file_info_list)}")

if __name__ == "__main__":
    main() 