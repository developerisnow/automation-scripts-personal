import os
import csv
from datetime import datetime
import logging
import argparse

def setup_logging():
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = f'temp/delete_files_{timestamp}.log'
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    return log_file

def find_empty_markdown_files(root_dir):
    empty_files = []
    
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.md'):
                filepath = os.path.join(dirpath, filename)
                size = os.path.getsize(filepath)
                
                if size == 0:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        lines = len(f.readlines())
                    
                    empty_files.append({
                        'filename': filename,
                        'size': size,
                        'lines': lines,
                        'path': filepath
                    })
    
    return empty_files

def save_to_csv(empty_files, output_file):
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['filename', 'size', 'lines', 'path'])
        writer.writeheader()
        writer.writerows(empty_files)

def delete_empty_files(config_file):
    deleted_count = 0
    
    with open(config_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            file_path = row['path']
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                    logging.info(f"Deleted: {file_path}")
                    deleted_count += 1
                except Exception as e:
                    logging.error(f"Error deleting {file_path}: {str(e)}")
            else:
                logging.warning(f"File not found: {file_path}")
    
    return deleted_count

def main():
    parser = argparse.ArgumentParser(description='Find and delete empty markdown files')
    parser.add_argument('--action', choices=['analyze', 'delete'], required=True,
                      help='Choose to analyze files or delete them')
    parser.add_argument('--dir', default='/Users/user/____Sandruk/___PKM/__SecondBrain/__Personal_Notes/Dailies_Notes',
                      help='Directory to scan for empty markdown files')
    args = parser.parse_args()

    # Create temp directory if it doesn't exist
    os.makedirs('temp', exist_ok=True)
    
    # Setup logging
    log_file = setup_logging()
    config_file = 'temp/empty_files.csv'

    if args.action == 'analyze':
        # Find empty files and save to CSV
        logging.info(f"Starting analysis of directory: {args.dir}")
        empty_files = find_empty_markdown_files(args.dir)
        save_to_csv(empty_files, config_file)
        logging.info(f"Analysis complete. Found {len(empty_files)} empty files")
        logging.info(f"Results saved to: {config_file}")

    elif args.action == 'delete':
        if not os.path.exists(config_file):
            logging.error(f"Config file not found: {config_file}")
            return
        
        # Delete files and log results
        logging.info(f"Starting deletion process using config: {config_file}")
        deleted_count = delete_empty_files(config_file)
        logging.info(f"Deletion complete. {deleted_count} files deleted")

    logging.info(f"Log file created: {log_file}")

if __name__ == "__main__":
    main()