import os
import sys
import argparse
from datetime import datetime
import csv
from pathlib import Path
from enum import Enum
import shutil

class RenameFunction(Enum):
    REPLACE = 'replace'
    SUFFIX = 'suffix'
    PREFIX = 'prefix'

class TargetType(Enum):
    FILES = 'files'
    FOLDERS = 'folders'
    ALL = 'all'

def create_log_file():
    """Create a log file with timestamp."""
    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M")
    log_filename = f"log-renamer-{timestamp}.csv"
    
    with open(log_filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['found_name', 'renamed_name', 'path', 'type'])
    
    return log_filename

def log_rename_operation(log_filename, original_name, new_name, file_path, item_type):
    """Log the rename operation to CSV file."""
    with open(log_filename, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([original_name, new_name, file_path, item_type])

def generate_new_name(filename, search_keyword, replace_keyword, function):
    """Generate new filename based on the selected function."""
    if function == RenameFunction.REPLACE:
        return filename.replace(search_keyword, replace_keyword)
    elif function == RenameFunction.SUFFIX:
        return f"{filename}{replace_keyword}"
    elif function == RenameFunction.PREFIX:
        return f"{replace_keyword}{filename}"
    
    return filename

def validate_operation(function, target_type):
    """Validate if the operation is allowed for the target type."""
    if function in [RenameFunction.SUFFIX, RenameFunction.PREFIX] and target_type == TargetType.FILES:
        print("Error: Suffix and Prefix operations are only allowed for folders!")
        return False
    if function == RenameFunction.REPLACE and target_type == TargetType.FOLDERS:
        print("Error: Replace operation is only allowed for files!")
        return False
    return True

def normalize_name(name, suffix):
    """Remove multiple occurrences of suffix and ensure only one at the end."""
    # Remove all occurrences of the suffix
    while suffix in name:
        name = name.replace(suffix, '')
    # Add suffix once
    return f"{name}{suffix}"

def find_and_rename_items(search_keyword, replace_keyword, start_path, log_filename, function, target_type, starts=''):
    """Find and rename items based on target type and function."""
    items_found = []
    processed_paths = set()
    
    start_path = Path(start_path)
    
    for root, dirs, files in os.walk(start_path, topdown=True):
        root_path = Path(root)
        
        if target_type in [TargetType.FOLDERS, TargetType.ALL]:
            for dirname in dirs[:]:
                if starts and not dirname.startswith(starts):
                    continue
                
                full_path = root_path / dirname
                str_path = str(full_path)
                
                if str_path in processed_paths:
                    continue
                
                try:
                    # Normalize the name (remove multiple suffixes if present)
                    normalized_name = normalize_name(dirname, replace_keyword)
                    
                    # Skip if the name is already normalized
                    if normalized_name == dirname:
                        continue
                        
                    new_path = root_path / normalized_name
                    
                    if len(str(new_path)) >= 255:
                        print(f"Warning: Path too long, skipping: {dirname}")
                        continue
                    
                    items_found.append((full_path, normalized_name, 'folder'))
                    processed_paths.add(str_path)
                    
                except Exception as e:
                    print(f"Warning: Error processing directory {dirname}: {str(e)}")
                    continue
    
    return items_found  # Return the items found

def main():
    parser = argparse.ArgumentParser(description='Rename files or folders using different functions.')
    parser.add_argument('search_keyword', help='Keyword to search for in names (required for replace function)')
    parser.add_argument('replace_keyword', help='Text to use for replacement/suffix/prefix')
    parser.add_argument('--path', help='Path to start search from', default=os.getcwd())
    parser.add_argument('--function', 
                       choices=[f.value for f in RenameFunction], 
                       default='replace',
                       help='Renaming function to use (replace for files, suffix/prefix for folders)')
    parser.add_argument('--type',
                       choices=[t.value for t in TargetType],
                       default='files',
                       help='Target type to rename (files, folders, or all)')
    parser.add_argument('--starts',
                       help='Only process items starting with this pattern (e.g., "_")',
                       default='')
    
    args = parser.parse_args()
    
    # Validate path
    if not os.path.exists(args.path):
        print(f"Error: Path '{args.path}' does not exist.")
        return
    
    # Validate operation
    function = RenameFunction(args.function)
    target_type = TargetType(args.type)
    if not validate_operation(function, target_type):
        return
    
    # Create log file
    log_filename = create_log_file()
    
    # Find matching items
    items_found = find_and_rename_items(
        args.search_keyword, 
        args.replace_keyword, 
        args.path, 
        log_filename,
        function,
        target_type,
        args.starts
    )
    
    if not items_found:
        print("No items found to process")
        return
    
    # Show preview
    print("\nItems to be renamed:")
    for i, (old_path, new_name, item_type) in enumerate(items_found, 1):
        print(f"{i}. [{item_type}] {old_path.name} -> {new_name}")
    
    # Ask for confirmation
    response = input("\nDo you want to proceed with renaming? (y/n): ").lower()
    if response != 'y':
        print("Operation cancelled.")
        return
    
    # Perform renaming
    for old_path, new_name, item_type in reversed(items_found):
        try:
            new_path = old_path.parent / new_name
            old_path.rename(new_path)
            log_rename_operation(
                log_filename,
                old_path.name,
                new_name,
                str(old_path.parent),
                item_type
            )
            print(f"Renamed {item_type}: {old_path.name} -> {new_name}")
        except Exception as e:
            print(f"Error renaming {old_path.name}: {str(e)}")

if __name__ == "__main__":
    main()