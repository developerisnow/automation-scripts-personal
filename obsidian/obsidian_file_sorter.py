#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Obsidian File Sorter Script

This script scans a specified root directory for Markdown (.md) files
and moves them into designated subfolders based on rules defined in a CSV file.
It includes logging and command-line argument handling.
"""

import os
import shutil
import csv
import argparse
import logging
import sys
from pathlib import Path

# Default paths (adjust if necessary)
DEFAULT_ROOT_DIR = "/Users/user/____Sandruk/___PKM/"
DEFAULT_CONFIG_FILE = "/Users/user/____Sandruk/___PKM/obsidian-files-sorter-config-script.csv"
DEFAULT_LOG_FILE = "/Users/user/____Sandruk/___PKM/logs/obsidian_file_sorter.log"

# Setup basic logger config - will be refined in setup_logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class FileSorter:
    """
    Handles scanning, matching, and moving Obsidian Markdown files based on CSV rules.
    """
    def __init__(self, root_dir: str, config_path: str):
        """
        Initializes the FileSorter.

        Args:
            root_dir (str): The root directory of the Obsidian vault to scan.
            config_path (str): The path to the CSV configuration file.
        """
        self.root_dir = Path(root_dir)
        self.config_path = Path(config_path)
        self.rules = []

        if not self.root_dir.is_dir():
            logger.error(f"Root directory not found or is not a directory: {self.root_dir}")
            raise FileNotFoundError(f"Root directory not found: {self.root_dir}")
        if not self.config_path.is_file():
            logger.error(f"Configuration file not found: {self.config_path}")
            raise FileNotFoundError(f"Configuration file not found: {self.config_path}")

        self._load_rules()

    def _load_rules(self):
        """
        Loads sorting rules from the CSV configuration file.
        Expected format: 'match-part','path' (header row optional but skipped).
        """
        try:
            with open(self.config_path, mode='r', newline='', encoding='utf-8') as csvfile:
                reader = csv.reader(csvfile)
                header = next(reader, None) # Skip header row
                if header and header == ['match-part', 'path']:
                     logger.info(f"Skipping header row in CSV: {header}")
                else:
                    # If no header or unexpected header, process the first row as data
                    if header:
                        self.rules.append((header[0], Path(header[1])))

                for i, row in enumerate(reader):
                    if len(row) == 2:
                        match_part = row[0].strip()
                        target_path = Path(row[1].strip())
                        if match_part and target_path:
                            self.rules.append((match_part, target_path))
                        else:
                            logger.warning(f"Skipping invalid rule in CSV line {i+2}: {row}")
                    else:
                        logger.warning(f"Skipping malformed rule in CSV line {i+2}: {row}")
            logger.info(f"Loaded {len(self.rules)} rules from {self.config_path}")
            if not self.rules:
                 logger.warning("No valid rules loaded from the configuration file.")

        except FileNotFoundError:
            logger.error(f"Configuration file not found during rule loading: {self.config_path}")
            raise
        except csv.Error as e:
            logger.error(f"Error reading CSV file {self.config_path}: {e}")
            raise
        except Exception as e:
            logger.error(f"An unexpected error occurred while loading rules: {e}")
            raise

    def _scan_files(self) -> list[Path]:
        """
        Scans the root directory for .md files (non-recursive).

        Returns:
            list[Path]: A list of Path objects for .md files found.
        """
        try:
            md_files = [f for f in self.root_dir.iterdir() if f.is_file() and f.suffix.lower() == '.md']
            logger.info(f"Found {len(md_files)} .md files in {self.root_dir}")
            return md_files
        except PermissionError:
            logger.error(f"Permission denied when scanning directory: {self.root_dir}")
            return []
        except Exception as e:
            logger.error(f"An error occurred while scanning files: {e}")
            return []

    def _match_rule(self, filename: str) -> Path | None:
        """
        Finds the first matching rule for a given filename (case-insensitive).

        Args:
            filename (str): The name of the file to match.

        Returns:
            Path | None: The target directory Path if a match is found, otherwise None.
        """
        filename_lower = filename.lower()
        for match_part, target_path in self.rules:
            # Simple case-insensitive substring matching
            if match_part.lower() in filename_lower:
                logger.debug(f"Matched (case-insensitive) '{filename}' with rule '{match_part}' -> '{target_path}'")
                return target_path
        return None

    def _move_file(self, source_path: Path, target_dir: Path):
        """
        Moves a file to the target directory, creating it if necessary.
        Handles potential filename collisions by skipping the move.

        Args:
            source_path (Path): The path to the file to move.
            target_dir (Path): The destination directory path.
        """
        target_file_path = target_dir / source_path.name

        try:
            # Ensure target directory exists
            if not target_dir.exists():
                logger.warning(f"Target directory does not exist, creating: {target_dir}")
                target_dir.mkdir(parents=True, exist_ok=True)
            elif not target_dir.is_dir():
                 logger.error(f"Target path exists but is not a directory, skipping move: {target_dir}")
                 return

            # Check for filename collision
            if target_file_path.exists():
                logger.warning(f"Filename collision: '{source_path.name}' already exists in '{target_dir}'. Skipping move.")
                return

            # Move the file
            shutil.move(str(source_path), str(target_file_path))
            logger.info(f"Moved '{source_path.name}' to '{target_dir}'")

        except OSError as e:
            logger.error(f"OS error moving file {source_path} to {target_dir}: {e}")
        except Exception as e:
            logger.error(f"Unexpected error moving file {source_path}: {e}")

    def run(self):
        """
        Executes the file sorting process: scan, match, and move.
        """
        logger.info("Starting Obsidian file sorting process...")
        files_to_process = self._scan_files()
        moved_count = 0

        if not files_to_process:
            logger.info("No .md files found to process.")
            logger.info("Obsidian file sorting process finished.")
            return

        if not self.rules:
             logger.warning("No rules loaded, cannot sort files.")
             logger.info("Obsidian file sorting process finished.")
             return

        for file_path in files_to_process:
            target_dir = self._match_rule(file_path.name)
            if target_dir:
                self._move_file(file_path, target_dir)
                moved_count += 1
            else:
                logger.debug(f"No matching rule found for '{file_path.name}'.")

        logger.info(f"Processed {len(files_to_process)} files, moved {moved_count} files.")
        logger.info("Obsidian file sorting process finished.")


def setup_logging(log_file: str, log_level_str: str, verbose: bool):
    """
    Configures logging based on command-line arguments.

    Args:
        log_file (str): Path to the log file.
        log_level_str (str): Logging level name (e.g., 'INFO', 'DEBUG').
        verbose (bool): If True, also log to console at the specified level.
    """
    log_level = getattr(logging, log_level_str.upper(), logging.INFO)

    # Ensure log directory exists
    log_dir = Path(log_file).parent
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        print(f"Error creating log directory {log_dir}: {e}", file=sys.stderr)
        # Fallback to logging only to console if dir creation fails
        logging.basicConfig(level=log_level, format='%(asctime)s - %(levelname)s - %(message)s')
        logger.error(f"Could not create log directory {log_dir}. Logging to console only.")
        return

    # Create handlers
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(log_level)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(formatter)

    # Clear existing handlers and add file handler
    # (prevents duplicate logs if script is run multiple times in same process)
    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(file_handler)
    root_logger.setLevel(log_level) # Set root logger level

    # Add console handler if verbose
    if verbose:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(log_level)
        console_handler.setFormatter(formatter)
        root_logger.addHandler(console_handler)

    logger.info(f"Logging configured. Level: {log_level_str.upper()}, File: '{log_file}', Console (Verbose): {verbose}")


def main():
    """
    Main function to parse arguments and run the FileSorter.
    """
    parser = argparse.ArgumentParser(description="Obsidian File Sorter: Sorts .md files based on rules in a CSV.")
    parser.add_argument(
        "--root-dir",
        default=DEFAULT_ROOT_DIR,
        help=f"Root directory to scan for .md files. Default: {DEFAULT_ROOT_DIR}"
    )
    parser.add_argument(
        "--config",
        default=DEFAULT_CONFIG_FILE,
        help=f"Path to the CSV configuration file. Default: {DEFAULT_CONFIG_FILE}"
    )
    parser.add_argument(
        "--log-file",
        default=DEFAULT_LOG_FILE,
        help=f"Path to the log file. Default: {DEFAULT_LOG_FILE}"
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        help="Set the logging level. Default: INFO"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose logging to console."
    )

    args = parser.parse_args()

    # Setup logging first
    setup_logging(args.log_file, args.log_level, args.verbose)

    try:
        sorter = FileSorter(root_dir=args.root_dir, config_path=args.config)
        sorter.run()
    except FileNotFoundError as e:
        logger.critical(f"Initialization failed: {e}")
        sys.exit(1)
    except Exception as e:
        logger.critical(f"An unexpected critical error occurred: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()
