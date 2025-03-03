#!/usr/bin/env python3
"""
Script to fix markdown files with redundant date prefixes in the Dailies_Outputs directory.
This script will:
1. Remove redundant date prefixes from filenames that already have date patterns
2. Delete files with "._" in the middle of their names (optional)
3. Organize files into subfolders based on project name (optional)
"""

import os
import re
import argparse
import datetime
import shutil
from pathlib import Path

# Regular expressions for detecting different date patterns
DATE_PATTERN_1 = re.compile(r"^\d{4}-\d{2}-\d{2}-\d{4}-.*")  # Matches: 2025-02-19-0809-2025-01-26-...
DATE_PATTERN_2 = re.compile(r"^(\d{4}-\d{2}-\d{2}-\d{4})-\._(\d{4}-\d{2}-\d{2}.*)")  # Matches: 2025-02-19-0809-._2025-01-26-...
DATE_PATTERN_3 = re.compile(r"^\d{4}-\d{2}-\d{2}-\d{4}-(\d{8}-\d{4}-\d{4}.*)")  # Matches: 2025-02-19-0809-20250201-1510-1653-...
# New pattern to match the standard redundant prefix (most of your files)
DATE_PATTERN_4 = re.compile(r"^(\d{4}-\d{2}-\d{2}-\d{4})-(.+)")  # Matches: 2025-02-19-0809-anything

# Regular expression to extract project name from filename
PROJECT_NAME_PATTERN = re.compile(r"__([^_]+)(?:_[^_]+)?\.md$")  # Matches: __ProjectName.md or __ProjectName_Suffix.md

# Global dictionary to store symlinks and their targets
SYMLINKS_MAP = {}
# Debug mode
DEBUG = False

def create_log_file():
    """Create a log file for the current run."""
    log_dir = "logs"
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    log_file = os.path.join(log_dir, f"fix-duplicated-dates-{timestamp}.log")
    
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

def find_symlinks_in_project(base_dir, log_file):
    """Find symlinks in project directories and map their targets."""
    print("Scanning for symlinks (this may take a moment)...")
    log_action(log_file, "Scanning for symlinks in project directories")
    
    # Look for _inputs directories within the PARA structure
    para_base = os.path.expanduser("~/____Sandruk/___PARA")
    symlink_count = 0
    
    for category in ['__Projects', '__Areas', '__Resources', '__Archives']:
        category_path = os.path.join(para_base, category)
        if not os.path.exists(category_path):
            continue
            
        for root, dirs, files in os.walk(category_path):
            if '_inputs' in dirs:
                inputs_dir = os.path.join(root, '_inputs')
                for file in os.listdir(inputs_dir):
                    file_path = os.path.join(inputs_dir, file)
                    if os.path.islink(file_path):
                        try:
                            link_target = os.readlink(file_path)
                            SYMLINKS_MAP[link_target] = file_path
                            symlink_count += 1
                        except Exception as e:
                            log_action(log_file, "Error reading symlink", file_path, 
                                      success=False, error=str(e))
    
    log_action(log_file, f"Found {symlink_count} symlinks in project directories")
    print(f"Found {symlink_count} symlinks to track")

def get_project_folder(filename):
    """Extract project folder name from filename using the last __ pattern."""
    # Find all __ occurrences
    double_underscore_positions = [m.start() for m in re.finditer('__', filename)]
    
    # If there are at least two __ patterns
    if len(double_underscore_positions) >= 2:
        # Take the second-to-last __ position
        second_last_pos = double_underscore_positions[-2]
        # Extract text between the last two __ occurrences
        project_name = filename[second_last_pos + 2:double_underscore_positions[-1]]
        return project_name
    elif len(double_underscore_positions) == 1:
        # If only one __ pattern, extract text after it but before .md
        match = re.search(r'__([^_\.]+)', filename)
        if match:
            return match.group(1)
    
    return None

def process_file_for_subfolder(filename, log_file, dir_path, dry_run=False):
    """Determine if a file should be moved to a subfolder based on project name in filename."""
    project_name = get_project_folder(filename)
    
    # Skip files without a project name
    if not project_name:
        if DEBUG:
            print(f"  No project name found in {filename}")
        return None, None
    
    target_dir = os.path.join(dir_path, project_name)
    
    # Create the subfolder if it doesn't exist
    if not os.path.exists(target_dir) and not dry_run:
        os.makedirs(target_dir)
        log_action(log_file, f"CREATED SUBFOLDER: {project_name}", target_dir)
    
    new_path = os.path.join(target_dir, filename)
    
    # Skip if target already exists
    if os.path.exists(new_path):
        if DEBUG:
            print(f"  Skipping - Target already exists: {new_path}")
        log_action(log_file, "SKIP - Target file already exists", 
                 os.path.join(dir_path, filename), new_path, 
                 success=False, error="Target file already exists")
        return None, None
    
    return target_dir, project_name

def rename_file(file_path, new_name, log_file, dry_run=False, organize_subfolders=False):
    """Rename a file and log the action."""
    dir_path = os.path.dirname(file_path)
    
    # If organizing into subfolders and file has __ pattern
    target_dir = dir_path
    if organize_subfolders and '__' in new_name:
        project_name = get_project_folder(new_name)
        if project_name:
            target_dir = os.path.join(dir_path, project_name)
            if not os.path.exists(target_dir) and not dry_run:
                os.makedirs(target_dir)
                log_action(log_file, f"CREATED SUBFOLDER: {project_name}", target_dir)
    
    new_path = os.path.join(target_dir, new_name)
    
    # Check if target already exists
    if os.path.exists(new_path):
        log_action(log_file, "SKIP - Target file already exists", file_path, new_path, success=False,
                  error="Target file already exists")
        return False
    
    if dry_run:
        log_action(log_file, "DRY RUN - Would rename", file_path, new_path)
        return True
    
    try:
        os.rename(file_path, new_path)
        log_action(log_file, "RENAMED", file_path, new_path)
        
        # If there's a symlink pointing to the old file, update it
        if file_path in SYMLINKS_MAP:
            symlink_path = SYMLINKS_MAP[file_path]
            try:
                os.remove(symlink_path)
                os.symlink(new_path, symlink_path)
                log_action(log_file, "UPDATED SYMLINK", symlink_path, new_path)
                # Update the map
                SYMLINKS_MAP[new_path] = symlink_path
                del SYMLINKS_MAP[file_path]
            except Exception as e:
                log_action(log_file, "FAILED TO UPDATE SYMLINK", symlink_path, 
                          success=False, error=str(e))
        
        return True
    except Exception as e:
        log_action(log_file, "FAILED", file_path, new_path, success=False, error=str(e))
        return False

def move_to_subfolder(file_path, target_dir, log_file, dry_run=False):
    """Move a file to a subfolder based on project name."""
    filename = os.path.basename(file_path)
    new_path = os.path.join(target_dir, filename)
    
    # Check if target already exists
    if os.path.exists(new_path):
        log_action(log_file, "SKIP - Target file already exists", file_path, new_path, success=False,
                  error="Target file already exists")
        return False
    
    if dry_run:
        log_action(log_file, "DRY RUN - Would move to subfolder", file_path, new_path)
        return True
    
    try:
        os.rename(file_path, new_path)
        log_action(log_file, "MOVED TO SUBFOLDER", file_path, new_path)
        
        # If there's a symlink pointing to the old file, update it
        if file_path in SYMLINKS_MAP:
            symlink_path = SYMLINKS_MAP[file_path]
            try:
                os.remove(symlink_path)
                os.symlink(new_path, symlink_path)
                log_action(log_file, "UPDATED SYMLINK", symlink_path, new_path)
                # Update the map
                SYMLINKS_MAP[new_path] = symlink_path
                del SYMLINKS_MAP[file_path]
            except Exception as e:
                log_action(log_file, "FAILED TO UPDATE SYMLINK", symlink_path, 
                          success=False, error=str(e))
        
        return True
    except Exception as e:
        log_action(log_file, "FAILED TO MOVE", file_path, new_path, success=False, error=str(e))
        return False

def delete_file(file_path, log_file, dry_run=False):
    """Delete a file and log the action."""
    if dry_run:
        log_action(log_file, "DRY RUN - Would delete", file_path)
        return True
    
    try:
        os.remove(file_path)
        log_action(log_file, "DELETED", file_path)
        return True
    except Exception as e:
        log_action(log_file, "FAILED TO DELETE", file_path, success=False, error=str(e))
        return False

def process_directory(directory, log_file, delete_dot_files=False, dry_run=False, organize_subfolders=False, debug=False):
    """Process all markdown files in the directory to fix redundant date prefixes."""
    # Count statistics
    total_files = 0
    renamed_files = 0
    deleted_files = 0
    moved_files = 0
    skipped_files = 0
    error_files = 0
    subfolder_created = 0
    
    # Get all markdown files
    markdown_files = []
    for file in os.listdir(directory):
        if file.lower().endswith('.md') and os.path.isfile(os.path.join(directory, file)):
            markdown_files.append(file)
    
    total_files = len(markdown_files)
    log_action(log_file, f"Found {total_files} markdown files in {directory}")
    
    # Find all symlinks in project directories (unless in dry-run mode)
    if not dry_run:
        find_symlinks_in_project(directory, log_file)
    
    # Track created subfolders
    created_folders = set()
    
    # First pass: handle all renaming operations
    for filename in markdown_files:
        file_path = os.path.join(directory, filename)
        
        if debug:
            print(f"\nProcessing file: {filename}")
            print(f"  DATE_PATTERN_1 match: {bool(DATE_PATTERN_1.match(filename))}")
            print(f"  DATE_PATTERN_2 match: {bool(DATE_PATTERN_2.match(filename))}")
            print(f"  DATE_PATTERN_3 match: {bool(DATE_PATTERN_3.match(filename))}")
            print(f"  DATE_PATTERN_4 match: {bool(DATE_PATTERN_4.match(filename))}")
            if '__' in filename:
                print(f"  Project folder: {get_project_folder(filename)}")
        
        # Handle files with "._" in the middle
        match = DATE_PATTERN_2.match(filename)
        if match and "._" in filename:
            if debug:
                print(f"  Handling as '._' file")
            if delete_dot_files:
                # Delete these problematic files
                if delete_file(file_path, log_file, dry_run):
                    deleted_files += 1
                else:
                    error_files += 1
            else:
                # Try to fix the filename by removing the "._" part
                prefix = match.group(1)
                content = match.group(2)
                new_name = f"{content}"
                
                if rename_file(file_path, new_name, log_file, dry_run, organize_subfolders):
                    renamed_files += 1
                    
                    # Track subfolder creation
                    if organize_subfolders and not dry_run and new_name.count('__') >= 1:
                        project_name = get_project_folder(new_name)
                        if project_name and project_name not in created_folders:
                            created_folders.add(project_name)
                            subfolder_created += 1
                else:
                    error_files += 1
            continue
        
        # Handle files with non-kebab case date format (20250201-1510-1653)
        match = DATE_PATTERN_3.match(filename)
        if match:
            if debug:
                print(f"  Handling as non-kebab date format file")
            # This is a file with redundant date prefix, but non-kebab date in content
            new_name = match.group(1)
            
            if rename_file(file_path, new_name, log_file, dry_run, organize_subfolders):
                renamed_files += 1
                
                # Track subfolder creation
                if organize_subfolders and not dry_run and new_name.count('__') >= 1:
                    project_name = get_project_folder(new_name)
                    if project_name and project_name not in created_folders:
                        created_folders.add(project_name)
                        subfolder_created += 1
            else:
                error_files += 1
            continue
        
        # Handle files with standard redundant date prefix (2025-02-19-0809-)
        match = DATE_PATTERN_4.match(filename)
        if match:
            if debug:
                print(f"  Handling as standard redundant date prefix file")
            prefix = match.group(1)  # The date prefix (2025-02-19-0809)
            content = match.group(2)  # Everything after the prefix
            
            # Skip if this is a pattern we already handle elsewhere
            if filename.count('2025-02-19-0809-') > 0:
                new_name = filename.replace('2025-02-19-0809-', '')
                
                if debug:
                    print(f"  Will rename to: {new_name}")
                
                if rename_file(file_path, new_name, log_file, dry_run, organize_subfolders):
                    renamed_files += 1
                    
                    # Track subfolder creation
                    if organize_subfolders and not dry_run and new_name.count('__') >= 1:
                        project_name = get_project_folder(new_name)
                        if project_name and project_name not in created_folders:
                            created_folders.add(project_name)
                            subfolder_created += 1
                else:
                    error_files += 1
                continue
            else:
                if debug:
                    print(f"  Skipping as it doesn't have the specific prefix we're looking for")
                skipped_files += 1
                continue
            
        # Handle files with redundant date prefix with embedded date
        match = DATE_PATTERN_1.match(filename)
        if match:
            if debug:
                print(f"  Handling as redundant date prefix with embedded date")
            parts = filename.split('-', 4)  # Split on first 4 hyphens
            if len(parts) >= 5:
                # Check if the content part starts with a date pattern
                content_part = parts[4]
                if re.match(r"^\d{4}-\d{2}-\d{2}.*", content_part):
                    # This is a file with redundant date prefix, remove it
                    new_name = content_part
                    
                    if rename_file(file_path, new_name, log_file, dry_run, organize_subfolders):
                        renamed_files += 1
                        
                        # Track subfolder creation
                        if organize_subfolders and not dry_run and new_name.count('__') >= 1:
                            project_name = get_project_folder(new_name)
                            if project_name and project_name not in created_folders:
                                created_folders.add(project_name)
                                subfolder_created += 1
                    else:
                        error_files += 1
                    continue
        
        # For files that don't need renaming, check if they should be organized into subfolders
        if organize_subfolders and '__' in filename:
            target_dir, project_name = process_file_for_subfolder(filename, log_file, directory, dry_run)
            if target_dir and project_name:
                if project_name not in created_folders:
                    created_folders.add(project_name)
                    subfolder_created += 1
                
                if move_to_subfolder(file_path, target_dir, log_file, dry_run):
                    moved_files += 1
                else:
                    error_files += 1
                continue
        
        # If we got here, no changes needed
        if debug:
            print(f"  No changes needed for this file")
        skipped_files += 1
    
    # Log summary
    summary = f"""
PROCESSING COMPLETE
Total files: {total_files}
Renamed files: {renamed_files}
Moved to subfolders: {moved_files}
Deleted files: {deleted_files}
Skipped files: {skipped_files}
Subfolders created: {subfolder_created}
Errors: {error_files}
"""
    log_action(log_file, summary)
    
    print(summary)
    print(f"Log file created at: {log_file}")

def main():
    parser = argparse.ArgumentParser(description='Fix markdown files with redundant date prefixes.')
    parser.add_argument('--directory', type=str, required=True,
                      help='Directory containing markdown files to fix')
    parser.add_argument('--delete-dot-files', action='store_true',
                      help='Delete files with "._" in their names instead of trying to fix them')
    parser.add_argument('--organize-subfolders', action='store_true',
                      help='Organize files into subfolders based on project name (after "__")')
    parser.add_argument('--dry-run', action='store_true',
                      help='Dry run mode (no actual changes)')
    parser.add_argument('--debug', action='store_true',
                      help='Enable debug output for each file')
    
    args = parser.parse_args()
    
    global DEBUG
    DEBUG = args.debug
    
    log_file = create_log_file()
    process_directory(args.directory, log_file, args.delete_dot_files, args.dry_run, args.organize_subfolders, args.debug)

if __name__ == "__main__":
    main() 