import os
import sys
from datetime import datetime
import csv

def normalize_content(content):
    """Normalize content by properly handling newlines and escape sequences"""
    # Replace literal '\n' with actual newlines
    content = content.replace('\\n', '\n')
    
    # Ensure content starts with newline if it doesn't already
    if not content.startswith('\n'):
        content = '\n' + content
        
    # Ensure content ends with newline if it doesn't already
    if not content.endswith('\n'):
        content = content + '\n'
    
    return content

def update_files_recursively(base_path, filename_pattern, content):
    # Get current timestamp
    timestamp = datetime.now().strftime('%Y-%m-%d-%H%M')
    csv_filename = f'addContentToFiles-{timestamp}.csv'
    
    # Normalize the content
    content = normalize_content(content)
    
    # List to store results
    results = []
    
    # Walk through directory tree
    for root, dirs, files in os.walk(base_path):
        for file in files:
            if file == filename_pattern:
                file_path = os.path.join(root, file)
                try:
                    # Read existing content and check if our content is already there
                    with open(file_path, 'r') as f:
                        existing_content = f.read()
                        lines_before = len(existing_content.splitlines())
                    
                    # Only append if content isn't already present
                    if content.strip() not in existing_content:
                        # Ensure file ends with newline before appending
                        if existing_content and not existing_content.endswith('\n'):
                            existing_content += '\n'
                            
                        # Append content
                        new_content = existing_content + content
                        
                        with open(file_path, 'w') as f:
                            f.write(new_content)
                        
                        # Count lines after update
                        lines_after = len(new_content.splitlines())
                        lines_added = lines_after - lines_before
                        
                        # Store result
                        results.append({
                            'filename': file,
                            'rows_before': lines_before,
                            'rows_after': lines_after,
                            'rows_added': lines_added,
                            'path': file_path,
                            'date': timestamp
                        })
                    else:
                        print(f"Content already exists in {file_path}, skipping...")
                    
                except Exception as e:
                    print(f"Error processing {file_path}: {str(e)}")
    
    # Write results to CSV
    if results:
        with open(csv_filename, 'w', newline='') as csvfile:
            fieldnames = ['filename', 'rows_before', 'rows_after', 'rows_added', 'path', 'date']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for result in results:
                writer.writerow(result)
        print(f"Updated {len(results)} files. Results saved to {csv_filename}")
    else:
        print(f"No files were updated. Either no matches for '{filename_pattern}' found in {base_path} or content already existed.")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python updateFilesRecursively.py <base_path> <filename_pattern> <content>")
        sys.exit(1)
    
    base_path = sys.argv[1]
    filename_pattern = sys.argv[2]
    content = sys.argv[3]
    
    update_files_recursively(base_path, filename_pattern, content)
