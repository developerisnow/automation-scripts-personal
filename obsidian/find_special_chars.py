import os
import re
import csv
from collections import defaultdict
import argparse
from pathlib import Path

"""
Naming Convention Prefixes:

Content Source Prefixes:
    own.    # Self-written content
    mix.    # Mixed/edited content
    ai.     # AI-generated content

Content Type Prefixes:
    =.      # Notes
    ==.     # Personal notes
    @.      # People
    @@.     # Communities
    {.      # Books
    (.      # Articles
    +.      # Videos
    %.      # Podcasts
    &.      # Papers/Academic
"""

def ensure_temp_dir():
    """Create temp directory if it doesn't exist"""
    temp_dir = Path('temp')
    temp_dir.mkdir(exist_ok=True)
    return temp_dir

def find_files_with_special_chars_no_space(root_dir):
    # Updated pattern to match both Latin and Cyrillic letters after special chars
    # Includes all content type prefixes: =, ==, @, @@, {, (, +, %, &
    pattern = re.compile(r'^([@$=]{1,2}|\{|\(|\+|\%|\&)[a-zA-Zа-яА-ЯёЁ]')
    
    # List to store matching files
    matching_files = []
    
    # Dictionary to store statistics for each special character
    char_stats = defaultdict(list)
    
    # Walk through directory
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            match = pattern.match(filename)
            if match:
                full_path = os.path.join(dirpath, filename)
                relative_path = os.path.relpath(full_path, root_dir)
                
                # Find the special character(s) at the start
                special_chars = re.match(r'^([@$=]{1,2}|\{|\(|\+|\%|\&)+', filename).group()
                
                # Store the file info
                file_info = {
                    'filename': filename,
                    'path': relative_path,
                    'full_path': full_path,
                    'special_chars': special_chars,
                    'rule': 'Special character immediately followed by letter (no dot/space)'
                }
                
                matching_files.append(file_info)
                char_stats[special_chars].append(file_info)
    
    return matching_files, char_stats

def write_csv_report(matching_files, output_dir):
    """Write results to CSV in temp directory"""
    output_file = output_dir / 'statistic_special_chars_rules.csv'
    
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['filename', 'special_character', 'rule', 'pathoffile']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for file in matching_files:
            writer.writerow({
                'filename': file['filename'],
                'special_character': file['special_chars'],
                'rule': file['rule'],
                'pathoffile': file['path']
            })
    return output_file

def clean_filename(filename, clean_options):
    """Clean filename based on specified options"""
    if not clean_options:
        return filename
        
    new_filename = filename
    options = clean_options.lower().split(',')
    
    if 'kebab' in options:
        # Replace multiple whitespaces with single hyphen
        new_filename = re.sub(r'\s+', '-', new_filename)
        
    if 'quote' in options:
        # Remove single quotes, double quotes, and smart quotes
        new_filename = re.sub(r'[\'"""'']', '', new_filename)
    
    return new_filename

def rename_matching_files(matching_files, pattern_map=None, clean_options=None):
    """Rename files according to pattern map and cleaning options"""
    if pattern_map is None:
        # Default pattern map: add dot and underscore after special character
        pattern_map = {
            # Content Type Prefixes
            '=': '=._',      # Notes
            '==': '==._',    # Personal notes
            '@': '@._',      # People
            '@@': '@@._',    # Communities
            '{': '{._',      # Books
            '(': '(._',      # Articles
            '+': '+._',      # Videos
            '%': '%._',      # Podcasts
            '&': '&._',      # Papers/Academic
            
            # Legacy/Combined patterns
            '$': '$._',
            '=$': '=$._'
        }
    
    renamed_files = []
    for file in matching_files:
        old_path = file['full_path']
        filename = file['filename']
        special_chars = file['special_chars']
        
        # First apply special character pattern
        if special_chars in pattern_map:
            new_filename = filename.replace(special_chars, pattern_map[special_chars], 1)
            
            # Then apply cleaning if requested
            if clean_options:
                new_filename = clean_filename(new_filename, clean_options)
            
            new_path = os.path.join(os.path.dirname(old_path), new_filename)
            
            print(f"DEBUG: Attempting to rename:")
            print(f"  Old filename: {filename}")
            print(f"  New filename: {new_filename}")
            print(f"  Special chars: {special_chars}")
            print(f"  Clean options: {clean_options}")
            
            if old_path != new_path:  # Only rename if the path would change
                try:
                    os.rename(old_path, new_path)
                    renamed_files.append({
                        'old': old_path,
                        'new': new_path
                    })
                    print(f"  Success: Renamed to {new_filename}")
                except OSError as e:
                    print(f"  Error renaming {old_path}: {e}")
            else:
                print("  No change needed - filenames are identical")
    
    return renamed_files

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Find and process files with special characters')
    parser.add_argument('--path', type=str, default=os.getcwd(),
                       help='Root directory to search (default: current directory)')
    parser.add_argument('--rename', action='store_true',
                       help='Rename matching files according to pattern')
    parser.add_argument('--clean', type=str,
                       help='Clean filenames: "kebab" for converting spaces to hyphens, '
                            '"quote" for removing quotes. Can combine with comma: "kebab,quote"')
    
    args = parser.parse_args()
    root_dir = args.path
    
    # Ensure temp directory exists
    temp_dir = ensure_temp_dir()
    
    # Find matching files and get statistics
    matches, char_stats = find_files_with_special_chars_no_space(root_dir)
    
    # Write CSV report
    if matches:
        output_file = write_csv_report(matches, temp_dir)
        
        print("Found files with special characters immediately followed by text:")
        print("-" * 80)
        
        # Print statistics by special character
        print("Statistics by special character pattern:")
        for char_pattern, files in char_stats.items():
            print(f"\nPattern '{char_pattern}' found in {len(files)} files:")
            for file in files:
                print(f"  - {file['path']}")
        
        print("\nDetailed file list:")
        print("-" * 80)
        for file in matches:
            print(f"File: {file['filename']}")
            print(f"Special Character(s): {file['special_chars']}")
            print(f"Path: {file['path']}")
            print(f"Rule: {file['rule']}")
            print("-" * 80)
        
        print(f"\nResults have been saved to '{output_file}'")
        
        # Rename files if requested
        if args.rename:
            renamed = rename_matching_files(matches, clean_options=args.clean)
            if renamed:
                print("\nRenamed files:")
                for file in renamed:
                    print(f"  {file['old']} -> {file['new']}")
    else:
        print("No matching files found.")

if __name__ == "__main__":
    main()