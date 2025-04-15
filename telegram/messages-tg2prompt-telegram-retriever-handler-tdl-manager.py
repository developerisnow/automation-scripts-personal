#!/usr/bin/env python3
"""
Telegram to Prompt Message Retriever (tg2p)

This script provides a simple command-line interface for retrieving Telegram chat messages
and converting them to markdown format for easy consumption.

Usage examples:
  tg2p shimanskij 7d     # Retrieve 7 days of messages from shimanskij
  tg2p shimanskij all    # Retrieve all messages from shimanskij
  tg2p shimanskij 100    # Retrieve last 100 messages from shimanskij
  tg2p ilya 1m           # Retrieve 1 month of messages from ilya (uses alias from contacts.csv)

Time modifiers:
  d - days (e.g., 7d = 7 days)
  w - weeks (e.g., 2w = 2 weeks)
  m - months (e.g., 1m = 1 month)
  y - years (e.g., 1y = 1 year)
  h - hours (e.g., 12h = 12 hours)
  (no suffix) - number of messages (e.g., 100 = last 100 messages)
  all - all messages
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
    "json2md_script": "/Users/user/__Repositories/LLMs-AssistantTelegram-ChatRag__SecondBrainInc/scripts/tgJson2Markdown/tgJson2Markdown.py"
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
    """Represents a Telegram contact with all necessary information."""
    def __init__(self, namespace: str, user_id: int, username: str, first_name: str = "", 
                 last_name: str = "", alias: str = ""):
        self.namespace = namespace
        self.user_id = user_id
        self.username = username
        self.first_name = first_name
        self.last_name = last_name
        self.alias = alias
    
    def __str__(self) -> str:
        return f"Contact(namespace={self.namespace}, user_id={self.user_id}, username={self.username})"

def find_contacts_csv_files(contacts_dir: str) -> List[str]:
    """Find all contacts CSV files in the contacts directory."""
    pattern = os.path.join(contacts_dir, "telegram-*-contacts-chats-list.csv")
    return glob.glob(pattern)

def load_contacts(csv_files: List[str]) -> Dict[str, Contact]:
    """
    Load contacts from CSV files.
    
    Returns:
        Dictionary mapping usernames and aliases to Contact objects
    """
    contacts = {}
    
    for csv_file in csv_files:
        try:
            # Extract namespace from filename
            match = re.search(r'telegram-([^-]+)-contacts', os.path.basename(csv_file))
            if not match:
                logger.warning(f"Could not extract namespace from filename: {csv_file}")
                continue
                
            namespace = match.group(1)
            logger.debug(f"Processing contacts for namespace: {namespace}")
            
            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    try:
                        # Skip rows that don't have required fields
                        if not row.get('ID') or row.get('Bot') == 'True':
                            continue
                        
                        user_id = int(row['ID'])
                        username = row.get('Username', '').lower()
                        
                        # Create contact object
                        contact = Contact(
                            namespace=namespace,
                            user_id=user_id,
                            username=username,
                            first_name=row.get('First Name', ''),
                            last_name=row.get('Last Name', '')
                        )
                        
                        # Add by username if available
                        if username:
                            contacts[username.lower()] = contact
                        
                        # Custom logic to add aliases based on name patterns
                        # This is a placeholder for future alias extraction logic
                        # For now, we'll just use the existing data
                        
                        # Map user_id as string key too
                        contacts[str(user_id)] = contact
                    except Exception as e:
                        logger.debug(f"Error processing contact row: {e}")
            
        except Exception as e:
            logger.warning(f"Failed to process contacts file {csv_file}: {e}")
    
    logger.info(f"Loaded {len(contacts)} contacts from {len(csv_files)} CSV files")
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
    
    Returns:
        True if successful, False otherwise
    """
    logger.info(f"Running command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            logger.error(f"Command failed with return code {result.returncode}")
            logger.error(f"Error output: {result.stderr}")
            return False
        
        logger.debug(f"Command output: {result.stdout}")
        
        # Check for specific error patterns in stdout (some errors are not reported in return code)
        error_patterns = [
            r"Error:",
            r"failed to get peer",
            r"rpc error code"
        ]
        
        for pattern in error_patterns:
            if re.search(pattern, result.stdout):
                logger.error(f"Error detected in command output: {pattern}")
                logger.error(f"Command output: {result.stdout}")
                return False
        
        # Check if the command seems to have run successfully
        if "Export completed" in result.stdout:
            return True
        
        logger.warning(f"Command did not report completion correctly. Output: {result.stdout}")
        return True  # Assume success if no clear error
        
    except Exception as e:
        logger.error(f"Failed to run command: {e}")
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
    
    # Find existing files
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

def convert_json_to_markdown(json2md_script: str, json_file: str, markdown_file: str, time_spec: str, contact: Contact) -> bool:
    """
    Convert JSON to markdown using the tgJson2Markdown.py script.
    
    Args:
        json2md_script: Path to the JSON to markdown conversion script
        json_file: Path to JSON file
        markdown_file: Path to output markdown file
        time_spec: Time specification for determining date range
        contact: Contact object for user identification
    
    Returns:
        True if successful, False otherwise
    """
    # Determine date range
    start_date, end_date = determine_date_range_from_time_spec(time_spec)
    
    # Find the contacts CSV file for this namespace
    contacts_file = ""
    for csv_file in glob.glob(os.path.join(DEFAULT_PATHS["contacts_dir"], f"telegram-{contact.namespace}-*.csv")):
        contacts_file = csv_file
        break
    
    if not contacts_file:
        logger.warning(f"No contacts CSV file found for namespace {contact.namespace}")
    else:
        logger.info(f"Using contacts file: {contacts_file}")
        
    # Create a temporary user info file with both the contact's and namespace owner's information
    # This ensures proper identification of both participants in the conversation
    temp_user_info_file = os.path.join(os.path.dirname(markdown_file), ".temp_user_info.json")
    with open(temp_user_info_file, 'w', encoding='utf-8') as f:
        # Find the namespace owner's details from the CSV files 
        namespace_owner_data = {
            "id": None,
            "first_name": contact.namespace,
            "last_name": "(You)",
            "username": contact.namespace,
            "is_self": True
        }
        
        # Try to get the actual namespace owner ID and info from contacts
        try:
            for csv_path in glob.glob(os.path.join(DEFAULT_PATHS["contacts_dir"], "*.csv")):
                with open(csv_path, 'r', encoding='utf-8') as csv_file:
                    # Check if this is the file for this namespace
                    if f"telegram-{contact.namespace}-" in os.path.basename(csv_path):
                        # Try to find the ID from the file
                        import csv
                        csv_reader = csv.DictReader(csv_file)
                        for row in csv_reader:
                            if row.get('is_self', '').lower() == 'true' or row.get('is_self', '') == '1':
                                for id_field in ['id', 'user_id', 'tg_id']:
                                    if id_field in row and row[id_field]:
                                        try:
                                            namespace_owner_data["id"] = int(row[id_field])
                                            namespace_owner_data["first_name"] = row.get('first_name', row.get('firstname', contact.namespace))
                                            namespace_owner_data["last_name"] = row.get('last_name', row.get('lastname', '(You)'))
                                            namespace_owner_data["username"] = row.get('username', contact.namespace)
                                            break
                                        except (ValueError, TypeError):
                                            pass
                                if namespace_owner_data["id"]:
                                    break
                        if namespace_owner_data["id"]:
                            break
        except Exception as e:
            logger.warning(f"Failed to get namespace owner info: {e}")
        
        # If we couldn't find the namespace owner's ID, use a default
        if not namespace_owner_data["id"]:
            # Use a high number to avoid conflicts with regular user IDs
            namespace_owner_data["id"] = 999999999
        
        # Write both user info entries
        json.dump({
            "users": [
                {
                    "id": contact.user_id,
                    "first_name": contact.first_name if contact.first_name else "User",
                    "last_name": contact.last_name if contact.last_name else "",
                    "username": contact.username if contact.username else f"user_{contact.user_id}",
                    "is_self": False
                },
                namespace_owner_data
            ]
        }, f, ensure_ascii=False)
    
    # Build command with both the contacts CSV and the temporary user info file
    # The script will merge them, prioritizing CSV data if available
    cmd = [
        "python3", json2md_script,
        "--startDate", start_date,
        "--endDate", end_date,
        "--userStats=TRUE",
        "--daysStats=TRUE",
        "--allMessages=TRUE",
        "--compactFormat=TRUE",  # Use compact timestamp format
        f"--namespaceId={namespace_owner_data['id']}"  # Pass namespace owner ID for message attribution
    ]
    
    # Add members file parameter if contacts file exists
    if contacts_file:
        cmd.extend(["--membersFile", contacts_file])
    
    # Add temp user info file as a fallback
    cmd.extend(["--userInfoFile", temp_user_info_file])
    
    # Add input and output files
    cmd.extend([json_file, markdown_file])
    
    logger.info(f"Converting JSON to markdown: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Clean up temporary file
        if os.path.exists(temp_user_info_file):
            os.remove(temp_user_info_file)
        
        if result.returncode != 0:
            logger.error(f"JSON to markdown conversion failed with return code {result.returncode}")
            logger.error(f"Error output: {result.stderr}")
            return False
        
        # Process the markdown to apply compact timestamp format
        post_process_markdown(markdown_file)
        
        logger.info(f"Successfully converted JSON to markdown: {markdown_file}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to run JSON to markdown conversion: {e}")
        # Clean up temporary file in case of error
        if os.path.exists(temp_user_info_file):
            os.remove(temp_user_info_file)
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

def process_command(identifier: str, time_spec: str = "1d", paths: Dict[str, str] = None) -> bool:
    """
    Process a tg2p command.
    
    Args:
        identifier: Username or alias
        time_spec: Time specification ('7d', 'all', '100', etc.)
        paths: Dictionary of paths to use
    
    Returns:
        True if successful, False otherwise
    """
    if paths is None:
        paths = DEFAULT_PATHS
        
    try:
        # Find all contact CSV files
        csv_files = find_contacts_csv_files(paths["contacts_dir"])
        if not csv_files:
            logger.error("No contact CSV files found")
            return False
        
        # Load contacts
        contacts = load_contacts(csv_files)
        
        # Find contact by identifier
        identifier = identifier.lower()
        contact = contacts.get(identifier)
        
        if not contact:
            logger.error(f"Contact not found: {identifier}")
            return False
        
        logger.info(f"Found contact: {contact}")
        
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
        if contact.username:
            file_part = f"@{contact.username}-tg_id-{contact.user_id}"
        else:
            file_part = f"user_{contact.user_id}-tg_id-{contact.user_id}"
        
        archive_old_markdown_files(namespace_dir, file_part, paths["archive_dir_name"])
        
        # Convert JSON to markdown (pass contact for proper user identification)
        if not convert_json_to_markdown(paths["json2md_script"], json_file, markdown_file, time_spec, contact):
            logger.error("Failed to convert JSON to markdown")
            return False
        
        logger.info(f"Successfully processed command: tg2p {identifier} {time_spec}")
        return True
        
    except Exception as e:
        logger.error(f"Error processing command: {e}")
        import traceback
        logger.debug(traceback.format_exc())
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Telegram to Prompt Message Retriever (tg2p)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  tg2p shimanskij 7d     # Retrieve 7 days of messages from shimanskij
  tg2p shimanskij all    # Retrieve all messages from shimanskij
  tg2p shimanskij 100    # Retrieve last 100 messages from shimanskij
  tg2p ilya 1m           # Retrieve 1 month of messages from ilya

Time modifiers:
  d - days (e.g., 7d = 7 days)
  w - weeks (e.g., 2w = 2 weeks)
  m - months (e.g., 1m = 1 month)
  y - years (e.g., 1y = 1 year)
  h - hours (e.g., 12h = 12 hours)
  (no suffix) - number of messages (e.g., 100 = last 100 messages)
  all - all messages
""")
    parser.add_argument('identifier', help='Username or alias of the contact')
    parser.add_argument('time_spec', nargs='?', default='1d', 
                        help='Time specification (e.g., 7d, 2w, 1m, 100, all)')
    parser.add_argument('--tdl-path', default=DEFAULT_PATHS["tdl_path"],
                        help=f'Path to tdl executable (default: {DEFAULT_PATHS["tdl_path"]})')
    parser.add_argument('--contacts-dir', default=DEFAULT_PATHS["contacts_dir"],
                        help=f'Directory containing contacts CSV files (default: {DEFAULT_PATHS["contacts_dir"]})')
    parser.add_argument('--raw-json-dir', default=DEFAULT_PATHS["raw_json_dir"],
                        help=f'Directory for storing raw JSON files (default: {DEFAULT_PATHS["raw_json_dir"]})')
    parser.add_argument('--markdown-dir', default=DEFAULT_PATHS["markdown_base_dir"],
                        help=f'Base directory for storing markdown files (default: {DEFAULT_PATHS["markdown_base_dir"]})')
    parser.add_argument('--log-level', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                       default='INFO', help='Set logging level')
    
    args = parser.parse_args()
    
    # Set log level
    logger.setLevel(getattr(logging, args.log_level))
    
    # Create custom paths dict with command-line overrides
    custom_paths = DEFAULT_PATHS.copy()
    custom_paths["tdl_path"] = args.tdl_path
    custom_paths["contacts_dir"] = args.contacts_dir
    custom_paths["raw_json_dir"] = args.raw_json_dir
    custom_paths["markdown_base_dir"] = args.markdown_dir
    
    # Process command with custom paths
    success = process_command(args.identifier, args.time_spec, custom_paths)
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
