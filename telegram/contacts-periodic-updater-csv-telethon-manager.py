#!/usr/bin/env python3
import os
import subprocess
import time
import shutil
import logging
import glob
import csv
from datetime import datetime
import argparse

# Configurable paths
PROJECT_ROOT = "/Users/user/__Repositories/tg-combainer__developerisnow"
SESSIONS_DIR = os.path.join(PROJECT_ROOT, "env", "tg_sessions")
OUTPUT_DIR = "/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts"

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Setup logging
def setup_logger():
    log_dir = os.path.join(OUTPUT_DIR, "logs")
    os.makedirs(log_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(log_dir, f"contacts_updater_{timestamp}.log")
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )

def get_session_files(skip_archived=True):
    """Get all session files from the sessions directory."""
    session_files = glob.glob(os.path.join(SESSIONS_DIR, "*.session"))
    
    if skip_archived:
        # Filter out sessions in the archived directory
        session_files = [f for f in session_files if "archived" not in f]
    
    return session_files

def is_group_or_channel(row, headers):
    """Helper function to determine if an entity is a group or channel."""
    # Check for title first - groups and channels usually have titles
    title_index = -1
    if 'Title' in headers:
        title_index = headers.index('Title')
    
    has_title = (title_index >= 0 and 
                title_index < len(row) and 
                row[title_index] and 
                row[title_index] != 'None')
    
    if not has_title:
        return None  # Not a group/channel
    
    # Check for Megagroup flag
    megagroup_index = -1
    if 'Megagroup' in headers:
        megagroup_index = headers.index('Megagroup')
    
    is_megagroup = (megagroup_index >= 0 and 
                    megagroup_index < len(row) and 
                    row[megagroup_index] == 'True')
    
    # Check for Gigagroup flag
    gigagroup_index = -1
    if 'Gigagroup' in headers:
        gigagroup_index = headers.index('Gigagroup')
    
    is_gigagroup = (gigagroup_index >= 0 and 
                   gigagroup_index < len(row) and 
                   row[gigagroup_index] == 'True')
    
    # Check for Participants Count
    has_participants = False
    if 'Participants Count' in headers:
        participants_index = headers.index('Participants Count')
        has_participants = (participants_index >= 0 and
                           participants_index < len(row) and
                           row[participants_index] and
                           row[participants_index] != '0' and
                           row[participants_index] != 'None')
    
    # Logic for determining group vs channel
    if is_megagroup or is_gigagroup:
        return "Group"
    elif has_participants:
        return "Group"  # If it has participants, it's likely a group
    elif has_title:
        return "Channel"  # Default case for entities with titles
    
    return None

def run_telegram_for_session(session_name):
    """Run the main.py script with the specified session."""
    session_name_without_ext = os.path.basename(session_name).replace(".session", "")
    
    logging.info(f"Starting process for session: {session_name_without_ext}")
    
    # Change to project directory
    os.chdir(PROJECT_ROOT)
    
    # Command to run
    cmd = [
        "poetry", "run", "python", "src_python/main.py",
        "--run=dialogs",
        "--store=csv",
        f"--session={session_name_without_ext}"
    ]
    
    # Record start time
    start_time = time.time()
    
    try:
        # Run the command and capture output
        process = subprocess.Popen(
            cmd, 
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Real-time logging of output
        while True:
            output = process.stdout.readline()
            if output == '' and process.poll() is not None:
                break
            if output:
                logging.info(output.strip())
        
        # Get return code
        return_code = process.wait()
        
        # Process stderr if there was an error
        if return_code != 0:
            stderr = process.stderr.read()
            logging.error(f"Error running command: {stderr}")
            return False
        
        # Find the generated CSV file
        csv_file = None
        
        # Find all matching CSV files
        csv_files = glob.glob(os.path.join(PROJECT_ROOT, "_files", "csv", f"chats_{session_name_without_ext}_*.csv"))
        
        if csv_files:
            # Get the file with the most records
            max_records = 0
            for file in csv_files:
                if os.path.isfile(file):
                    # Count the lines in this file
                    try:
                        with open(file, 'r', encoding='utf-8') as f:
                            line_count = sum(1 for _ in f)
                        
                        logging.info(f"Found CSV file: {file} with {line_count} lines")
                        
                        if line_count > max_records:
                            max_records = line_count
                            csv_file = file
                    except Exception as e:
                        logging.warning(f"Error counting lines in {file}: {str(e)}")
            
            if csv_file:
                logging.info(f"Selected file with most records: {csv_file} ({max_records} lines)")
            else:
                logging.error(f"No valid CSV files found for session {session_name_without_ext}")
                return False
        else:
            logging.error(f"No CSV files found for session {session_name_without_ext}")
            return False
        
        if csv_file:
            # Copy the file to the output directory with a standardized name
            destination = os.path.join(OUTPUT_DIR, f"telegram-{session_name_without_ext}-contacts-chats-list.csv")
            
            # Read the CSV file and make sure it has the correct headers
            with open(csv_file, 'r', newline='', encoding='utf-8') as src_file:
                csv_reader = csv.reader(src_file)
                try:
                    headers = next(csv_reader)
                    rows = list(csv_reader)
                    logging.info(f"CSV file has {len(headers)} headers and {len(rows)} rows")
                except Exception as e:
                    logging.error(f"Error reading CSV file: {str(e)}")
                    # Just copy the file directly as a fallback
                    shutil.copy2(csv_file, destination)
                    logging.info(f"Direct copy of CSV file to {destination} due to read error")
                    return True
            
            # The expected headers for our updated format
            expected_headers = [
                'tg_session', 'ID', 'Username', 'Alias', 'Title', 'Type', 'Usernames', 'First Name', 
                'Last Name', 'Phone', 'Contact', 'Premium', 'Lang Code', 
                'Mutual Contact', 'Is Self', 'Deleted', 'Bot', 'Bot Chat History', 
                'Bot No Chats', 'Verified', 'Restricted', 'Min', 'Bot Inline Geo', 
                'Support', 'Scam', 'Apply Min Photo', 'Fake', 'Bot Attach Menu', 
                'Attach Menu Enabled', 'Access Hash', 'Status Original', 'Status Date', 
                'Status Time', 'Status Datetime', 'Bot Info Version', 
                'Restriction Reason', 'Bot Inline Placeholder', 'Emoji Status',
                'Megagroup', 'Gigagroup', 'Participants Count'
            ]
            
            # Check if the headers match the expected format
            header_mapping = {}
            for idx, header in enumerate(headers):
                if header in expected_headers:
                    header_mapping[idx] = expected_headers.index(header)
            
            # Write to the destination file
            with open(destination, 'w', newline='', encoding='utf-8') as dst_file:
                csv_writer = csv.writer(
                    dst_file,
                    quoting=csv.QUOTE_NONNUMERIC,  # Quote all non-numeric fields
                    escapechar='\\',               # Use backslash for escaping
                    doublequote=True               # Double quotes within quoted strings
                )
                csv_writer.writerow(expected_headers)
                
                # Direct format conversion - no row skipping
                if 'Type' in headers and 'Alias' in headers:
                    # The format already matches what we expect
                    logging.info("CSV already has the correct format, copying all records")
                    csv_writer.writerows(rows)
                
                # Old header format missing Alias and Type
                elif 'Alias' not in headers and 'Type' not in headers and len(headers) >= 4:
                    # This is the old format without Alias and Type
                    logging.info(f"Converting from old format (missing Alias and Type fields) with {len(rows)} rows")
                    
                    count = 0
                    for row in rows:
                        if len(row) >= 4:  # Ensure we have at least ID, Username, Title
                            new_row = [
                                row[0],  # tg_session
                                row[1],  # ID
                                row[2],  # Username
                                '',      # Alias (empty)
                                row[3],  # Title
                                '',      # Type (determine from data)
                            ]
                            
                            # Determine entity type
                            entity_type = "User"  # Default
                            
                            # Check for Bot flag
                            is_bot = False
                            for i in range(len(row)):
                                if i >= 15 and i <= 17 and i < len(row) and row[i] == 'True':  # Bot field is usually around 16
                                    is_bot = True
                                    break
                            
                            if is_bot:
                                entity_type = "Bot"
                            else:
                                # Check if it's a group or channel based on title and properties
                                has_title = row[3] != 'None' and row[3]
                                has_megagroup = False
                                
                                # Look for Megagroup flag anywhere after position 30
                                for i in range(len(row)):
                                    if i >= 30 and i < len(row) and row[i] == 'True':
                                        has_megagroup = True
                                        break
                                
                                if has_title:
                                    if has_megagroup:
                                        entity_type = "Group"
                                    else:
                                        entity_type = "Channel"
                            
                            new_row[5] = entity_type  # Set the determined type
                            
                            # Add the rest of the fields from index 4 onwards
                            new_row.extend(row[4:])
                            
                            # Convert all values to strings to ensure proper quoting
                            row_strings = [str(value) if value is not None else '' for value in new_row]
                            csv_writer.writerow(row_strings)
                            count += 1
                        else:
                            logging.warning(f"Skipping row with insufficient data: {row}")
                    
                    logging.info(f"Converted and wrote {count} records to destination")
                
                # Headers fewer than expected - need mapping
                elif len(headers) < len(expected_headers):
                    logging.info(f"Converting format with {len(headers)} headers to expected format with {len(expected_headers)} headers, {len(rows)} rows")
                    
                    count = 0
                    for row in rows:
                        # The source has fewer columns than expected - need to map and fill
                        new_row = [""] * len(expected_headers)
                        
                        # Copy the values we have
                        for i, value in enumerate(row):
                            if i < len(headers):
                                # Find the corresponding index in expected_headers
                                header_name = headers[i]
                                if header_name in expected_headers:
                                    target_index = expected_headers.index(header_name)
                                    new_row[target_index] = value
                        
                        # Special handling for entity type
                        if 'Type' not in headers:
                            # Use our helper function to determine entity type
                            group_or_channel = is_group_or_channel(row, headers)
                            
                            if group_or_channel:
                                entity_type = group_or_channel
                            else:
                                # Check if it's a bot
                                entity_type = "User"  # Default
                                bot_index = -1
                                if 'Bot' in headers:
                                    bot_index = headers.index('Bot')
                                
                                if bot_index >= 0 and bot_index < len(row) and row[bot_index] == 'True':
                                    entity_type = "Bot"
                            
                            # Set the Type field
                            type_index = expected_headers.index('Type')
                            new_row[type_index] = entity_type
                        
                        # Convert all values to strings
                        row_strings = [str(value) if value is not None else '' for value in new_row]
                        csv_writer.writerow(row_strings)
                        count += 1
                    
                    logging.info(f"Mapped and wrote {count} records to destination")
                
                # Headers more than expected - we'll still try to map
                else:
                    logging.info(f"Source CSV has more headers ({len(headers)}) than expected ({len(expected_headers)}), attempting to map")
                    
                    # Create a mapping from source headers to expected headers
                    header_mapping = {}
                    for src_idx, header in enumerate(headers):
                        if header in expected_headers:
                            dst_idx = expected_headers.index(header)
                            header_mapping[src_idx] = dst_idx
                    
                    count = 0
                    for row in rows:
                        new_row = [""] * len(expected_headers)
                        
                        # Map the fields we can
                        for src_idx, value in enumerate(row):
                            if src_idx in header_mapping:
                                dst_idx = header_mapping[src_idx]
                                new_row[dst_idx] = value
                        
                        # Special handling for entity type if needed
                        if 'Type' not in headers:
                            # Use our helper function to determine entity type
                            group_or_channel = is_group_or_channel(row, headers)
                            
                            if group_or_channel:
                                entity_type = group_or_channel
                            else:
                                # Check if it's a bot
                                entity_type = "User"  # Default
                                bot_index = -1
                                if 'Bot' in headers:
                                    bot_index = headers.index('Bot')
                                
                                if bot_index >= 0 and bot_index < len(row) and row[bot_index] == 'True':
                                    entity_type = "Bot"
                            
                            # Set the Type field
                            type_index = expected_headers.index('Type')
                            new_row[type_index] = entity_type
                        
                        # Convert all values to strings
                        row_strings = [str(value) if value is not None else '' for value in new_row]
                        csv_writer.writerow(row_strings)
                        count += 1
                    
                    logging.info(f"Mapped and wrote {count} records to destination")
            
            logging.info(f"Copied CSV file to {destination} with correct format")
            return True
        else:
            logging.error(f"No CSV file found for session {session_name_without_ext}")
            return False
            
    except Exception as e:
        logging.error(f"Exception running command for {session_name_without_ext}: {str(e)}")
        return False
    finally:
        elapsed_time = time.time() - start_time
        logging.info(f"Completed process for {session_name_without_ext} in {elapsed_time:.2f} seconds")

def main():
    parser = argparse.ArgumentParser(description="Telegram Contacts Updater")
    parser.add_argument("--test", action="store_true", help="Run only on test sessions")
    parser.add_argument("--sessions", nargs="+", help="Specific session names to process")
    args = parser.parse_args()
    
    setup_logger()
    logging.info("Starting Telegram Contacts Updater")
    
    if args.test:
        # Use only the test sessions
        test_sessions = ["singularity_explorer", "usernyme", "crispr_cas9_ceo"]
        session_files = [os.path.join(SESSIONS_DIR, f"{s}.session") for s in test_sessions]
        # Filter to only existing files
        session_files = [f for f in session_files if os.path.exists(f)]
    elif args.sessions:
        # Use specified sessions
        session_files = [os.path.join(SESSIONS_DIR, f"{s}.session") for s in args.sessions]
        # Filter to only existing files
        session_files = [f for f in session_files if os.path.exists(f)]
    else:
        # Get all session files
        session_files = get_session_files()
    
    if not session_files:
        logging.error("No session files found")
        return
    
    logging.info(f"Found {len(session_files)} session files")
    
    success_count = 0
    for session_file in session_files:
        if run_telegram_for_session(session_file):
            success_count += 1
        # Add a delay between sessions to avoid rate limiting
        time.sleep(5)
    
    logging.info(f"Completed processing {success_count} of {len(session_files)} sessions successfully")

if __name__ == "__main__":
    main()
