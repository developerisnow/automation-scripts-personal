import os
from datetime import datetime
from pathlib import Path

# Define search directories
SEARCH_DIRS = [
    "/Users/user/__Repositories/",
    "/Users/user/____Sandruk/"
]

def process_gitignore_files():
    total_files = 0
    modified_files = 0
    updated_files = []
    
    # Current timestamp for the log file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"gitignore-references-replace_{timestamp}.log"
    
    for search_dir in SEARCH_DIRS:
        # Walk through each directory
        for root, _, files in os.walk(search_dir):
            for file in files:
                if file == ".gitignore":
                    total_files += 1
                    file_path = os.path.join(root, file)
                    
                    # Read file content
                    with open(file_path, 'r') as f:
                        content = f.read()
                    
                    # Check if file contains "_references/" and replace it
                    if "_references/" in content:
                        new_content = content.replace("_references/", ".references/")
                        
                        # Write updated content
                        with open(file_path, 'w') as f:
                            f.write(new_content)
                        
                        modified_files += 1
                        updated_files.append(file_path)
                        print(f"Updated: {file_path}")
    
    # Write log file
    with open(log_file, 'w') as f:
        f.write(f"Scan completed at: {datetime.now()}\n")
        f.write(f"Total .gitignore files found: {total_files}\n")
        f.write(f"Files modified: {modified_files}\n\n")
        f.write("Modified files:\n")
        f.write("\n".join(updated_files))
    
    # Print summary
    print(f"\nSummary:")
    print(f"Total .gitignore files found: {total_files}")
    print(f"Files modified: {modified_files}")
    print(f"Log file created: {log_file}")

if __name__ == "__main__":
    process_gitignore_files()