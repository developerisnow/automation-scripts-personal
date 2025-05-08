#!/bin/bash

# Path to the obsidian file sorter script
SORTER_SCRIPT="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obsidian_file_sorter.py"
# Log file for this shell script's execution (distinct from the python script's log)
SHELL_LOG_FILE="/Users/user/____Sandruk/___PKM/logs/obsidian_hourly_sorter_runner.log"
# Log file used by the python script itself (should match DEFAULT_LOG_FILE or argument)
PYTHON_LOG_FILE="/Users/user/____Sandruk/___PKM/logs/obsidian_file_sorter.log"

# Ensure log directory exists for both logs
mkdir -p "$(dirname "$SHELL_LOG_FILE")"
mkdir -p "$(dirname "$PYTHON_LOG_FILE")"

# Function to run the sorter
run_sorter() {
    echo "-----------------------------------------" >> "$SHELL_LOG_FILE"
    echo "$(date): Starting obsidian file sorter run" >> "$SHELL_LOG_FILE"

    # Check if the script exists
    if [ ! -f "$SORTER_SCRIPT" ]; then
        echo "$(date): Error - Python script not found: $SORTER_SCRIPT" >> "$SHELL_LOG_FILE"
        echo "$(date): Obsidian file sorter run failed (script missing)" >> "$SHELL_LOG_FILE"
        return 1
    fi

    # Run the python script
    # Pass arguments if needed, e.g., --log-level DEBUG
    # Redirect python script's stdout/stderr to its own log file configured within the script
    # This shell script logs its own start/end/errors to SHELL_LOG_FILE
    python3 "$SORTER_SCRIPT" --log-file "$PYTHON_LOG_FILE" # Add other args like --verbose if desired

    SCRIPT_EXIT_CODE=$?

    # Check the result
    if [ $SCRIPT_EXIT_CODE -eq 0 ]; then
        echo "$(date): Python script finished successfully (Exit Code: $SCRIPT_EXIT_CODE)" >> "$SHELL_LOG_FILE"
        echo "$(date): Obsidian file sorter run completed" >> "$SHELL_LOG_FILE"
    else
        echo "$(date): Python script finished with errors (Exit Code: $SCRIPT_EXIT_CODE)" >> "$SHELL_LOG_FILE"
        echo "$(date): Obsidian file sorter run failed" >> "$SHELL_LOG_FILE"
    fi
     echo "-----------------------------------------" >> "$SHELL_LOG_FILE"
    return $SCRIPT_EXIT_CODE
}

# Execute the function
run_sorter

exit $? 