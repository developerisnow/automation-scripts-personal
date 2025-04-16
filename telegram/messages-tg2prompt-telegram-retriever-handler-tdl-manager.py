#!/usr/bin/env python3
"""
Telegram Message Retrieval and Processing Utility

This script provides a convenient interface for retrieving and processing Telegram messages
using the TDLib CLI (tdl) tool. It converts raw JSON output to formatted Markdown for better readability.

Key features:
- Contact lookup by ID, username, or alias
- Message retrieval with flexible time filtering (days, weeks, months, etc.)
- JSON to Markdown conversion with customizable formatting
- Archive management for previous exports
- Visualization of message statistics

Dependencies:
- tdl: Telegram CLI based on TDLib
- tgJson2Markdown.py: Script for converting JSON to Markdown

Usage examples:
  python telegram-retriever-handler.py load-contacts
  python telegram-retriever-handler.py get-messages @username 7d
  python telegram-retriever-handler.py find-contact john

Author: SecondBrainInc
"""
import os
import sys
import re
import csv
import json
import argparse
import subprocess
import shutil
import glob
from datetime import datetime, timedelta
import logging
from typing import Dict, List, Tuple, Optional, Union, Any
import time
import tempfile

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Constants - default values that can be overridden via command line
DEFAULT_PATHS = {
    "tdl_path": "/Users/user/__Repositories/tg-tdl-client-scrapper__iyear/tdl",
    "contacts_dir": "/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts",
    "raw_json_dir": "/Users/user/NextCloud2/__Vaults_Databases_nxtcld/__People_nxtcld/telegram",
    "markdown_base_dir": "/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault",
    "archive_dir_name": ".tg-archives",
    "json2md_script": "/Users/user/__Repositories/LLMs-AssistantTelegram-ChatRag__SecondBrainInc/scripts/tgJson2Markdown/tgJson2Markdown.py",
    "today_yesterday_dir": "/Users/user/____Sandruk/___PKM"
}

# Time modifier mapping
TIME_MODIFIERS = {
    'd': 'days',
    'w': 'weeks',
    'm': 'months',
    'y': 'years',
    'h': 'hours'
}

class Contact:
    """Represents a Telegram contact."""
    
    def __init__(self, user_id: str, username: str = '', first_name: str = '', 
                 last_name: str = '', namespace: str = '', is_bot: bool = False, is_group: bool = False):
        self.user_id = user_id
        self.username = username
        self.first_name = first_name
        self.last_name = last_name
        self.namespace = namespace
        self.is_bot = is_bot
        self.is_group = is_group
    
    @property
    def display_name(self) -> str:
        """Return a human-readable name for the contact."""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        elif self.first_name:
            return self.first_name
        elif self.username:
            return f"@{self.username}"
        else:
            return str(self.user_id)
    
    def __str__(self) -> str:
        return f"{self.display_name} (ID: {self.user_id})"
    
    def __repr__(self) -> str:
        return f"Contact(user_id={self.user_id}, username='{self.username}', first_name='{self.first_name}', last_name='{self.last_name}', namespace='{self.namespace}', is_bot={self.is_bot}, is_group={self.is_group})"

def find_contacts_csv_files(contacts_dir: str) -> List[str]:
    """
    Find all contacts CSV files in the contacts directory.
    
    Args:
        contacts_dir: Directory to search for contact CSV files
        
    Returns:
        List of paths to contact CSV files
    """
    if not os.path.exists(contacts_dir):
        logger.error(f"Contacts directory not found: {contacts_dir}")
        return []
        
    if not os.path.isdir(contacts_dir):
        logger.error(f"Contacts path is not a directory: {contacts_dir}")
        return []
    
    # Main pattern for contact files
    pattern = os.path.join(contacts_dir, "telegram-*-contacts-chats-list.csv")
    files = glob.glob(pattern)
    
    # If no files found, also try looking for any CSV files as a fallback
    if not files:
        logger.warning(f"No contact files matching pattern {pattern}")
        csv_pattern = os.path.join(contacts_dir, "*.csv")
        csv_files = glob.glob(csv_pattern)
        if csv_files:
            logger.info(f"Found {len(csv_files)} CSV files in {contacts_dir} that might contain contacts")
            return csv_files
    
    logger.debug(f"Found {len(files)} contact files in {contacts_dir}")
    return files

def load_aliases(data_dir: str) -> Dict[str, str]:
    """
    Load aliases from a CSV file in the data directory. 
    The CSV should have two columns: alias,user_id
    
    Args:
        data_dir: Directory containing the aliases.csv file
        
    Returns:
        Dictionary mapping aliases to user IDs
    """
    aliases_path = os.path.join(data_dir, "aliases.csv")
    if not os.path.exists(aliases_path):
        logger.debug(f"Aliases file not found: {aliases_path}")
        return {}
        
    aliases = {}
    try:
        with open(aliases_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if 'alias' in row and 'user_id' in row:
                    aliases[row['alias'].lower().strip()] = row['user_id'].strip()
    except Exception as e:
        logger.error(f"Error loading aliases from {aliases_path}: {e}")
    
    logger.info(f"Loaded {len(aliases)} aliases from {aliases_path}")
    return aliases

def load_contacts(data_dir: str) -> Dict[str, Contact]:
    """
    Load contacts from the data directory.
    
    This function reads contacts from contacts.csv, aliases.csv and chat_aliases.csv
    
    Args:
        data_dir: Directory containing contacts and aliases files
        
    Returns:
        Dictionary mapping user_id/aliases to Contact objects
    """
    contacts = {}
    contacts_path = os.path.join(data_dir, "contacts.csv")
    
    if not os.path.exists(contacts_path):
        logger.warning(f"Contacts file not found: {contacts_path}")
        return contacts
        
    try:
        with open(contacts_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if not row.get('user_id'):
                    continue
                
                user_id = row['user_id'].strip()
                
                # Create contact object
                contact = Contact(
                    user_id=user_id,
                    username=row.get('username', '').strip() if row.get('username') else None,
                    first_name=row.get('first_name', '').strip(),
                    last_name=row.get('last_name', '').strip(),
                    is_bot=row.get('is_bot', '').lower() in ('true', 'yes', '1'),
                    is_group=row.get('is_group', '').lower() in ('true', 'yes', '1')
                )
                
                # Add to contacts dictionary with user_id as key
                contacts[user_id] = contact
                
                # If username exists, add it as an alias key too
                if contact.username:
                    username_key = contact.username.lower()
                    # Only add if not already a primary key
                    if username_key not in contacts:
                        contacts[username_key] = contact
                        logger.debug(f"Added username alias: {username_key} -> {user_id}")
    except Exception as e:
        logger.error(f"Error loading contacts: {str(e)}")
    
    # Now load and process aliases
    aliases = load_aliases(data_dir)
    alias_count = 0
    
    # Add aliases to the contacts dictionary
    for alias, target_id in aliases.items():
        if target_id in contacts:
            if alias not in contacts:  # Avoid overwriting existing keys
                contacts[alias] = contacts[target_id]
                alias_count += 1
                logger.debug(f"Added user alias: {alias} -> {target_id}")
        else:
            logger.warning(f"Alias '{alias}' references non-existent user_id: {target_id}")
    
    # Add chat aliases (for group chats)
    chat_aliases_path = os.path.join(data_dir, "chat_aliases.csv")
    if os.path.exists(chat_aliases_path):
        chat_alias_count = 0
        try:
            with open(chat_aliases_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if not row.get('chat_id') or not row.get('alias'):
                        continue
                        
                    chat_id = row['chat_id'].strip()
                    alias = row['alias'].strip().lower()
                    
                    logger.debug(f"Processing chat alias: {alias} -> {chat_id}")
                    
                    # Check if the chat_id exists in contacts
                    if chat_id in contacts:
                        if alias not in contacts:  # Avoid overwriting existing keys
                            contacts[alias] = contacts[chat_id]
                            chat_alias_count += 1
                            logger.debug(f"Added chat alias for existing chat: {alias} -> {chat_id}")
                    else:
                        # Create a new contact for this chat_id if it doesn't exist
                        chat_name = row.get('chat_name', '').strip()
                        contact = Contact(
                            user_id=chat_id,
                            username=None,
                            first_name=chat_name,
                            last_name='',
                            is_bot=False,
                            is_group=True
                        )
                        contacts[chat_id] = contact
                        contacts[alias] = contact
                        chat_alias_count += 1
                        logger.debug(f"Created new contact for chat and added alias: {alias} -> {chat_id}")
            
            logger.info(f"Loaded {chat_alias_count} chat aliases")
        except Exception as e:
            logger.error(f"Error loading chat aliases: {str(e)}")
    else:
        logger.debug(f"Chat aliases file not found: {chat_aliases_path}")
    
    # Log all available contact keys at debug level
    logger.debug(f"Available contact keys: {sorted(list(contacts.keys()))}")
    logger.info(f"Loaded {len(contacts) - alias_count} contacts with {alias_count} aliases")
    return contacts

def parse_time_modifier(time_spec: str) -> Tuple[str, int, Optional[str]]:
    """
    Parse a time specification like '7d', '2w', '1m', '100', 'all'.
    
    Returns:
        Tuple of (filter_type, value, filter_option)
        - filter_type: 'last', 'time', 'id'
        - value: numeric value
        - filter_option: string modifier (d, w, m, y, h) or None
    """
    if time_spec.lower() == 'all':
        # Special case for 'all' - use time filter with a wide range
        return 'time', 0, None
    
    # Check if it's a number followed by a modifier
    match = re.match(r'^(\d+)([dwmyh]?)$', time_spec)
    if not match:
        raise ValueError(f"Invalid time specification: {time_spec}")
    
    value = int(match.group(1))
    modifier = match.group(2)
    
    if not modifier:
        # If no modifier, it's a count of messages
        return 'last', value, None
    
    # For time-based modifiers, convert to 'time' filter
    return 'time', value, modifier

def calculate_time_range(value: int, modifier: str) -> Tuple[int, int]:
    """
    Calculate time range in Unix timestamps based on value and modifier.
    
    Returns:
        Tuple of (start_timestamp, end_timestamp)
    """
    end_time = datetime.now()
    
    if modifier == 'd':
        start_time = end_time - timedelta(days=value)
    elif modifier == 'w':
        start_time = end_time - timedelta(weeks=value)
    elif modifier == 'm':
        # Rough approximation of months as 30 days
        start_time = end_time - timedelta(days=30 * value)
    elif modifier == 'y':
        start_time = end_time - timedelta(days=365 * value)
    elif modifier == 'h':
        start_time = end_time - timedelta(hours=value)
    else:
        # Default to 1 day if unknown modifier
        start_time = end_time - timedelta(days=1)
    
    # Convert to Unix timestamps
    start_timestamp = int(start_time.timestamp())
    end_timestamp = int(end_time.timestamp())
    
    return start_timestamp, end_timestamp

def get_tdl_command(tdl_path: str, namespace: str, chat_id: int, filter_type: str, value: int, 
                   modifier: Optional[str], output_file: str) -> List[str]:
    """
    Generate the tdl command for retrieving messages.
    
    Args:
        tdl_path: Path to tdl executable
        namespace: Telegram session namespace
        chat_id: Chat ID to retrieve messages from
        filter_type: Type of filter ('last', 'time', 'id')
        value: Value for the filter
        modifier: Time modifier if applicable
        output_file: Output JSON file path
    
    Returns:
        List of command parts to execute
    """
    cmd = [
        tdl_path,
        "-n", namespace,
        "chat", "export",
        "-c", str(chat_id),
        "--with-content",
        "--all",
        "--raw",
        "--transcribe-voice",
        "-o", output_file
    ]
    
    if filter_type == 'last':
        cmd.extend(["-T", "last", "-i", str(value)])
    elif filter_type == 'time':
        if modifier:
            # Calculate time range based on modifier
            start_timestamp, end_timestamp = calculate_time_range(value, modifier)
            cmd.extend(["-T", "time", "-i", f"{start_timestamp},{end_timestamp}"])
        else:
            # For 'all', use a wide time range
            cmd.extend(["-T", "time", "-i", f"1115700000,{int(datetime.now().timestamp())}"])
    elif filter_type == 'id':
        cmd.extend(["-T", "id", "-i", f"1,{value}"])
    
    return cmd

def run_tdl_command(cmd: List[str]) -> bool:
    """
    Run the tdl command and wait for it to complete.
    
    Args:
        cmd: Command to run as a list of strings
        
    Returns:
        True if successful, False otherwise
    """
    cmd_str = ' '.join(cmd)
    logger.info(f"Running TDL command: {cmd_str}")
    
    try:
        # Timeout after 5 minutes (300 seconds) to prevent hanging
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        # Check return code
        if result.returncode != 0:
            logger.error(f"TDL command failed with return code {result.returncode}")
            logger.error(f"Error output: {result.stderr}")
            # Log a small part of stdout for context if it's available
            if result.stdout:
                logger.error(f"Command stdout excerpt: {result.stdout[:200]}...")
            return False
        
        # Log success at debug level
        logger.debug(f"TDL command stdout: {result.stdout}")
        
        # Check for specific error patterns in stdout (some errors are not reported in return code)
        error_patterns = [
            r"Error:",
            r"failed to get peer",
            r"rpc error code",
            r"not authorized",
            r"unauthorized",
            r"auth failed",
            r"cannot find"
        ]
        
        for pattern in error_patterns:
            if re.search(pattern, result.stdout, re.IGNORECASE):
                logger.error(f"Error pattern '{pattern}' detected in TDL command output")
                # Only log the relevant part of the output containing the error
                error_context = re.search(f".*{pattern}.*", result.stdout, re.IGNORECASE)
                if error_context:
                    logger.error(f"Error context: {error_context.group(0)}")
                else:
                    logger.error(f"Full command output: {result.stdout}")
                return False
        
        # Check for success patterns
        success_patterns = [
            r"Export completed",
            r"completed successfully",
            r"successfully exported"
        ]
        
        for pattern in success_patterns:
            if re.search(pattern, result.stdout, re.IGNORECASE):
                logger.info("TDL command completed successfully")
                return True
        
        # If we get here, we didn't find a clear success or error indicator
        # Check if output file exists and has content
        output_file_index = cmd.index("-o") + 1 if "-o" in cmd else None
        if output_file_index and output_file_index < len(cmd):
            output_file = cmd[output_file_index]
            if os.path.exists(output_file) and os.path.getsize(output_file) > 0:
                logger.info(f"TDL command produced output file ({os.path.getsize(output_file)} bytes)")
                return True
        
        logger.warning("TDL command did not report clear completion status, but no errors detected")
        return True  # Assume success if no clear error
        
    except subprocess.TimeoutExpired:
        logger.error("TDL command timed out after 5 minutes")
        return False
    except Exception as e:
        logger.error(f"Exception running TDL command: {str(e)}")
        return False

def generate_output_filenames(markdown_base_dir: str, raw_json_dir: str, contact: Contact, time_spec: str) -> Tuple[str, str]:
    """
    Generate output filenames for JSON and markdown files.
    
    Args:
        markdown_base_dir: Base directory for markdown files
        raw_json_dir: Directory for raw JSON files
        contact: Contact object
        time_spec: Time specification ('7d', 'all', etc.)
    
    Returns:
        Tuple of (json_path, markdown_path)
    """
    # Format basic identifier for the contact
    if contact.is_group:
        # For groups, use a special prefix
        if contact.username:
            identifier = f"@{contact.username}"
        else:
            identifier = f"group_{contact.user_id}"
    else:
        # For users
        if contact.username:
            identifier = f"@{contact.username}"
        else:
            identifier = f"user_{contact.user_id}"
    
    # Combined name for display
    combined_name = ""
    if contact.first_name:
        combined_name += contact.first_name
    if contact.last_name:
        if combined_name:
            combined_name += "-"
        combined_name += contact.last_name
    
    # Format file part
    if contact.is_group:
        file_part = f"{identifier}-group_id-{contact.user_id}"
    else:
        file_part = f"{identifier}-tg_id-{contact.user_id}"
        
    if combined_name:
        file_part += f"-{combined_name}"
    
    # Add time specification
    time_part = time_spec.upper()
    
    # JSON output path
    json_filename = f"{contact.namespace}_messages_raw-{contact.user_id}-{time_part}.json"
    json_path = os.path.join(raw_json_dir, json_filename)
    
    # Markdown output path
    namespace_dir = os.path.join(markdown_base_dir, contact.namespace)
    os.makedirs(namespace_dir, exist_ok=True)
    
    # Use kebab-case by replacing spaces with hyphens
    markdown_filename = f"@.__{file_part}-{time_part}.md".replace(" ", "-")
    markdown_path = os.path.join(namespace_dir, markdown_filename)
    
    return json_path, markdown_path

def archive_old_markdown_files(namespace_dir: str, file_part: str, archive_dir_name: str) -> None:
    """
    Archive old markdown files for the same contact if they exist.
    
    Args:
        namespace_dir: Directory containing markdown files
        file_part: Common part of the filename to match
        archive_dir_name: Name of the archive directory
    """
    archive_dir = os.path.join(namespace_dir, archive_dir_name)
    os.makedirs(archive_dir, exist_ok=True)
    
    # Get the base identifier by removing time spec and preserving ID parts
    # Handle both user IDs and group IDs
    match = re.search(r'(@\._\_.*(?:tg_id|group_id)-\d+)', file_part)
    if match:
        base_pattern = match.group(1)
        # Find existing files
        pattern = os.path.join(namespace_dir, f"{base_pattern}-*.md")
        existing_files = glob.glob(pattern)
        
        if existing_files:
            logger.info(f"Found {len(existing_files)} existing markdown files to archive")
            
            for file in existing_files:
                # Skip archive directory files
                if archive_dir_name in file:
                    continue
                    
                # Move to archive
                dest = os.path.join(archive_dir, os.path.basename(file))
                logger.info(f"Archiving {file} to {dest}")
                try:
                    shutil.move(file, dest)
                except Exception as e:
                    logger.warning(f"Failed to archive file {file}: {e}")
    else:
        logger.warning(f"Could not extract base pattern from file_part: {file_part}")
        # Fallback to the original pattern for backward compatibility
        pattern = os.path.join(namespace_dir, f"@.__{file_part}-*.md")
        existing_files = glob.glob(pattern)
        
        if existing_files:
            logger.info(f"Found {len(existing_files)} existing markdown files to archive")
            
            for file in existing_files:
                # Skip archive directory files
                if archive_dir_name in file:
                    continue
                    
                # Move to archive
                dest = os.path.join(archive_dir, os.path.basename(file))
                logger.info(f"Archiving {file} to {dest}")
                try:
                    shutil.move(file, dest)
                except Exception as e:
                    logger.warning(f"Failed to archive file {file}: {e}")

def determine_date_range_from_time_spec(time_spec: str) -> Tuple[str, str]:
    """
    Determine start and end dates from time specification for markdown conversion.
    
    Returns:
        Tuple of (start_date, end_date) in YYYYMMDD format
    """
    end_date = datetime.now()
    
    # Parse time spec
    if time_spec.lower() == 'all':
        # For 'all', use a wide date range
        start_date = datetime(2000, 1, 1)
    else:
        match = re.match(r'^(\d+)([dwmyh]?)$', time_spec)
        if not match:
            # Default to 1 day
            start_date = end_date - timedelta(days=1)
        else:
            value = int(match.group(1))
            modifier = match.group(2)
            
            if not modifier:
                # If no modifier (just number of messages), default to 7 days
                start_date = end_date - timedelta(days=7)
            elif modifier == 'd':
                start_date = end_date - timedelta(days=value)
            elif modifier == 'w':
                start_date = end_date - timedelta(weeks=value)
            elif modifier == 'm':
                # Approximate months as 30 days
                start_date = end_date - timedelta(days=30 * value)
            elif modifier == 'y':
                start_date = end_date - timedelta(days=365 * value)
            elif modifier == 'h':
                start_date = end_date - timedelta(hours=value)
            else:
                # Unknown modifier, default to 1 day
                start_date = end_date - timedelta(days=1)
    
    # Format dates
    start_date_str = start_date.strftime('%Y%m%d')
    end_date_str = end_date.strftime('%Y%m%d')
    
    return start_date_str, end_date_str

def convert_json_to_markdown(script_path: str, json_file: str, markdown_file: str, time_spec: str, contact: Contact) -> bool:
    """
    Convert JSON to markdown using the tgJson2Markdown.py script.
    
    Args:
        script_path: Path to the tgJson2Markdown.py script
        json_file: Path to the JSON file
        markdown_file: Path to the output markdown file
        time_spec: Time specification ('7d', 'all', '100', etc.)
        contact: Contact object with user info
    
    Returns:
        True if successful, False otherwise
    """
    if not os.path.exists(json_file):
        logger.error(f"Input JSON file not found: {json_file}")
        return False
        
    if not os.path.exists(script_path):
        logger.error(f"tgJson2Markdown.py script not found: {script_path}")
        return False
        
    # Make sure the output directory exists
    os.makedirs(os.path.dirname(markdown_file), exist_ok=True)
    
    try:
        # Get date range for filtering
        start_date, end_date = determine_date_range_from_time_spec(time_spec)
        
        base_command = [
            sys.executable, 
            script_path,
            json_file,  # input file as positional argument
            markdown_file,  # output file as positional argument
            "--startDate", start_date,  # Always provide start date
        ]
        
        # Add end date (for non-all queries)
        if time_spec.lower() != 'all':
            base_command.extend(["--endDate", end_date])
        
        # Add compact format option for better readability
        base_command.extend(["--compactFormat", "TRUE"])
        
        # Add namespace ID
        base_command.extend(["--namespaceId", str(contact.user_id)])
        
        # Add additional options based on time specification type
        filter_type, value, modifier = parse_time_modifier(time_spec)
        
        if filter_type == 'last' and not modifier:
            # If it's just a message count (like "100"), add max messages filter
            base_command.extend(['--maxMessages', str(value)])
        
        # Log the command
        logger.info(f"Running tgJson2Markdown.py command: {' '.join(base_command)}")
        
        # Run the command
        process = subprocess.run(base_command, capture_output=True, text=True, timeout=300)
        
        if process.returncode != 0:
            logger.error(f"Failed to convert JSON to markdown: {process.stderr}")
            logger.error(f"Command output: {process.stdout[:200]}...")
            return False
        
        # Check if output file was created
        if not os.path.exists(markdown_file):
            logger.error(f"Markdown file was not created: {markdown_file}")
            return False
            
        logger.info(f"Successfully converted JSON to markdown: {markdown_file}")
        logger.debug(f"Command output: {process.stdout}")
        return True
    except subprocess.TimeoutExpired:
        logger.error("JSON to markdown conversion timed out after 5 minutes")
        return False
    except Exception as e:
        logger.error(f"Error converting JSON to markdown: {e}")
        import traceback
        logger.debug(traceback.format_exc())
        return False

def post_process_markdown(markdown_file: str) -> None:
    """
    Post-process the markdown file to apply additional formatting improvements.
    
    Args:
        markdown_file: Path to the markdown file
    """
    try:
        with open(markdown_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Simplify timestamp format to remove date and just show time
        # Replace patterns like [2025-04-15_1513] with just 1513_ 
        pattern = r'\[(\d{4}-\d{2}-\d{2})_(\d{4})\]'
        
        # Track current day heading to avoid repetition
        current_day = None
        new_lines = []
        
        # Process line by line
        for line in content.split('\n'):
            # Check if this is a day header
            if line.startswith('## DAY '):
                current_day = line.replace('## DAY ', '')
                new_lines.append(line)
                continue
                
            # For message lines, update the timestamp format
            import re
            if '_[msg_id:' in line:
                matches = re.search(pattern, line)
                if matches:
                    date = matches.group(1)
                    time = matches.group(2)
                    
                    # Only update if the date matches the current day header
                    if current_day and date in current_day:
                        # Replace full timestamp with just time
                        line = re.sub(pattern, f'{time}_', line)
                
            new_lines.append(line)
        
        # Write the updated content back to the file
        with open(markdown_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
        
        # After formatting, add mermaid chart
        add_mermaid_chart_to_markdown(markdown_file)
        
        logger.info(f"Post-processed markdown file: {markdown_file}")
        
    except Exception as e:
        logger.warning(f"Failed to post-process markdown file: {e}")
        import traceback
        logger.debug(traceback.format_exc())

def add_mermaid_chart_to_markdown(markdown_file: str) -> None:
    """
    Add a mermaid.js chart for user statistics to the markdown file.
    
    Args:
        markdown_file: Path to the markdown file
    """
    try:
        with open(markdown_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find the user stats section
        user_stats_section = "# User stats\n## Top users by Total messages"
        if user_stats_section in content:
            # Parse the user stats to create a mermaid pie chart
            lines = content.split('\n')
            user_stats = []
            for i, line in enumerate(lines):
                if line.startswith('## Top users by Total messages'):
                    j = i + 1
                    while j < len(lines) and lines[j].strip() and not lines[j].startswith('#'):
                        if lines[j].strip():
                            # Extract username and count from lines like "1. user-name: 42"
                            parts = lines[j].split(':')
                            if len(parts) >= 2:
                                name = parts[0].split('. ', 1)[1] if '. ' in parts[0] else parts[0]
                                count = parts[1].strip()
                                user_stats.append((name, count))
                        j += 1
                    break
            
            # Create mermaid chart
            if user_stats:
                mermaid_chart = '\n```mermaid\npie title Message Distribution\n'
                for name, count in user_stats:
                    mermaid_chart += f'    "{name}" : {count}\n'
                mermaid_chart += '```\n'
                
                # Insert the chart after the user stats section
                new_content = content.replace(
                    user_stats_section,
                    user_stats_section + mermaid_chart
                )
                
                # Write the updated content back to the file
                with open(markdown_file, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                
                logger.info(f"Added mermaid chart to {markdown_file}")
    except Exception as e:
        logger.warning(f"Failed to add mermaid chart to {markdown_file}: {e}")

def extract_namespace_from_csv_path(csv_path: str) -> Optional[str]:
    """
    Extract namespace from a CSV file path.
    
    The function attempts to extract the namespace from the filename pattern:
    - 'telegram-{namespace}-contacts-chats-list.csv'
    - If that fails, it looks for any identifier in the filename
    
    Args:
        csv_path: Path to the CSV file
        
    Returns:
        Namespace string or None if not found
    """
    try:
        filename = os.path.basename(csv_path)
        
        # Try the standard pattern first
        match = re.search(r'telegram-([^-]+)-contacts-chats-list\.csv', filename)
        if match:
            namespace = match.group(1)
            logger.debug(f"Extracted namespace '{namespace}' from {filename}")
            return namespace
            
        # If that doesn't work, try a more generic approach for any CSV
        if filename.endswith('.csv'):
            # Try to extract any word that might be a namespace
            parts = filename.replace('.csv', '').split('-')
            if len(parts) > 1:
                # Use the second part (after the first hyphen) as a potential namespace
                namespace = parts[1]
                logger.warning(f"Using potential namespace '{namespace}' from {filename} (non-standard format)")
                return namespace
            elif len(parts) == 1:
                # If there's only one part, use that (minus extension)
                namespace = parts[0]
                logger.warning(f"Using filename '{namespace}' as namespace (non-standard format)")
                return namespace
        
        # If we're here, we couldn't find a namespace
        logger.warning(f"Could not extract namespace from {filename}, using 'default'")
        return "default"  # Use a default namespace rather than returning None
        
    except Exception as e:
        logger.error(f"Error extracting namespace from {csv_path}: {e}")
        logger.debug(f"Using 'error' as namespace due to exception: {str(e)}")
        return "error"  # Use an error namespace instead of None

def generate_today_yesterday_files() -> bool:
    """
    Generate Telegram-Today.md and Telegram-Yesterday.md files based on the DayLastContacted field.
    
    Returns:
        True if successful, False otherwise
    """
    try:
        contacts_dir = DEFAULT_PATHS["contacts_dir"]
        output_dir = DEFAULT_PATHS["today_yesterday_dir"]
        
        # Find all contact CSV files
        csv_files = find_contacts_csv_files(contacts_dir)
        if not csv_files:
            logger.warning(f"No contact CSV files found in {contacts_dir}")
            return False
        
        today = datetime.now().strftime('%Y-%m-%d')
        yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
        
        today_contacts = []
        yesterday_contacts = []
        
        # Process each CSV file to find contacts with today's and yesterday's date
        for csv_file in csv_files:
            try:
                # Extract namespace from the CSV filename
                namespace = extract_namespace_from_csv_path(csv_file)
                
                # Read the CSV file
                with open(csv_file, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    fieldnames = reader.fieldnames
                    
                    # Skip if no headers found
                    if not fieldnames:
                        logger.warning(f"CSV file {csv_file} has no headers")
                        continue
                    
                    # Check if the CSV has the DayLastContacted field
                    if 'DayLastContacted' not in fieldnames:
                        logger.warning(f"CSV file {csv_file} does not have DayLastContacted field")
                        continue
                    
                    # Determine which fields to use for identifying contacts
                    id_field = None
                    for field in ['ID', 'user_id', 'id', 'tg_id']:
                        if field in fieldnames:
                            id_field = field
                            break
                            
                    if not id_field:
                        logger.warning(f"CSV file {csv_file} does not have a recognizable ID field")
                        continue
                    
                    # Process each row
                    for row in reader:
                        # Skip rows without the necessary fields
                        if not row.get(id_field) or not row.get('DayLastContacted'):
                            continue
                        
                        # Get contact details
                        contact_id = row.get(id_field)
                        contact_date = row.get('DayLastContacted')
                        
                        # Determine if this is a user, group, or channel
                        contact_type = "Private Chat"  # Default
                        if 'Type' in fieldnames and row.get('Type'):
                            type_value = row.get('Type').lower()
                            if 'group' in type_value:
                                contact_type = "Group"
                                # Add member count if available
                                if 'MemberCount' in fieldnames and row.get('MemberCount'):
                                    contact_type += f" ({row.get('MemberCount')} members)"
                            elif 'channel' in type_value:
                                contact_type = "Channel"
                        
                        # Get display name
                        display_name = None
                        # Try to get username first
                        if 'Username' in fieldnames and row.get('Username'):
                            username = row.get('Username')
                            display_name = f"@{username}"
                        # If no username, try first name + last name
                        elif 'FirstName' in fieldnames and row.get('FirstName'):
                            display_name = row.get('FirstName')
                            if 'LastName' in fieldnames and row.get('LastName'):
                                display_name += f" {row.get('LastName')}"
                        # Fall back to title for groups
                        elif 'Title' in fieldnames and row.get('Title'):
                            display_name = row.get('Title')
                        # Last resort: use the ID
                        else:
                            display_name = f"Contact {contact_id}"
                        
                        # Find the markdown file for this contact
                        namespace_dir = os.path.join(DEFAULT_PATHS["markdown_base_dir"], namespace)
                        if not os.path.exists(namespace_dir):
                            logger.debug(f"Namespace directory does not exist: {namespace_dir}")
                            markdown_path = None
                        else:
                            markdown_path = None
                            
                            # Try different patterns to find the markdown file
                            patterns_to_try = []
                            
                            # 1. Try with username if available
                            if display_name.startswith('@'):
                                username = display_name[1:]
                                patterns_to_try.append(f"@._*@{username}*tg_id*{contact_id}*.md")
                                patterns_to_try.append(f"@.__@{username}*tg_id*{contact_id}*.md")
                            
                            # 2. Try with user ID
                            patterns_to_try.append(f"@._*tg_id*{contact_id}*.md")
                            patterns_to_try.append(f"@.__*tg_id*{contact_id}*.md")
                            
                            # 3. Try based on contact type
                            if contact_type.startswith("Group"):
                                patterns_to_try.append(f"@._*group*{contact_id}*.md")
                                patterns_to_try.append(f"@.__*group*{contact_id}*.md")
                            elif contact_type == "Channel":
                                patterns_to_try.append(f"@._*channel*{contact_id}*.md")
                                patterns_to_try.append(f"@.__*channel*{contact_id}*.md")
                            
                            # Try each pattern
                            for pattern in patterns_to_try:
                                logger.debug(f"Trying to find markdown file with pattern: {os.path.join(namespace_dir, pattern)}")
                                matching_files = glob.glob(os.path.join(namespace_dir, pattern))
                                if matching_files:
                                    # Sort by modification time, newest first
                                    matching_files.sort(key=os.path.getmtime, reverse=True)
                                    markdown_path = matching_files[0]
                                    logger.debug(f"Found markdown file: {markdown_path}")
                                    break
                            
                            # If no match with globbing, try listing all files and finding closest match
                            if not markdown_path:
                                try:
                                    all_files = os.listdir(namespace_dir)
                                    logger.debug(f"Looking for ID {contact_id} in {len(all_files)} files in {namespace_dir}")
                                    
                                    for file in all_files:
                                        if f"tg_id-{contact_id}" in file or f"group_id-{contact_id}" in file:
                                            markdown_path = os.path.join(namespace_dir, file)
                                            logger.debug(f"Found markdown file by direct ID match: {markdown_path}")
                                            break
                                except Exception as e:
                                    logger.debug(f"Error listing files in {namespace_dir}: {e}")
                        
                        # Create the contact entry
                        contact_entry = {
                            'id': contact_id,
                            'display_name': display_name,
                            'type': contact_type,
                            'markdown_path': markdown_path,
                            'namespace': namespace
                        }
                        
                        # Add to the appropriate list
                        if contact_date == today:
                            today_contacts.append(contact_entry)
                        elif contact_date == yesterday:
                            yesterday_contacts.append(contact_entry)
                
            except Exception as e:
                logger.error(f"Error processing CSV file {csv_file}: {e}")
                import traceback
                logger.debug(traceback.format_exc())
        
        # Generate the Today markdown file
        today_markdown_path = os.path.join(output_dir, "Telegram-Today.md")
        with open(today_markdown_path, 'w', encoding='utf-8') as f:
            f.write(f"# Telegram Today ({today})\n\n")
            f.write("## Recently Active Chats\n\n")
            
            if not today_contacts:
                f.write("*No active chats today.*\n")
            else:
                # Sort contacts by display name
                today_contacts.sort(key=lambda x: x['display_name'])
                
                # Determine vault name from base path
                vault_name = os.path.basename(DEFAULT_PATHS["markdown_base_dir"])
                if not vault_name:
                    vault_name = "__People__vault"  # Default vault name
                
                # Write each contact
                for i, contact in enumerate(today_contacts, 1):
                    if contact['markdown_path']:
                        # Create an Obsidian link to the markdown file
                        try:
                            md_rel_path = os.path.relpath(
                                contact['markdown_path'], 
                                DEFAULT_PATHS["markdown_base_dir"]
                            )
                            obsidian_link = f"obsidian://open?vault={vault_name}&file={md_rel_path}"
                            f.write(f"{i}. [{contact['display_name']}]({obsidian_link}) - {contact['type']}\n")
                        except Exception as e:
                            logger.debug(f"Error creating link for {contact['display_name']}: {e}")
                            f.write(f"{i}. {contact['display_name']} - {contact['type']} (File: {os.path.basename(contact['markdown_path'])})\n")
                    else:
                        # Just list the contact without a link
                        f.write(f"{i}. {contact['display_name']} - {contact['type']}\n")
        
        # Generate the Yesterday markdown file
        yesterday_markdown_path = os.path.join(output_dir, "Telegram-Yesterday.md")
        with open(yesterday_markdown_path, 'w', encoding='utf-8') as f:
            f.write(f"# Telegram Yesterday ({yesterday})\n\n")
            f.write("## Recently Active Chats\n\n")
            
            if not yesterday_contacts:
                f.write("*No active chats yesterday.*\n")
            else:
                # Sort contacts by display name
                yesterday_contacts.sort(key=lambda x: x['display_name'])
                
                # Determine vault name from base path
                vault_name = os.path.basename(DEFAULT_PATHS["markdown_base_dir"])
                if not vault_name:
                    vault_name = "__People__vault"  # Default vault name
                
                # Write each contact
                for i, contact in enumerate(yesterday_contacts, 1):
                    if contact['markdown_path']:
                        # Create an Obsidian link to the markdown file
                        try:
                            md_rel_path = os.path.relpath(
                                contact['markdown_path'], 
                                DEFAULT_PATHS["markdown_base_dir"]
                            )
                            obsidian_link = f"obsidian://open?vault={vault_name}&file={md_rel_path}"
                            f.write(f"{i}. [{contact['display_name']}]({obsidian_link}) - {contact['type']}\n")
                        except Exception as e:
                            logger.debug(f"Error creating link for {contact['display_name']}: {e}")
                            f.write(f"{i}. {contact['display_name']} - {contact['type']} (File: {os.path.basename(contact['markdown_path'])})\n")
                    else:
                        # Just list the contact without a link
                        f.write(f"{i}. {contact['display_name']} - {contact['type']}\n")
        
        # Count how many contacts have links
        today_with_links = sum(1 for c in today_contacts if c['markdown_path'])
        yesterday_with_links = sum(1 for c in yesterday_contacts if c['markdown_path'])
        
        logger.info(f"Generated Today/Yesterday markdown files: {today_markdown_path}, {yesterday_markdown_path}")
        logger.info(f"Today: {len(today_contacts)} contacts ({today_with_links} with links), Yesterday: {len(yesterday_contacts)} contacts ({yesterday_with_links} with links)")
        return True
        
    except Exception as e:
        logger.error(f"Error generating Today/Yesterday markdown files: {e}")
        import traceback
        logger.debug(traceback.format_exc())
        return False

def process_messages_for_contact(contact: Contact, time_spec: str) -> bool:
    """
    Process messages for a specific contact.
    
    Args:
        contact: Contact object
        time_spec: Time specification ('7d', 'all', '100', etc.)
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Use the default paths
        paths = DEFAULT_PATHS
        
        # Parse time modifier
        filter_type, value, modifier = parse_time_modifier(time_spec)
        logger.info(f"Time specification: {time_spec} → type={filter_type}, value={value}, modifier={modifier}")
        
        # Generate output filenames
        json_file, markdown_file = generate_output_filenames(
            paths["markdown_base_dir"], 
            paths["raw_json_dir"], 
            contact, 
            time_spec
        )
        logger.info(f"Output files: JSON={json_file}, Markdown={markdown_file}")
        
        # Create directories if they don't exist
        os.makedirs(os.path.dirname(json_file), exist_ok=True)
        os.makedirs(os.path.dirname(markdown_file), exist_ok=True)
        
        # Generate TDL command
        cmd = get_tdl_command(
            paths["tdl_path"],
            contact.namespace, 
            contact.user_id, 
            filter_type, 
            value, 
            modifier, 
            json_file
        )
        
        # Run TDL command
        if not run_tdl_command(cmd):
            logger.error("Failed to run TDL command")
            return False
        
        # Check if the JSON file was created
        if not os.path.exists(json_file):
            logger.error(f"JSON file was not created: {json_file}")
            return False
        
        # Archive old markdown files
        namespace_dir = os.path.join(paths["markdown_base_dir"], contact.namespace)
        
        # Create proper file_part based on contact type
        if contact.is_group:
            if contact.username:
                file_part = f"@{contact.username}-group_id-{contact.user_id}"
            else:
                file_part = f"group_{contact.user_id}-group_id-{contact.user_id}"
        else:
            if contact.username:
                file_part = f"@{contact.username}-tg_id-{contact.user_id}"
            else:
                file_part = f"user_{contact.user_id}-tg_id-{contact.user_id}"
        
        archive_old_markdown_files(namespace_dir, file_part, paths["archive_dir_name"])
        
        # Convert JSON to markdown (pass contact for proper user identification)
        if not convert_json_to_markdown(paths["json2md_script"], json_file, markdown_file, time_spec, contact):
            logger.error("Failed to convert JSON to markdown")
            return False
        
        # Update DayLastContacted field in CSV files
        contacts_dir = paths.get("contacts_dir", "/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts")
        if not update_day_last_contacted(contacts_dir, contact):
            logger.warning(f"Failed to update DayLastContacted for contact: {contact}")
            # Continue execution even if update fails - this is not critical
        
        # After updating DayLastContacted, regenerate Today/Yesterday files
        generate_today_yesterday_files()
        
        logger.info(f"Successfully processed messages for contact: {contact}")
        return True
        
    except Exception as e:
        logger.error(f"Error processing messages for contact: {e}")
        import traceback
        logger.debug(traceback.format_exc())
        return False

def find_contact_by_identifier(identifier: str, contacts: Dict[str, Contact]) -> Optional[Contact]:
    """
    Find a contact by identifier (user_id, username, or alias).
    
    The search prioritizes in this order:
    1. Direct match on identifier as user_id/tg_id
    2. Direct match on identifier as alias
    3. Match on username (normalized to lowercase without @)
    4. Partial match on first_name or last_name
    
    Args:
        identifier: The identifier to search for
        contacts: Dictionary of contacts
        
    Returns:
        Contact object if found, None otherwise
    """
    if not identifier or not contacts:
        logger.warning(f"Empty identifier or contacts dictionary: identifier='{identifier}', contacts_count={len(contacts) if contacts else 0}")
        return None
    
    # Try to parse as integer user_id first if it looks like a number
    try:
        if identifier.isdigit():
            numeric_id = identifier
            # Check if numeric id is in contacts
            if numeric_id in contacts:
                logger.debug(f"Found contact by numeric user_id: {numeric_id}")
                return contacts[numeric_id]
    except (ValueError, AttributeError):
        # Not a numeric ID, continue with string-based search
        pass
    
    # Normalize identifier
    normalized_identifier = identifier.lower()
    if normalized_identifier.startswith('@'):
        normalized_identifier = normalized_identifier[1:]
    
    logger.debug(f"Looking for identifier: '{normalized_identifier}' in {len(contacts)} contacts")
    
    # 1. Check if the identifier directly matches a user_id
    for contact in contacts.values():
        if contact.user_id and contact.user_id.lower() == normalized_identifier:
            logger.debug(f"Found contact by direct user_id match: {normalized_identifier} -> {contact}")
            return contact
    
    # 2. Direct match on keys in contacts dictionary (which can be aliases)
    if normalized_identifier in contacts:
        logger.debug(f"Found contact by alias match: {normalized_identifier} -> {contacts[normalized_identifier]}")
        return contacts[normalized_identifier]
    
    # For other match types, we need to search through all contacts
    potential_matches = []
    
    for contact in contacts.values():
        # Skip duplicate contact objects (due to aliases)
        if contact in potential_matches:
            continue
            
        # 3. Match on username
        if contact.username and contact.username.lower() == normalized_identifier:
            logger.debug(f"Found contact by username: {normalized_identifier} -> {contact}")
            return contact
            
        # 4. Collect partial matches on first_name or last_name for later
        if contact.first_name and normalized_identifier in contact.first_name.lower():
            potential_matches.append(contact)
        elif contact.last_name and normalized_identifier in contact.last_name.lower():
            potential_matches.append(contact)
    
    # If we have exactly one potential match, return it
    if len(potential_matches) == 1:
        logger.debug(f"Found contact by partial name match: {normalized_identifier} -> {potential_matches[0]}")
        return potential_matches[0]
    # If we have multiple potential matches, log a warning and return the first one
    elif len(potential_matches) > 1:
        logger.warning(f"Multiple contacts matched '{identifier}', using first match: {potential_matches[0]}")
        return potential_matches[0]
    
    logger.warning(f"Contact not found: '{identifier}'")
    return None

def process_command(command: str) -> None:
    """
    Process a tg2p command.
    
    Args:
        command: Command string to process
    """
    parts = command.strip().split()
    
    if len(parts) < 2:
        logger.error("Invalid command format. Usage: tg2p <identifier> <timespec>")
        print("Invalid command format. Usage: tg2p <identifier> <timespec>")
        print("  - identifier: username, alias, or chat ID")
        print("  - timespec: 'all', '7d' (7 days), '30d' (30 days), or a number (last N messages)")
        return
    
    identifier = parts[1].lower()
    time_spec = parts[2] if len(parts) > 2 else "7d"
    
    # Set log level to debug temporarily for this command
    original_log_level = logger.level
    logger.setLevel(logging.DEBUG)
    
    # Load all contacts from all CSV files
    contacts = {}
    csv_files = find_contacts_csv_files(DEFAULT_PATHS["contacts_dir"])
    
    if not csv_files:
        logger.error(f"No contact CSV files found in {DEFAULT_PATHS['contacts_dir']}")
        print(f"No contact CSV files found in {DEFAULT_PATHS['contacts_dir']}")
        print(f"Expected file pattern: telegram-*-contacts-chats-list.csv")
        return
        
    logger.debug(f"Found {len(csv_files)} contact CSV files: {csv_files}")
    
    for csv_file in csv_files:
        namespace = extract_namespace_from_csv_path(csv_file)
        logger.debug(f"Processing contacts from namespace '{namespace}' in file {os.path.basename(csv_file)}")
        
        # Read the CSV file directly
        try:
            with open(csv_file, 'r', encoding='utf-8') as f:
                # First, peek at the file to determine the format
                header = f.readline().strip()
                f.seek(0)  # Go back to the beginning
                
                # Check if it's the newer format with many columns or the older format
                is_new_format = False
                
                # Look for column names that would indicate the format
                if '"tg_session"' in header or 'tg_session' in header or 'ID' in header:
                    is_new_format = True
                    logger.debug(f"Detected new CSV format in {os.path.basename(csv_file)}")
                
                # Process according to the detected format
                reader = csv.reader(f)
                headers = next(reader)  # Skip header row
                
                # Find the index of relevant columns
                if is_new_format:
                    # New format with many columns (usually from telethon export)
                    id_idx = 1  # Usually the ID column is the second one (index 1)
                    username_idx = 2  # Usually Username is the third column
                    alias_idx = 3  # The Alias column is 4th
                    first_name_idx = 7  # First Name is typically the 8th column
                    last_name_idx = 8  # Last Name is typically the 9th column
                    is_bot_idx = 16  # Bot column is usually around here
                    is_group_idx = None  # Need to determine based on "Type" column
                    type_idx = 5  # Type column indicates if it's a User, Bot, Group, etc.
                    
                    # Try to find these columns by name if they exist in headers
                    for i, col in enumerate(headers):
                        col = col.strip('"').lower()
                        if col == 'id':
                            id_idx = i
                        elif col == 'username':
                            username_idx = i
                        elif col == 'alias':
                            alias_idx = i
                        elif col in ('first name', 'firstname'):
                            first_name_idx = i
                        elif col in ('last name', 'lastname'):
                            last_name_idx = i
                        elif col == 'bot':
                            is_bot_idx = i
                        elif col == 'type':
                            type_idx = i
                else:
                    # Old format - assume simple user_id,username,first_name,last_name order
                    id_idx = 0
                    username_idx = 1
                    alias_idx = None
                    first_name_idx = 2
                    last_name_idx = 3
                    is_bot_idx = None
                    is_group_idx = None
                    type_idx = None
                
                # Now process the rows
                for row in reader:
                    # Skip empty rows
                    if not row or len(row) <= id_idx:
                        continue
                    
                    # Extract values, handling potential missing columns
                    user_id = row[id_idx].strip() if id_idx < len(row) else ""
                    username = row[username_idx].strip() if username_idx < len(row) and len(row) > username_idx else ""
                    alias = row[alias_idx].strip() if alias_idx is not None and alias_idx < len(row) and len(row) > alias_idx else ""
                    first_name = row[first_name_idx].strip() if first_name_idx < len(row) and len(row) > first_name_idx else ""
                    last_name = row[last_name_idx].strip() if last_name_idx < len(row) and len(row) > last_name_idx else ""
                    
                    # Skip entries without valid user ID
                    if not user_id or not user_id.strip():
                        continue
                    
                    # Determine if it's a bot
                    is_bot = False
                    if is_bot_idx is not None and is_bot_idx < len(row):
                        is_bot = row[is_bot_idx].lower() in ('true', 'yes', '1', 't')
                    
                    # Determine if it's a group
                    is_group = False
                    if type_idx is not None and type_idx < len(row):
                        is_group = row[type_idx].lower() in ('group', 'supergroup', 'channel')
                    
                    # Create contact object with namespace
                    contact = Contact(
                        user_id=user_id,
                        username=username if username and username != "None" else None,
                        first_name=first_name if first_name and first_name != "None" else "",
                        last_name=last_name if last_name and last_name != "None" else "",
                        namespace=namespace,
                        is_bot=is_bot,
                        is_group=is_group
                    )
                    
                    # Add to contacts dictionary with user_id as key
                    contacts[user_id] = contact
                    
                    # If username exists, add it as an alias key too
                    if contact.username:
                        username_key = contact.username.lower()
                        # Only add if not already a primary key
                        if username_key not in contacts:
                            contacts[username_key] = contact
                            logger.debug(f"Added username alias: {username_key} -> {user_id}")
                    
                    # If alias exists in the new format, add it as an alias key
                    if alias and alias != "None":
                        alias_key = alias.lower()
                        if alias_key not in contacts:
                            contacts[alias_key] = contact
                            logger.debug(f"Added custom alias: {alias_key} -> {user_id}")
                
                logger.info(f"Loaded {len(contacts)} contacts from {os.path.basename(csv_file)}")
        except Exception as e:
            logger.error(f"Failed to load contacts from {csv_file}: {e}")
            import traceback
            logger.debug(traceback.format_exc())
    
    # Restore original log level
    logger.setLevel(original_log_level)
    
    # Check if we found any contacts at all
    if not contacts:
        logger.error("No contacts were loaded from any files. Check that your contact CSV files exist and are formatted correctly.")
        print("No contacts were loaded. Check that your contact CSV files exist and are formatted correctly.")
        print(f"Expected file pattern: {DEFAULT_PATHS['contacts_dir']}/telegram-*-contacts-chats-list.csv")
        return
        
    logger.debug(f"Looking for contact with identifier: {identifier}")
    contact = find_contact_by_identifier(identifier, contacts)
    
    if not contact:
        logger.error(f"Contact not found: {identifier}")
        print(f"Contact not found: {identifier}")
        print("Available contacts (showing up to 10):")
        # Print a few available contacts to help the user
        contacts_list = list(set(contacts.values()))  # Remove duplicates
        if contacts_list:
            for i, c in enumerate(sorted(contacts_list, key=lambda x: x.display_name)[:10]):
                print(f"- {c.display_name} (username: {c.username}, id: {c.user_id})")
            if len(contacts_list) > 10:
                print(f"... and {len(contacts_list) - 10} more")
        else:
            print("No contacts available. Check your contact files.")
        return
    
    logger.info(f"Processing messages for contact: {contact}")
    process_messages_for_contact(contact, time_spec)

def update_day_last_contacted(contacts_dir: str, contact: Contact) -> bool:
    """
    Update the DayLastContacted field for a contact in all relevant CSV files.
    
    Args:
        contacts_dir: Directory containing contacts CSV files
        contact: Contact object to update
        
    Returns:
        True if update was successful, False otherwise
    """
    today = datetime.now().strftime('%Y-%m-%d')
    logger.info(f"Updating DayLastContacted to {today} for contact: {contact}")
    
    # Find all contact CSV files
    csv_files = find_contacts_csv_files(contacts_dir)
    if not csv_files:
        logger.warning(f"No contact CSV files found in {contacts_dir}")
        return False
    
    updated = False
    
    for csv_file in csv_files:
        try:
            # Read the entire CSV file
            rows = []
            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                fieldnames = reader.fieldnames
                
                # Skip if no headers found
                if not fieldnames:
                    logger.warning(f"CSV file {csv_file} has no headers")
                    continue
                
                # Check if the CSV has the DayLastContacted field
                if 'DayLastContacted' not in fieldnames:
                    logger.warning(f"CSV file {csv_file} does not have DayLastContacted field")
                    continue
                
                # Determine which field to use for user ID matching
                id_field = None
                for field in ['ID', 'user_id', 'id', 'tg_id']:
                    if field in fieldnames:
                        id_field = field
                        break
                        
                if not id_field:
                    logger.warning(f"CSV file {csv_file} does not have a recognizable ID field")
                    continue
                
                # Process each row
                for row in reader:
                    # Check if this is the row for our contact
                    if row.get(id_field) == contact.user_id:
                        row['DayLastContacted'] = today
                        updated = True
                        logger.debug(f"Updated DayLastContacted for contact {contact.user_id} in {csv_file}")
                    rows.append(row)
            
            # Write the updated content back to the file
            if updated:
                with open(csv_file, 'w', encoding='utf-8', newline='') as f:
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(rows)
                logger.info(f"Updated CSV file: {csv_file}")
        
        except Exception as e:
            logger.error(f"Error updating DayLastContacted in {csv_file}: {e}")
            import traceback
            logger.debug(traceback.format_exc())
    
    return updated

def main():
    """
    Main function.
    """
    parser = argparse.ArgumentParser(description='Process Telegram messages for a contact')
    
    # Add --today-yesterday-only flag first so we can check it
    parser.add_argument('--today-yesterday-only', action='store_true', help='Only generate Today/Yesterday files without processing messages')
    
    # Only require identifier if not using --today-yesterday-only
    if '--today-yesterday-only' in sys.argv:
        parser.add_argument('identifier', nargs='?', help='Username, alias, or chat ID')
    else:
        parser.add_argument('identifier', help='Username, alias, or chat ID')
    
    parser.add_argument('time_spec', nargs='?', default='7d', help='Time specification (default: 7d)')
    parser.add_argument('--contacts-dir', help='Directory containing contact CSV files')
    parser.add_argument('--markdown-dir', help='Base directory for markdown output')
    parser.add_argument('--raw-json-dir', help='Directory for raw JSON output')
    parser.add_argument('--tdl-path', help='Path to tdl executable')
    parser.add_argument('--json2md-script', help='Path to JSON to markdown conversion script')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose output')
    parser.add_argument('--debug', '-d', action='store_true', help='Enable debug output')
    parser.add_argument('--today-yesterday-dir', help='Directory to store Today/Yesterday files')
    
    args = parser.parse_args()
    
    # Set up logging
    if args.debug:
        logger.setLevel(logging.DEBUG)
    elif args.verbose:
        logger.setLevel(logging.INFO)
    
    # Set up custom paths if specified
    custom_paths = DEFAULT_PATHS.copy()
    if args.contacts_dir:
        custom_paths["contacts_dir"] = args.contacts_dir
    if args.markdown_dir:
        custom_paths["markdown_base_dir"] = args.markdown_dir
    if args.raw_json_dir:
        custom_paths["raw_json_dir"] = args.raw_json_dir
    if args.tdl_path:
        custom_paths["tdl_path"] = args.tdl_path
    if args.json2md_script:
        custom_paths["json2md_script"] = args.json2md_script
    if args.today_yesterday_dir:
        custom_paths["today_yesterday_dir"] = args.today_yesterday_dir
    
    # Override DEFAULT_PATHS
    for key, value in custom_paths.items():
        DEFAULT_PATHS[key] = value
    
    # If only generating Today/Yesterday files, do that and exit
    if args.today_yesterday_only:
        logger.info("Generating Today/Yesterday files only")
        generate_today_yesterday_files()
        return 0
    
    # Process command with custom paths
    command = f"tg2p {args.identifier} {args.time_spec}"
    process_command(command)
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
