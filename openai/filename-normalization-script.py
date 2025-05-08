#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Filename Normalization and Content Cleaning Script

Scans a directory for chat export files (e.g., from ChatGPT),
renames them to a standard format (optionally adding a timestamp),
and cleans their content by removing embedded images and specific watermarks.
"""

import os
import re
import shutil
import argparse
import logging
import sys
from pathlib import Path
from datetime import datetime

# Attempt to import transliterate, provide guidance if missing
try:
    from transliterate import translit, get_available_language_codes
    from transliterate.exceptions import LanguageCodeError
except ImportError:
    print("Error: The 'transliterate' library is required.", file=sys.stderr)
    print("Please install it using: pip install transliterate", file=sys.stderr)
    sys.exit(1)

# --- Configuration ---
DEFAULT_TARGET_DIR = "/Users/user/Downloads/chatgpt-export-chats/chatgpt-export-markdown"
DEFAULT_LOG_FILE = "/Users/user/____Sandruk/___PKM/logs/filename_normalization.log"
PROVIDER_PREFIX = "ChatGPT-" # Initial provider prefix to look for
# Regex to identify already normalized files (accounts for optional timestamp)
NORMALIZED_PATTERN = re.compile(r"^(?:\d{4}-\d{2}-\d{2}-\d{4}-)?thread-llm-ChatGPT-.*\.md$", re.IGNORECASE)
# Regex to find embedded image data (more general)
IMAGE_PATTERN = re.compile(r"!\[[^\]]*\]\(data:(?:image|application|multipart)/[^)]+\)")
# Watermarks to remove from content
WATERMARKS_TO_REMOVE = ["citeturn0search0", "", ""] # Added 

# --- Logging Setup ---
logger = logging.getLogger(__name__)

def setup_logging(log_file: str, log_level_str: str, verbose: bool):
    """Configures logging."""
    log_level = getattr(logging, log_level_str.upper(), logging.INFO)
    log_dir = Path(log_file).parent
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        print(f"Error creating log directory {log_dir}: {e}", file=sys.stderr)
        logging.basicConfig(level=log_level, format='%(asctime)s - %(levelname)s - %(message)s')
        logger.error(f"Could not create log directory {log_dir}. Logging to console only.")
        return

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.setLevel(log_level)

    # File Handler
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(log_level)
    file_handler.setFormatter(formatter)
    root_logger.addHandler(file_handler)

    # Console Handler (if verbose)
    if verbose:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(log_level)
        console_handler.setFormatter(formatter)
        root_logger.addHandler(console_handler)

    logger.info(f"Logging configured. Level: {log_level_str.upper()}, File: '{log_file}', Console: {verbose}")

# --- Normalizer Class ---
class FilenameNormalizer:
    """Handles filename normalization and content cleaning."""

    def __init__(self, target_dir: str, add_timestamp: bool):
        self.target_dir = Path(target_dir)
        self.add_timestamp = add_timestamp
        self.stats = {
            "scanned": 0,
            "considered_rename": 0,
            "renamed": 0,
            "cleaned": 0,
            "images_removed_total": 0,
            "watermarks_removed_total": 0,
            "skipped_normalized": 0,
            "skipped_collision": 0,
            "skipped_parse_error": 0,
            "skipped_cleaning_error": 0,
            "skipped_rename_error": 0,
        }
        if not self.target_dir.is_dir():
            logger.error(f"Target directory not found or is not a directory: {self.target_dir}")
            raise FileNotFoundError(f"Target directory not found: {self.target_dir}")

    def _is_already_normalized(self, filename: str) -> bool:
        """Checks if a filename matches the target normalized format."""
        return bool(NORMALIZED_PATTERN.match(filename))

    def _scan_files(self) -> list[Path]:
        """Scans target directory for all .md files."""
        md_files = []
        try:
            for item in self.target_dir.iterdir():
                self.stats["scanned"] += 1 # Count everything scanned
                if item.is_file() and item.suffix.lower() == '.md':
                    # Consider all .md files for cleaning/checking
                    md_files.append(item)
                # else:
                #    logger.debug(f"Skipping item (not an .md file): {item.name}")
            logger.info(f"Found {len(md_files)} .md files in the directory.")
        except PermissionError:
            logger.error(f"Permission denied scanning directory: {self.target_dir}")
        except Exception as e:
            logger.error(f"Error scanning directory {self.target_dir}: {e}", exc_info=True)
        return md_files

    def _get_modification_timestamp(self, file_path: Path) -> str | None:
        """Gets file modification time formatted as yyyy-mm-dd-hhmm."""
        try:
            mtime = file_path.stat().st_mtime
            dt_object = datetime.fromtimestamp(mtime)
            return dt_object.strftime("%Y-%m-%d-%H%M")
        except OSError as e:
            logger.error(f"Could not get modification time for {file_path.name}: {e}")
            return None
        except Exception as e:
             logger.error(f"Unexpected error getting timestamp for {file_path.name}: {e}", exc_info=True)
             return None

    def _parse_filename(self, filename: str) -> str | None:
        """Extracts the topic part after the provider prefix."""
        if filename.lower().startswith(PROVIDER_PREFIX.lower()):
            base_name = Path(filename).stem # Get filename without extension
            topic = base_name[len(PROVIDER_PREFIX):]
            logger.debug(f"Extracted topic '{topic}' from '{filename}'")
            return topic
        logger.warning(f"Could not parse topic from filename (prefix mismatch?): {filename}")
        return None

    def _normalize_topic(self, topic: str) -> str:
        """Normalizes the topic string according to defined rules."""
        if not topic:
            return ""
        try:
            # Transliterate Cyrillic and other non-ASCII to Latin, force lowercase
            # Use 'ru' for Russian Cyrillic transliteration rules. Adjust if needed.
            normalized = translit(topic, 'ru', reversed=True).lower()
        except LanguageCodeError:
             logger.warning(f"Language code 'ru' not available for transliteration. Falling back to basic normalization for topic: {topic}")
             normalized = topic.lower()
        except Exception as e:
            logger.error(f"Transliteration error for topic '{topic}': {e}. Falling back.", exc_info=True)
            normalized = topic.lower() # Fallback

        # Replace problematic characters and whitespace with hyphens
        # Preserve underscores by temporarily replacing them
        normalized = normalized.replace('_', '__TEMP_UNDERSCORE__')
        normalized = re.sub(r'[\s\\/?:|*<>".]+', '-', normalized) # Replace whitespace and invalid chars
        normalized = normalized.replace('__TEMP_UNDERSCORE__', '_') # Restore underscores

        # Replace multiple consecutive hyphens with a single hyphen
        normalized = re.sub(r'-+', '-', normalized)

        # Remove leading/trailing hyphens or underscores
        normalized = normalized.strip('-_')

        # Ensure it's not empty after stripping
        if not normalized:
             # Fallback for topics that become empty (e.g., just symbols)
             normalized = "untitled"
             logger.warning(f"Topic '{topic}' resulted in empty normalized string, using 'untitled'.")


        logger.debug(f"Normalized topic '{topic}' -> '{normalized}'")
        return normalized

    def _clean_file_content(self, file_path: Path) -> tuple[int, int]:
        """Removes images and watermarks from file content."""
        images_removed = 0
        watermarks_removed = 0
        try:
            with file_path.open('r', encoding='utf-8') as f:
                content = f.read()

            original_content = content

            # Remove images
            new_content, img_count = IMAGE_PATTERN.subn('', content)
            if img_count > 0:
                images_removed += img_count
                content = new_content
                logger.debug(f"Removed {img_count} image patterns from {file_path.name}")

            # Remove watermarks
            for wm in WATERMARKS_TO_REMOVE:
                wm_count = content.count(wm)
                if wm_count > 0:
                    content = content.replace(wm, '')
                    watermarks_removed += wm_count
                    logger.debug(f"Removed {wm_count} instances of watermark '{wm}' from {file_path.name}")

            # Write back only if changes were made
            if content != original_content:
                with file_path.open('w', encoding='utf-8') as f:
                    f.write(content)
                logger.info(f"Cleaned content in {file_path.name} (Images: {images_removed}, Watermarks: {watermarks_removed})")
                self.stats["cleaned"] += 1
            else:
                 logger.debug(f"No content changes needed for {file_path.name}")


        except OSError as e:
            logger.error(f"Error reading/writing file during cleaning {file_path.name}: {e}")
            self.stats["skipped_cleaning_error"] += 1
            return 0, 0 # Return 0 counts if error occurred
        except Exception as e:
            logger.error(f"Unexpected error cleaning file {file_path.name}: {e}", exc_info=True)
            self.stats["skipped_cleaning_error"] += 1
            return 0, 0
        return images_removed, watermarks_removed

    def _rename_file(self, old_path: Path, new_filename: str) -> bool:
        """Renames the file, handling potential collisions. Returns True on success, False on failure."""
        if not new_filename:
             logger.error(f"Cannot rename {old_path.name}: generated new filename is empty.")
             self.stats["skipped_rename_error"] += 1
             return False

        new_path = old_path.parent / new_filename
        if old_path == new_path:
            # This case should ideally be caught before calling _rename_file
            logger.debug(f"Skipping rename for {old_path.name}: new name is identical.")
            return False # No rename needed/performed

        try:
            if new_path.exists():
                logger.warning(f"Skipping rename for {old_path.name}: target file {new_filename} already exists.")
                self.stats["skipped_collision"] += 1
                return False

            shutil.move(str(old_path), str(new_path))
            logger.info(f"Renamed '{old_path.name}' -> '{new_filename}'")
            self.stats["renamed"] += 1
            return True

        except OSError as e:
            logger.error(f"OS error renaming file {old_path.name} to {new_filename}: {e}")
            self.stats["skipped_rename_error"] += 1
            return False
        except Exception as e:
            logger.error(f"Unexpected error renaming file {old_path.name}: {e}", exc_info=True)
            self.stats["skipped_rename_error"] += 1
            return False

    def run(self):
        """Executes the normalization and cleaning process."""
        logger.info(f"Starting filename normalization and cleaning in '{self.target_dir}'...")
        logger.info(f"Timestamp prefix {'enabled' if self.add_timestamp else 'disabled'}.")

        all_md_files = self._scan_files()

        if not all_md_files:
            logger.info("No .md files found in the directory.")
            self._log_summary()
            return

        for current_path in all_md_files:
            logger.debug(f"Processing file: {current_path.name}")
            original_name = current_path.name
            file_path_to_clean = current_path # Start with the current path for cleaning
            file_renamed_in_this_pass = False

            # 1. Check if Renaming is Needed (based on original name)
            if not self._is_already_normalized(original_name):
                self.stats["considered_rename"] += 1
                topic = self._parse_filename(original_name)
                if topic is not None:
                    normalized_topic = self._normalize_topic(topic)
                    if normalized_topic:
                        # Construct potential new filename
                        timestamp_prefix = ""
                        if self.add_timestamp:
                            timestamp = self._get_modification_timestamp(current_path)
                            if timestamp:
                                timestamp_prefix = f"{timestamp}-"
                            else:
                                logger.warning(f"Could not get timestamp for {original_name}, omitting prefix for potential rename.")

                        new_filename = f"{timestamp_prefix}thread-llm-{PROVIDER_PREFIX}{normalized_topic}.md"

                        if new_filename != original_name:
                            # Perform Renaming
                            renamed_successfully = self._rename_file(current_path, new_filename)
                            if renamed_successfully:
                                # Update the path for the cleaning step
                                file_path_to_clean = self.target_dir / new_filename
                                file_renamed_in_this_pass = True
                            # else: Rename error already logged by _rename_file
                        else:
                             logger.debug(f"Constructed name '{new_filename}' is identical to original '{original_name}'. No rename needed.")
                             self.stats["skipped_normalized"] += 1 # Count as skipped normalized if generated name is same

                    else: # Normalized topic was empty
                        logger.warning(f"Skipping rename for {original_name} due to empty normalized topic.")
                        self.stats["skipped_rename_error"] += 1
                else: # Topic parse failed
                     self.stats["skipped_parse_error"] += 1
                     logger.warning(f"Skipping rename for {original_name}: Could not parse topic.")
            else:
                 # Log files whose names were already correct before this pass
                 self.stats["skipped_normalized"] += 1
                 logger.debug(f"Skipping rename for {original_name}: Already normalized.")

            # 2. Clean Content (using the potentially updated path)
            if file_path_to_clean.exists():
                img_removed, wm_removed = self._clean_file_content(file_path_to_clean)
                self.stats["images_removed_total"] += img_removed
                self.stats["watermarks_removed_total"] += wm_removed
            else:
                 # This might happen if rename failed critically or file disappeared
                 logger.error(f"Cannot clean file {original_name} (or its renamed version): Path {file_path_to_clean} not found.")
                 # Don't increment cleaning error if it was due to rename failure already logged
                 if not file_renamed_in_this_pass: # Only count as cleaning error if rename wasn't attempted/failed
                    # Check if original path exists, if not, it's a real issue
                    if not current_path.exists():
                         self.stats["skipped_cleaning_error"] += 1


        self._log_summary()
        logger.info("Filename normalization and cleaning process finished.")

    def _log_summary(self):
        """Logs summary statistics."""
        logger.info("--- Summary ---")
        logger.info(f"Files Scanned: {self.stats['scanned']}")
        logger.info(f"Files Considered for Rename: {self.stats['considered_rename']}")
        logger.info(f"Files Successfully Renamed: {self.stats['renamed']}")
        logger.info(f"Files Content Cleaned: {self.stats['cleaned']}")
        logger.info(f"Total Images Removed: {self.stats['images_removed_total']}")
        logger.info(f"Total Watermarks Removed: {self.stats['watermarks_removed_total']}")
        logger.info(f"Skipped (Already Normalized): {self.stats['skipped_normalized']}")
        logger.info(f"Skipped (Collision): {self.stats['skipped_collision']}")
        logger.info(f"Skipped (Parse Error): {self.stats['skipped_parse_error']}")
        logger.info(f"Skipped (Cleaning Error): {self.stats['skipped_cleaning_error']}")
        logger.info(f"Skipped (Rename Error): {self.stats['skipped_rename_error']}")
        logger.info("---------------")

# --- Main Execution ---
def main():
    """Parses arguments and runs the normalizer."""
    parser = argparse.ArgumentParser(
        description="Normalize filenames and clean content of chat exports (e.g., ChatGPT).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--dir",
        default=DEFAULT_TARGET_DIR,
        help="Directory containing the chat export files."
    )
    parser.add_argument(
        "--add-timestamp",
        action="store_true",
        help="Add 'yyyy-mm-dd-hhmm-' prefix based on file modification time."
    )
    parser.add_argument(
        "--log-file",
        default=DEFAULT_LOG_FILE,
        help="Path to the log file."
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        help="Set the logging level."
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose logging to console (INFO level)."
    )

    # Quick check for transliterate availability early on
    if 'transliterate' not in sys.modules:
         print("Transliterate library check failed earlier. Exiting.", file=sys.stderr)
         sys.exit(1)
    # Check if Russian language pack is available for transliterate
    if 'ru' not in get_available_language_codes():
        logger.warning("Russian ('ru') language pack for 'transliterate' not found. Cyrillic conversion might not work as expected.")


    args = parser.parse_args()

    # Setup logging
    setup_logging(args.log_file, args.log_level, args.verbose)

    try:
        normalizer = FilenameNormalizer(target_dir=args.dir, add_timestamp=args.add_timestamp)
        normalizer.run()
    except FileNotFoundError as e:
        logger.critical(f"Initialization failed: {e}")
        sys.exit(1)
    except Exception as e:
        logger.critical(f"An unexpected critical error occurred: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()
