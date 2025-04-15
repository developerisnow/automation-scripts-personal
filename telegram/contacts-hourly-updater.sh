#!/bin/bash

# Path to the contacts updater script
UPDATER_SCRIPT="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/telegram/contacts-periodic-updater-csv-telethon-manager.py"
LOG_FILE="/Users/user/____Sandruk/___PKM/__Vaults_Databases/__People__vault/DatabaseContacts/logs/hourly_updater.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to run the updater
run_updater() {
    echo "$(date): Starting telegram contacts hourly update" >> "$LOG_FILE"
    
    # Check if the script exists
    if [ ! -f "$UPDATER_SCRIPT" ]; then
        echo "$(date): Error - Script not found: $UPDATER_SCRIPT" >> "$LOG_FILE"
        return 1
    fi
    
    # Run the script
    "$UPDATER_SCRIPT" >> "$LOG_FILE" 2>&1
    
    # Check the result
    if [ $? -eq 0 ]; then
        echo "$(date): Contacts update completed successfully" >> "$LOG_FILE"
    else
        echo "$(date): Contacts update failed with exit code $?" >> "$LOG_FILE"
    fi
}

# Main loop
while true; do
    # Check if the computer is idle (not in sleep mode)
    # This is a simple check, but it works for this purpose
    if pmset -g ps | grep -q "AC Power"; then
        run_updater
    else
        echo "$(date): Computer is on battery power, skipping update" >> "$LOG_FILE"
    fi
    
    # Sleep for 1 hour
    sleep 3600
done 