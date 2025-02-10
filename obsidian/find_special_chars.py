import os
import re
import csv
from collections import defaultdict

def find_files_with_special_chars_no_space(root_dir):
    # Pattern to match: special character immediately followed by text (no dot or space)
    pattern = re.compile(r'^[@$=]+[a-zA-Z]')
    
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
                special_chars = re.match(r'^[@$=]+', filename).group()
                
                # Store the file info
                file_info = {
                    'filename': filename,
                    'path': relative_path,
                    'special_chars': special_chars,
                    'rule': 'Special character immediately followed by letter (no dot/space)'
                }
                
                matching_files.append(file_info)
                char_stats[special_chars].append(file_info)
    
    return matching_files, char_stats

def write_csv_report(matching_files, output_file='statistic_special_chars_rules.csv'):
    # Write results to CSV
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

def main():
    # Get current directory
    root_dir = os.getcwd()
    
    # Find matching files and get statistics
    matches, char_stats = find_files_with_special_chars_no_space(root_dir)
    
    # Write CSV report
    write_csv_report(matches)
    
    # Print results
    if matches:
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
        
        print(f"\nResults have been saved to 'statistic_special_chars_rules.csv'")
    else:
        print("No matching files found.")

if __name__ == "__main__":
    main() 