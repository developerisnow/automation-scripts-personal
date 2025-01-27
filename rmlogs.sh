#!/bin/bash

# Function to recreate logs directory
recreate_logs() {
    local path="${1:-logs}"  # Default to 'logs' if no argument provided
    rm -r "$path"
    mkdir "$path"
    tree "$path"
}

# Function to handle test fixtures
handle_test_fixtures() {
    pwd
    recreate_logs "test/__fixtures__/logs"
}

handle_test_data() {
    pwd
    recreate_logs "logs/test-data"
}

case "$1" in
    "fixt") handle_test_fixtures ;;
    "test-data") handle_test_data ;;
    *) 
        recreate_logs 
        handle_test_data  # Ensure test-data folder is created by default
esac
