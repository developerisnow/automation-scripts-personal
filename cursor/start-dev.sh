#!/bin/bash

PROJECT_DIR="$HOME/__Repositories/LLMs-cursor-chat-browser"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/app-$(date +%Y-%m-%d).log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Navigate to project directory
cd "$PROJECT_DIR"

# Check if the project is already running
if lsof -i :3201 > /dev/null; then
    echo "Port 3201 is already in use. Stopping existing process..."
    kill $(lsof -t -i:3201)
    sleep 2
fi

# Start the application with logging
echo "Starting application at $(date)" >> "$LOG_FILE"
npm run dev >> "$LOG_FILE" 2>&1
