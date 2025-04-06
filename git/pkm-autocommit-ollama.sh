#!/bin/bash

# PKM Auto-Commit Script with LLM-generated commit messages using Ollama directly
# This script uses Ollama local LLM to generate commit messages without OpenCommit

# Configuration
PKM_DIR="${HOME}/path/to/your/obsidian/pkm"  # Replace with your actual PKM directory path
LOG_FILE="${HOME}/logs/pkm-autocommit.log"   # Log file path
OLLAMA_MODEL="mistral"                       # Model to use (mistral, llama3, etc.)
OLLAMA_URL="http://localhost:11434"          # Ollama API URL
MAX_DIFF_SIZE=10000                          # Maximum diff size to send to Ollama

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to check if Ollama is running
check_ollama() {
    if ! curl -s "$OLLAMA_URL/api/version" > /dev/null; then
        log "Ollama not running. Please start Ollama service"
        exit 1
    fi
}

# Function to check if repository has changes
has_changes() {
    cd "$PKM_DIR" || { log "Failed to change to PKM directory: $PKM_DIR"; exit 1; }
    git status --porcelain | grep -q "."
}

# Function to generate commit message using Ollama
generate_commit_message() {
    local diff=$(git diff --staged | head -c $MAX_DIFF_SIZE)
    
    log "Generating commit message with Ollama ($OLLAMA_MODEL)..."
    
    local prompt="Generate a concise and meaningful git commit message based on the following git diff. Follow the Conventional Commits format (type: description). Focus on the most important changes. Diff: $diff"
    
    # Call Ollama API to generate commit message
    local response=$(curl -s "$OLLAMA_URL/api/generate" \
        -d "{\"model\": \"$OLLAMA_MODEL\", \"prompt\": \"$prompt\", \"stream\": false}")
    
    # Extract just the commit message from response
    local message=$(echo "$response" | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"//')
    
    # Clean up message (remove quotes, limit to first paragraph)
    message=$(echo "$message" | head -n1 | sed 's/^[" ]*//' | sed 's/[" ]*$//')
    
    # Default message if empty or too short
    if [ ${#message} -lt 10 ]; then
        message="chore: update PKM content"
    fi
    
    echo "$message"
}

# Main execution
main() {
    log "Starting PKM auto-commit process with Ollama"
    
    # Check if Ollama is running
    check_ollama
    
    # Navigate to PKM directory
    cd "$PKM_DIR" || { log "Failed to change to PKM directory: $PKM_DIR"; exit 1; }
    
    log "Checking for changes in PKM repository"
    
    # Check if there are any changes to commit
    if has_changes; then
        log "Changes detected. Staging changes..."
        git add -A
        
        # Generate commit message
        commit_message=$(generate_commit_message)
        
        log "Committing with message: $commit_message"
        if git commit -m "$commit_message"; then
            log "Successfully committed changes"
            
            # Push changes to remote repository (optional)
            log "Pushing changes to remote repository..."
            git push
            log "Successfully pushed changes"
        else
            log "Failed to commit changes"
            exit 1
        fi
    else
        log "No changes detected in PKM repository"
    fi
    
    log "PKM auto-commit process completed"
}

# Execute the main function
main 