#!/usr/bin/env python3
import os
import subprocess
import time
import shutil
import logging
import glob
import csv
import json
from datetime import datetime, timedelta
import argparse

# Configurable paths
PROJECT_ROOT = "/Users/user/__Repositories/tg-combainer__developerisnow"
SESSIONS_DIR = os.path.join(PROJECT_ROOT, "env", "tg_sessions")
OUTPUT_DIR = "/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts"

# Configuration
MAX_TODAY_CHATS = 100  # Лимит на количество чатов, которые могут получить сегодняшнюю дату за один запуск скрипта (Max # of chats to mark with today's date in one run)

# Store chat order history for tracking changes
CHAT_ORDER_FILE = os.path.join(OUTPUT_DIR, "telegram-chat-orders.json")

# Initialization file for first-time chat date assignment
INIT_FILE = os.path.join(OUTPUT_DIR, "telegram-chat-orders-init.json")

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

def save_chat_order(session_name, chat_order):
    """Save the current chat order to track changes."""
    orders = {}
    
    # Load existing orders if file exists
    if os.path.exists(CHAT_ORDER_FILE):
        try:
            with open(CHAT_ORDER_FILE, 'r') as f:
                orders = json.load(f)
        except Exception as e:
            logging.warning(f"Error loading chat order file: {str(e)}")
            orders = {}
    
    # Update with new order for this session
    orders[session_name] = {
        "updated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "order": chat_order
    }
    
    # Save back to file
    try:
        with open(CHAT_ORDER_FILE, 'w') as f:
            json.dump(orders, f, indent=2)
    except Exception as e:
        logging.error(f"Error saving chat order file: {str(e)}")

def get_previous_chat_order(session_name):
    """Get the previous chat order for comparison."""
    if not os.path.exists(CHAT_ORDER_FILE):
        return {}
    
    try:
        with open(CHAT_ORDER_FILE, 'r') as f:
            orders = json.load(f)
            if session_name in orders:
                return orders[session_name].get("order", {})
    except Exception as e:
        logging.warning(f"Error reading previous chat order: {str(e)}")
    
    return {}

def load_chat_date_init_mapping():
    """
    Load chat date mappings from the initialization file.
    This file is used only once for initial setup of chat dates.
    
    The file should contain:
    - position_ranges: list of objects with max_position and date
    - default_date: date to use for chats not in any range
    
    Returns dict with position ranges and default date
    """
    if not os.path.exists(INIT_FILE):
        logging.info(f"Initialization file not found: {INIT_FILE}")
        return None
    
    try:
        with open(INIT_FILE, 'r') as f:
            init_data = json.load(f)
            
        if 'position_ranges' not in init_data or 'default_date' not in init_data:
            logging.warning("Initialization file missing required fields")
            return None
        
        # Get position ranges
        position_ranges = init_data.get('position_ranges', [])
        default_date = init_data.get('default_date')
        
        # Sort ranges by max_position, highest first
        position_ranges.sort(key=lambda x: x.get('max_position', 0))
        
        logging.info(f"Loaded initialization data with {len(position_ranges)} position ranges")
        return {
            'position_ranges': position_ranges,
            'default_date': default_date
        }
        
    except Exception as e:
        logging.warning(f"Error loading chat date initialization data: {str(e)}")
        return None

def get_global_today_chat_counter():
    """
    Подсчитать общее количество чатов с сегодняшней датой по всем CSV файлам.
    Возвращает общее количество и словарь с ID чатов с сегодняшней датой.
    """
    today = datetime.now().strftime("%Y-%m-%d")
    today_chats = {}
    total_count = 0
    
    csv_files = glob.glob(os.path.join(OUTPUT_DIR, "telegram-*-contacts-chats-list.csv"))
    logging.info(f"Found {len(csv_files)} CSV files to check for today's date")
    
    for csv_file in csv_files:
        try:
            # Проверяем, что файл существует и не пустой
            if not os.path.exists(csv_file) or os.path.getsize(csv_file) == 0:
                logging.warning(f"Empty or non-existent CSV file: {csv_file}")
                continue
                
            with open(csv_file, 'r', newline='', encoding='utf-8') as f:
                reader = csv.reader(f)
                try:
                    headers = next(reader)
                except StopIteration:
                    # Пустой файл, пропускаем
                    logging.warning(f"Empty CSV file (no headers): {csv_file}")
                    continue
                
                # Find key columns
                try:
                    id_idx = headers.index('ID')
                    day_contacted_idx = headers.index('DayLastContacted')
                except ValueError as e:
                    # Нет нужных колонок
                    logging.warning(f"Missing required column in {csv_file}: {str(e)}")
                    continue
                
                # Используем простой способ подсчета вместо итерации
                file_count = 0
                for row in reader:
                    if len(row) <= day_contacted_idx or len(row) <= id_idx:
                        continue
                    
                    chat_id = row[id_idx]
                    day_contacted = row[day_contacted_idx]
                    
                    if day_contacted == today:
                        if chat_id not in today_chats:
                            today_chats[chat_id] = True
                            file_count += 1
                
                logging.info(f"Found {file_count} chats with today's date in {os.path.basename(csv_file)}")
                total_count += file_count
                
        except Exception as e:
            logging.warning(f"Error counting today's chats in {csv_file}: {str(e)}")
    
    logging.info(f"Found a total of {total_count} chats already marked with today's date across all CSV files")
    return total_count, today_chats

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
                'tg_session', 'ID', 'Username', 'DayLastContacted', 'Title', 'Type', 'Usernames', 'First Name', 
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
                
                # Track current chat order for this session
                current_chat_order = {}
                order_position = 0
                
                # Get previous chat order
                previous_chat_order = get_previous_chat_order(session_name_without_ext)
                
                # Today's date in YYYY-MM-DD format
                today_date = datetime.now().strftime("%Y-%m-%d")
                yesterday_date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
                
                # Check if we need to load boundary data for initialization
                # Count how many rows have empty DayLastContacted values
                empty_date_count = sum(1 for row in rows if len(row) > 0 and len(row) < len(expected_headers))
                
                # If many rows have empty dates, load initialization data
                init_boundaries = None
                if empty_date_count > len(rows) * 0.5:  # If more than 50% need initialization
                    logging.info(f"Found {empty_date_count} rows without dates, loading initialization data")
                    init_boundaries = load_chat_date_init_mapping()
                    if init_boundaries:
                        logging.info(f"Loaded initialization data with position ranges: {init_boundaries['position_ranges']}")
                        logging.info(f"First 30 chats will get date 2025-04-16, next 30 will get 2025-04-15, etc.")
                    else:
                        logging.info("No initialization data found, will use default dates")
                
                # Get count of chats already marked with today's date
                today_count, today_chats_dict = get_global_today_chat_counter()
                logging.info(f"Found {today_count} chats already marked with today's date")
                
                # Calculate how many more chats we can mark with today's date
                remaining_today_slots = max(0, MAX_TODAY_CHATS - today_count)
                logging.info(f"Can mark up to {remaining_today_slots} more chats with today's date in this session")
                
                # Direct format conversion - no row skipping
                if 'Type' in headers and 'Alias' in headers:
                    # The format already matches what we expect
                    logging.info("CSV already has the correct format, processing records")
                    
                    # Создадим списки для отслеживания активности чатов
                    active_today_chats = []
                    
                    # Первый проход - находим самые активные чаты для присвоения им сегодняшней даты
                    for row_index, row in enumerate(rows):
                        # Убедимся, что у нас достаточно данных
                        if len(row) <= 1:
                            continue
                        
                        # Get the chat ID
                        id_index = headers.index('ID') if 'ID' in headers else 1
                        chat_id = row[id_index] if id_index < len(row) else ""
                        
                        # Store chat order для дальнейшего использования
                        order_position = row_index + 1
                        current_chat_order[chat_id] = order_position
                        
                        # Determine if this chat was recently active
                        was_active_today = False
                        
                        # Если чат переместился вверх в порядке или новый в топе
                        if chat_id in previous_chat_order:
                            prev_position = previous_chat_order[chat_id]
                            # Если позиция улучшилась (меньшее число лучше)
                            if order_position < prev_position:
                                was_active_today = True
                        elif row_index < 30:  # Новый чат в первых 30 позициях
                            was_active_today = True
                        
                        # Если чат был активен сегодня и не уже отмечен с сегодняшней датой
                        if was_active_today and chat_id not in today_chats_dict:
                            # Игнорируем старые чаты, если они не очень активны
                            if chat_id == "268748450" or (int(chat_id) < 300000000 if chat_id.isdigit() else False):
                                if order_position < 10:  # Только если он действительно активен
                                    active_today_chats.append((chat_id, row_index, order_position))
                            else:
                                active_today_chats.append((chat_id, row_index, order_position))
                    
                    # Сортируем активные чаты по порядку, чтобы приоритизировать самые активные
                    active_today_chats.sort(key=lambda x: x[2])
                    
                    # Все активные чаты будут помечены сегодняшней датой
                    new_today_chat_ids = {chat_id for chat_id, _, _ in active_today_chats}
                    
                    logging.info(f"Will mark {len(new_today_chat_ids)} active chats with today's date in this session")
                    
                    # Второй проход - обновляем даты
                    preserved_dates_count = 0
                    updated_today_count = 0
                    init_applied_count = 0
                    for row_index, row in enumerate(rows):
                        # First check if the row already has all fields
                        if len(row) >= len(expected_headers):
                            new_row = list(row)
                        else:
                            # Extend the row to match expected headers
                            new_row = list(row) + [""] * (len(expected_headers) - len(row))
                        
                        # Get the chat ID
                        id_index = headers.index('ID') if 'ID' in headers else 1
                        chat_id = row[id_index] if id_index < len(row) else ""
                        
                        # Get current DayLastContacted value
                        day_contacted_index = len(expected_headers) - 1  # Last column
                        current_day_contacted = new_row[day_contacted_index] if day_contacted_index < len(new_row) and new_row[day_contacted_index] else ""
                        
                        # Если чат уже помечен с сегодняшней датой, оставляем как есть
                        if current_day_contacted == today_date:
                            preserved_dates_count += 1
                        # Если чат в списке для присвоения сегодняшней даты (активный)
                        elif chat_id in new_today_chat_ids:
                            new_row[day_contacted_index] = today_date
                            updated_today_count += 1
                        # Если еще нет даты и есть данные инициализации, используем их
                        elif not current_day_contacted and init_boundaries:
                            # Определяем дату на основе границ из файла инициализации
                            new_row[day_contacted_index] = get_date_for_chat_by_position(
                                chat_id, row_index + 1, init_boundaries
                            )
                            init_applied_count += 1
                        # Если еще нет даты, ставим вчерашнюю
                        elif not current_day_contacted:
                            new_row[day_contacted_index] = yesterday_date
                        # В остальных случаях оставляем существующую дату без изменений
                        
                        # Special case for chat ID 268748450 and similar old chats
                        if chat_id == "268748450" or (int(chat_id) < 300000000 if chat_id.isdigit() else False):
                            # Only update if it's clearly active today
                            if was_active_today and order_position < 10:
                                new_row[-1] = today_date
                                updated_today_count += 1
                            # If no date set yet and we have initialization data
                            elif not new_row[-1] and init_boundaries:
                                # Use initialization data boundaries
                                new_row[-1] = get_date_for_chat_by_position(
                                    chat_id, row_index + 1, init_boundaries
                                )
                                init_applied_count += 1
                            elif not new_row[-1]:
                                # If no date set yet, use yesterday's date for old chats
                                yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
                                new_row[-1] = yesterday
                            elif new_row[-1] == today_date:
                                preserved_dates_count += 1
                        else:
                            # For regular chats
                            if was_active_today:
                                new_row[-1] = today_date
                                updated_today_count += 1
                            # If no date set yet and we have initialization data
                            elif not new_row[-1] and init_boundaries:
                                # Use initialization data boundaries
                                new_row[-1] = get_date_for_chat_by_position(
                                    chat_id, row_index + 1, init_boundaries
                                )
                                init_applied_count += 1
                            elif not new_row[-1]:
                                # Default to yesterday if no date is set yet
                                new_row[-1] = yesterday
                            elif new_row[-1] == today_date:
                                preserved_dates_count += 1
                        
                        # Convert all values to strings to ensure proper quoting
                        row_strings = [str(value) if value is not None else '' for value in new_row]
                        csv_writer.writerow(row_strings)
                    
                    logging.info(f"Date assignment summary: {preserved_dates_count} chats already had today's date, {updated_today_count} chats were marked with today's date, {len(rows) - preserved_dates_count - updated_today_count} chats maintained their historical dates")
                    if init_applied_count > 0:
                        logging.info(f"Initialization applied to {init_applied_count} chats using position-based ranges")
                # Old header format missing Alias and Type
                elif 'Alias' not in headers and 'Type' not in headers and len(headers) >= 4:
                    # This is the old format without Alias and Type
                    logging.info(f"Converting from old format (missing Alias and Type fields) with {len(rows)} rows")
                    
                    # Track current chat order for this session
                    current_chat_order = {}
                    order_position = 0
                    
                    # Get previous chat order
                    previous_chat_order = get_previous_chat_order(session_name_without_ext)
                    
                    # Today's date in YYYY-MM-DD format
                    today_date = datetime.now().strftime("%Y-%m-%d")
                    
                    count = 0
                    preserved_dates_count = 0
                    updated_today_count = 0
                    init_applied_count = 0
                    for row_index, row in enumerate(rows):
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
                            
                            # Ensure we have all the fields we need, including DayLastContacted
                            if len(new_row) < len(expected_headers):
                                new_row.extend([''] * (len(expected_headers) - len(new_row)))
                            
                            # Get the chat ID
                            chat_id = row[1] if len(row) > 1 else ""
                            
                            # Store chat order
                            order_position += 1
                            current_chat_order[chat_id] = order_position
                            
                            # Determine if this chat was recently active
                            was_active_today = False
                            
                            # If this chat moved up in the order or is new, mark it as active today
                            if chat_id in previous_chat_order:
                                prev_position = previous_chat_order[chat_id]
                                # If position improved (lower number is better)
                                if order_position < prev_position:
                                    was_active_today = True
                            elif row_index < 30:  # New chat in the first 30 positions
                                was_active_today = True
                            
                            # Special case for chat ID 268748450 and similar old chats
                            if chat_id == "268748450" or (int(chat_id) < 300000000 if chat_id.isdigit() else False):
                                # Only update if it's clearly active today
                                if was_active_today and order_position < 10:
                                    new_row[-1] = today_date
                                    updated_today_count += 1
                                # If no date set yet and we have initialization data
                                elif not new_row[-1] and init_boundaries:
                                    # Use initialization data boundaries
                                    new_row[-1] = get_date_for_chat_by_position(
                                        chat_id, row_index + 1, init_boundaries
                                    )
                                    init_applied_count += 1
                                elif not new_row[-1]:
                                    # If no date set yet, use yesterday's date for old chats
                                    yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
                                    new_row[-1] = yesterday
                                elif new_row[-1] == today_date:
                                    preserved_dates_count += 1
                            else:
                                # For regular chats
                                if was_active_today:
                                    new_row[-1] = today_date
                                    updated_today_count += 1
                                # If no date set yet and we have initialization data
                                elif not new_row[-1] and init_boundaries:
                                    # Use initialization data boundaries
                                    new_row[-1] = get_date_for_chat_by_position(
                                        chat_id, row_index + 1, init_boundaries
                                    )
                                    init_applied_count += 1
                                elif not new_row[-1]:
                                    # Default to yesterday if no date is set yet
                                    new_row[-1] = yesterday
                                elif new_row[-1] == today_date:
                                    preserved_dates_count += 1
                            
                            # Convert all values to strings to ensure proper quoting
                            row_strings = [str(value) if value is not None else '' for value in new_row]
                            csv_writer.writerow(row_strings)
                            count += 1
                        else:
                            logging.warning(f"Skipping row with insufficient data: {row}")
                    
                    # Save the current chat order
                    save_chat_order(session_name_without_ext, current_chat_order)
                    
                    logging.info(f"Date assignment summary: {preserved_dates_count} chats already had today's date, {updated_today_count} chats were marked with today's date, {count - preserved_dates_count - updated_today_count} chats maintained their historical dates")
                    if init_applied_count > 0:
                        logging.info(f"Initialization applied to {init_applied_count} chats using position-based ranges")
                    logging.info(f"Converted and wrote {count} records to destination")
                # Other formats
                else:
                    logging.error(f"Unrecognized CSV format in {csv_file}")
                    # Just copy the file directly as a fallback
                    shutil.copy2(csv_file, destination)
                    return True
            
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

def get_date_for_chat_by_position(chat_id, chat_position, init_data=None):
    """
    Determine the appropriate date for a chat based on its position in the list.
    Only used during initial setup when DayLastContacted is empty.
    
    Args:
        chat_id: The Telegram chat ID (not used for comparison)
        chat_position: The position of the chat in the list (1-based)
        init_data: Dict with position_ranges and default_date
        
    Returns:
        A date string in YYYY-MM-DD format
    """
    if not init_data or 'position_ranges' not in init_data:
        # Default to yesterday if no initialization data
        return (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
    
    # Get position ranges and default date
    position_ranges = init_data.get('position_ranges', [])
    default_date = init_data.get('default_date')
    
    # Find the appropriate date based on position
    for range_data in position_ranges:
        max_position = range_data.get('max_position', 0)
        if chat_position <= max_position:
            return range_data.get('date')
    
    # If no matching range, use default date
    return default_date

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
