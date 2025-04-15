#!/usr/bin/env python3
import os
import subprocess
import time
import shutil
import logging
import glob
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
        for file in glob.glob(os.path.join(PROJECT_ROOT, "_files", "csv", f"chats_{session_name_without_ext}_*.csv")):
            if os.path.isfile(file):
                csv_file = file
                break
        
        if csv_file:
            # Copy the file to the output directory with a standardized name
            destination = os.path.join(OUTPUT_DIR, f"telegram-{session_name_without_ext}-contacts-chats-list.csv")
            shutil.copy2(csv_file, destination)
            logging.info(f"Copied CSV file to {destination}")
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
