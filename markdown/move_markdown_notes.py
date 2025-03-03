#!/usr/bin/env python3
"""
Script to move markdown files from _inputs directories to a centralized location,
rename them according to the format YYYY-MM-DD-hhmm-<title>__<project-foldername>.md,
and create symlinks from the original locations.
"""

import os
import csv
import shutil
import argparse
import datetime
from pathlib import Path

def create_log_file(log_directory):
    """Create a log file for the current run."""
    if not os.path.exists(log_directory):
        os.makedirs(log_directory)
    
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    log_file = os.path.join(log_directory, f"move-markdown-notes-{timestamp}.log")
    
    return log_file

def log_action(log_file, action, source=None, target=None, success=True, error=None):
    """Log an action to the log file."""
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    with open(log_file, 'a', encoding='utf-8') as f:
        log_line = f"[{timestamp}] {action}"
        
        if source:
            log_line += f"\n  Source: {source}"
        if target:
            log_line += f"\n  Target: {target}"
        if not success:
            log_line += f"\n  ERROR: {error}"
        
        log_line += "\n"
        f.write(log_line)

def move_file_and_create_symlink(source_path, target_dir, new_filename, log_file):
    """Move a file to the target directory and create a symlink from the original location."""
    # Check if source is a symlink
    if os.path.islink(source_path):
        log_action(log_file, "SKIP - Source is a symlink", source_path, success=False, 
                  error="Source is a symlink")
        return False
    
    # Check if source file exists
    if not os.path.exists(source_path):
        log_action(log_file, "SKIP - Source file not found", source_path, success=False, 
                  error="Source file not found")
        return False
    
    # Make sure the target directory exists
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
    
    target_path = os.path.join(target_dir, new_filename)
    
    # Check if target file already exists
    if os.path.exists(target_path):
        log_action(log_file, "SKIP - Target file already exists", source_path, target_path, success=False, 
                  error="Target file already exists")
        return False
    
    try:
        # Move the file
        shutil.copy2(source_path, target_path)
        log_action(log_file, "COPY", source_path, target_path)
        
        # Remove original file
        os.remove(source_path)
        log_action(log_file, "REMOVE ORIGINAL", source_path)
        
        # Create symlink from original location to new location
        os.symlink(target_path, source_path)
        log_action(log_file, "CREATE SYMLINK", target_path, source_path)
        
        return True
    except Exception as e:
        log_action(log_file, "FAILED", source_path, target_path, success=False, error=str(e))
        return False

def process_files(csv_file, target_dir, log_dir, dry_run=False):
    """Process files according to the CSV report."""
    # Create log file
    log_file = create_log_file(log_dir)
    
    # Start log
    log_action(log_file, f"STARTED PROCESSING - {'DRY RUN' if dry_run else 'ACTUAL RUN'}")
    
    # Count statistics
    total_files = 0
    moved_files = 0
    skipped_files = 0
    error_files = 0
    symlink_files = 0
    
    # Process each file
    with open(csv_file, 'r', newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            total_files += 1
            source_path = row['path']
            new_filename = row['new_filename']
            
            # Skip symlinks
            if os.path.islink(source_path):
                log_action(log_file, "SKIP - Source is a symlink", source_path)
                symlink_files += 1
                continue
                
            if not os.path.exists(source_path):
                log_action(log_file, "SKIP - Source file not found", source_path, success=False, 
                          error="Source file not found")
                skipped_files += 1
                continue
            
            # In dry run mode, just log what would happen
            if dry_run:
                log_action(log_file, "DRY RUN - Would move", source_path, os.path.join(target_dir, new_filename))
                moved_files += 1
            else:
                # Actually move the file and create symlink
                success = move_file_and_create_symlink(source_path, target_dir, new_filename, log_file)
                
                if success:
                    moved_files += 1
                else:
                    error_files += 1
    
    # Log summary
    summary = f"""
PROCESSING COMPLETE
Total files: {total_files}
Moved files: {moved_files}
Skipped files: {skipped_files}
Skipped symlinks: {symlink_files}
Errors: {error_files}
"""
    log_action(log_file, summary)
    
    print(summary)
    print(f"Log file created at: {log_file}")
    
    return log_file

def main():
    parser = argparse.ArgumentParser(description='Move markdown files and create symlinks.')
    parser.add_argument('--csv-file', type=str, required=True, 
                      help='CSV file with file information (from analyze_markdown_notes.py)')
    parser.add_argument('--target-dir', type=str, required=True,
                      help='Target directory to move files to')
    parser.add_argument('--log-dir', type=str, default='logs',
                      help='Directory to store log files')
    parser.add_argument('--dry-run', action='store_true',
                      help='Dry run mode (no actual changes)')
    
    args = parser.parse_args()
    
    process_files(args.csv_file, args.target_dir, args.log_dir, args.dry_run)

if __name__ == "__main__":
    main() 