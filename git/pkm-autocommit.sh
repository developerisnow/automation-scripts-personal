#!/bin/bash

# PKM Auto-Commit Script with LLM-generated commit messages
# This script automates commits to your Obsidian PKM repository
# It uses OpenCommit to generate meaningful commit messages based on changes

# Configuration
PKM_DIR="${HOME}/____Sandruk/___PKM"  # Replace with your actual PKM directory path
COMMIT_PREFIX="[PKM-AutoCommit]"             # Optional prefix for all commit messages
LOG_FILE="${HOME}/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/git/logs/pkm-autocommit.log"   # Log file path
PUSH_TO_REMOTE=false                         # Set to true if you want to push to remote

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to check if OpenCommit is installed
check_opencommit() {
    if ! command -v oco &> /dev/null; then
        log "OpenCommit not found. Please install it with: pnpm install -g opencommit"
        exit 1
    fi
}

# Function to check if repository has changes
has_changes() {
    cd "$PKM_DIR" || { log "Failed to change to PKM directory: $PKM_DIR"; exit 1; }
    git status --porcelain | grep -q "."
}

# Function to check if remote repository is configured
has_remote() {
    cd "$PKM_DIR" || { log "Failed to change to PKM directory: $PKM_DIR"; exit 1; }
    git remote -v | grep -q "."
}

# Main execution
main() {
    log "Starting PKM auto-commit process"
    
    # Check if OpenCommit is installed
    check_opencommit
    
    # Navigate to PKM directory
    cd "$PKM_DIR" || { log "Failed to change to PKM directory: $PKM_DIR"; exit 1; }
    
    log "Checking for changes in PKM repository"
    
    # Check if there are any changes to commit
    if has_changes; then
        log "Changes detected. Staging changes..."
        git add -A
        
        log "Generating commit message with OpenCommit..."
        # Use OpenCommit to generate and apply the commit message
        # The --yes flag skips the confirmation prompt
        if oco --yes; then
            log "Successfully committed changes with OpenCommit"
            
            # Push changes to remote repository (if configured and enabled)
            if [ "$PUSH_TO_REMOTE" = true ] && has_remote; then
                log "Pushing changes to remote repository..."
                if git push; then
                    log "Successfully pushed changes"
                else
                    log "Failed to push changes to remote repository"
                    log "You can push manually later or check your remote configuration"
                fi
            elif [ "$PUSH_TO_REMOTE" = true ]; then
                log "No remote repository configured. Skipping push operation."
                log "To configure a remote, use: git remote add origin <repository-url>"
            else
                log "Push to remote is disabled. Changes committed locally only."
            fi
        else
            log "Failed to commit changes with OpenCommit"
            exit 1
        fi
    else
        log "No changes detected in PKM repository"
    fi
    
    log "PKM auto-commit process completed"
}

# Execute the main function
main 