#!/usr/bin/env python3
"""
File Extensions Finder Script

This script scans one or more directories (configured at the top of the script) to gather a report of file extensions found within.
For each extension, the script counts the number of files and sums their sizes (converted to MB) and produces a CSV output.

Configuration:
  - PATHS: List of paths to scan. The script will recursively traverse each directory.
  - OUTPUT_DIR: Directory where the CSV report will be saved.
  - OUTPUT_FILENAME: Base name of the CSV report, appended with a timestamp.

CSV Structure:
  extension,amount,size-mb
  e.g.,
    pdf,99,100.00

Usage:
  Ensure the paths are correctly set, then run the script.

Logging:
  The script prints log messages for primary actions.

Safety:
  Files are only read; no modifications are performed.
"""

import os
import csv
import datetime
from pathlib import Path

# Configuration
# -------------
# List of directories (absolute or relative) to scan for file extensions
PATHS = [
    os.path.expanduser('/Users/user/____Sandruk'),  # Change or add paths as needed
    # os.path.expanduser('~/Downloads'),
]

# Output directory for the CSV report (defaults to the script directory if empty)
OUTPUT_DIR = ""


def scan_extensions(paths):
    """
    Scans the given list of directory paths recursively and gathers file extension data.

    Returns:
        A dictionary where keys are file extensions (lowercase, without the dot) and
        values are dictionaries with keys 'count' and 'total_size' in bytes.
    """
    ext_data = {}
    for base_path in paths:
        path_obj = Path(base_path)
        if not path_obj.exists() or not path_obj.is_dir():
            print(f"Warning: Path does not exist or is not a directory: {base_path}")
            continue

        print(f"Scanning directory: {base_path}")
        for root, dirs, files in os.walk(base_path):
            for file in files:
                file_path = os.path.join(root, file)
                try:
                    # Split extension using rsplit to only take the part after the last dot
                    parts = file.rsplit('.', 1)
                    if len(parts) == 2 and parts[1]:
                        ext = parts[1].lower()
                    else:
                        ext = 'no_extension'
                    
                    file_size = os.path.getsize(file_path)

                    if ext in ext_data:
                        ext_data[ext]['count'] += 1
                        ext_data[ext]['total_size'] += file_size
                    else:
                        ext_data[ext] = {'count': 1, 'total_size': file_size}
                except Exception as e:
                    print(f"Error processing file {file_path}: {e}")
                    continue
    return ext_data


def write_csv(ext_data, output_file):
    """
    Writes the extension data to a CSV file with columns: extension, amount, size-mb
    """
    with open(output_file, 'w', newline='') as csvfile:
        fieldnames = ['extension', 'amount', 'size-mb']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for ext, data in sorted(ext_data.items()):
            size_mb = data['total_size'] / (1024 * 1024)
            writer.writerow({
                'extension': ext,
                'amount': data['count'],
                'size-mb': f"{size_mb:.2f}"
            })
    print(f"CSV report written to: {output_file}")


def main():
    # Create timestamp for the output filename
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')

    # Determine output directory
    output_dir = OUTPUT_DIR if OUTPUT_DIR else os.path.dirname(os.path.abspath(__file__))
    os.makedirs(output_dir, exist_ok=True)
    
    output_file = os.path.join(output_dir, f"find_extensions-{timestamp}.csv")

    ext_data = scan_extensions(PATHS)
    if not ext_data:
        print("No file extensions found in the provided paths.")
        return

    write_csv(ext_data, output_file)
    print("Extension collection complete.")


if __name__ == "__main__":
    main()
