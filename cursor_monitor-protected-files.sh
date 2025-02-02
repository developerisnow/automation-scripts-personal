#!/bin/bash

# Configuration
REPO_PATH="/Users/user/__Repositories/LLMs-airpg__belbix"
MIGRATIONS_PATH="$REPO_PATH/src/db/migrations"
SCHEMAS_PATH="$REPO_PATH/src/models/validation"
CHECKSUM_FILE="$REPO_PATH/.cursor/protected_files.sha256"
LOCK_SCRIPT="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/cursor_protect-schema-files.sh"

# Function to restore protection
restore_protection() {
    local file=$1
    echo "🔄 Restoring protection for: $file"
    
    # Remove immutable flag if it exists
    sudo chflags noschg "$file" 2>/dev/null
    
    # Restore from Git if modified
    if git diff --quiet "$file"; then
        git restore "$file"
    fi
    
    # Re-apply protection
    sudo chflags schg "$file"
    chmod 444 "$file"
    
    # Update checksums
    "$LOCK_SCRIPT" verify
}

# Function to handle file changes
handle_change() {
    local file=$1
    echo "⚠️ Change detected in protected file: $file"
    
    # Verify checksums
    if [ -f "$CHECKSUM_FILE" ]; then
        if ! sha256sum -c "$CHECKSUM_FILE" 2>/dev/null | grep "$file"; then
            echo "❌ File integrity violation detected in: $file"
            restore_protection "$file"
            
            # Log the violation
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Integrity violation detected and fixed: $file" >> "$REPO_PATH/logs/protection.log"
            
            # Optional: Send notification
            osascript -e "display notification \"Integrity violation detected and fixed in $file\" with title \"File Protection Alert\""
        fi
    else
        echo "⚠️ No checksum file found. Protection may be incomplete."
        "$LOCK_SCRIPT" lock all
    fi
}

# Ensure log directory exists
mkdir -p "$REPO_PATH/logs"

# Start monitoring
echo "🔍 Starting file monitor for protected directories..."
echo "   Watching: $MIGRATIONS_PATH"
echo "   Watching: $SCHEMAS_PATH"

# Initial protection verification
"$LOCK_SCRIPT" verify

# Monitor for changes
fswatch -o "$MIGRATIONS_PATH" "$SCHEMAS_PATH" | while read file
do
    handle_change "$file"
done
