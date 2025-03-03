#!/usr/bin/env python3
"""
Folder Synchronization Script

This script synchronizes folders based on comparison results from compare_folders.py.
It ensures data from duplicate folders is properly merged into the main folder while
preserving all important data through backups.
"""

import os
import csv
import shutil
import subprocess
import datetime
import logging
import sys
from pathlib import Path

# Configuration
# -------------
# Main folder path (source)
MAIN_FOLDER = os.path.expanduser("~/__  epositories")
# MAIN_FOLDER = os.path.expanduser("~/__Repositories")

# List of duplicate folder paths
DUPLICATE_FOLDERS = [
    os.path.expanduser("~/NextCloud2_0"),
    # os.path.expanduser("~/__Repositories0"),
    # os.path.expanduser("~/__Repositories1")
]

# Path to the comparison CSV file
COMPARISON_CSV = os.path.expanduser("~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/compare/compare_folders-2025-02-25-1213.csv")

# Output directory for logs (defaults to script directory if empty)
OUTPUT_DIR = ""

# Backup options
CREATE_BACKUPS = True
COMPRESSION_LEVEL = 15  # zstd compression level

# Cleanup options
REMOVE_DUPLICATES = False  # Set to False as requested for this run

def setup_logging():
    """Set up logging configuration."""
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    
    # Determine output directory
    output_directory = OUTPUT_DIR if OUTPUT_DIR else os.path.dirname(os.path.abspath(__file__))
    os.makedirs(output_directory, exist_ok=True)
    
    # Set log file path
    log_file = os.path.join(output_directory, f"log-sync-folders-{timestamp}.log")
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    return log_file

def create_backup(folder_path, backup_dir=None):
    """Create a compressed backup of a folder."""
    if not os.path.exists(folder_path):
        logging.warning(f"Cannot backup non-existent folder: {folder_path}")
        return None
    
    folder_name = os.path.basename(folder_path)
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    
    # Determine backup directory
    if backup_dir is None:
        backup_dir = os.path.dirname(folder_path)
    
    # Create backup filename
    backup_file = os.path.join(backup_dir, f"backup_{folder_name}.orig.tar.zst")
    
    try:
        # Create backup using tar with zstd compression
        cmd = [
            "tar", 
            f"--zstd", 
            f"-I", f"zstd -{COMPRESSION_LEVEL}", 
            "-cf", 
            backup_file, 
            "-C", 
            os.path.dirname(folder_path), 
            folder_name
        ]
        
        logging.info(f"Creating backup: {backup_file}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            logging.error(f"Backup failed: {result.stderr}")
            return None
        
        logging.info(f"Backup created successfully: {backup_file}")
        return backup_file
    except Exception as e:
        logging.error(f"Error creating backup: {e}")
        return None

def sync_folder(source_path, dest_path):
    """Synchronize a folder from source to destination."""
    try:
        if os.path.exists(dest_path):
            logging.info(f"Updating existing folder: {dest_path}")
            # Remove destination folder
            shutil.rmtree(dest_path)
        else:
            logging.info(f"Creating new folder: {dest_path}")
        
        # Copy source folder to destination
        shutil.copytree(source_path, dest_path)
        logging.info(f"Successfully synchronized: {source_path} -> {dest_path}")
        return True
    except Exception as e:
        logging.error(f"Error synchronizing folder: {e}")
        return False

def parse_csv(csv_path):
    """Parse the comparison CSV file and return folders to sync."""
    folders_to_sync = []
    
    try:
        with open(csv_path, 'r', newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                folders_to_sync.append({
                    'folder': row['folder'],
                    'source': row['source'],
                    'reason': row['reason']
                })
        
        logging.info(f"Found {len(folders_to_sync)} folders to sync from {csv_path}")
        return folders_to_sync
    except Exception as e:
        logging.error(f"Error parsing CSV file: {e}")
        return []

def main():
    """Main function to synchronize folders."""
    # Set up logging
    log_file = setup_logging()
    logging.info("Starting folder synchronization")
    logging.info(f"Main folder: {MAIN_FOLDER}")
    logging.info(f"Duplicate folders: {DUPLICATE_FOLDERS}")
    logging.info(f"Comparison CSV: {COMPARISON_CSV}")
    logging.info(f"Remove duplicates after sync: {REMOVE_DUPLICATES}")
    
    # Parse CSV file
    folders_to_sync = parse_csv(COMPARISON_CSV)
    if not folders_to_sync:
        logging.error("No folders to sync. Exiting.")
        return
    
    # Track successful syncs for each duplicate folder
    successful_syncs = {dup_folder: [] for dup_folder in DUPLICATE_FOLDERS}
    
    # Process each folder to sync
    for folder_info in folders_to_sync:
        folder_name = folder_info['folder']
        source_folder = folder_info['source']
        reason = folder_info['reason']
        
        source_path = os.path.join(source_folder, folder_name)
        dest_path = os.path.join(MAIN_FOLDER, folder_name)
        
        logging.info(f"Processing folder: {folder_name} (Reason: {reason})")
        
        # Create backup of destination folder if it exists and backups are enabled
        if CREATE_BACKUPS and os.path.exists(dest_path):
            backup_file = create_backup(dest_path)
            if not backup_file:
                logging.warning(f"Skipping sync for {folder_name} due to backup failure")
                continue
        
        # Synchronize folder
        if sync_folder(source_path, dest_path):
            # Track successful sync
            for dup_folder in DUPLICATE_FOLDERS:
                if source_folder == dup_folder:
                    successful_syncs[dup_folder].append(folder_name)
    
    # Remove duplicate folders if requested
    if REMOVE_DUPLICATES:
        for dup_folder in DUPLICATE_FOLDERS:
            if os.path.exists(dup_folder):
                # Create backup of entire duplicate folder if backups are enabled
                if CREATE_BACKUPS:
                    backup_file = create_backup(dup_folder)
                    if not backup_file:
                        logging.warning(f"Skipping removal of {dup_folder} due to backup failure")
                        continue
                
                # Remove duplicate folder
                try:
                    logging.info(f"Removing duplicate folder: {dup_folder}")
                    shutil.rmtree(dup_folder)
                    logging.info(f"Successfully removed: {dup_folder}")
                except Exception as e:
                    logging.error(f"Error removing duplicate folder: {e}")
    else:
        logging.info("Skipping removal of duplicate folders as REMOVE_DUPLICATES is set to False")
    
    # Log summary
    logging.info("Synchronization complete")
    logging.info(f"Total folders processed: {len(folders_to_sync)}")
    for dup_folder in DUPLICATE_FOLDERS:
        logging.info(f"Folders synced from {dup_folder}: {len(successful_syncs[dup_folder])}")
    
    logging.info(f"Log file: {log_file}")

if __name__ == "__main__":
    main()
