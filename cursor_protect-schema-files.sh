#!/bin/bash

# Configuration
REPO_PATH="/Users/user/__Repositories/LLMs-airpg__belbix"
MIGRATIONS_PATH="$REPO_PATH/src/db/migrations"
SCHEMAS_PATH="$REPO_PATH/src/models/validation"
CHECKSUM_FILE="$REPO_PATH/.cursor/protected_files.sha256"
GIT_ATTRIBUTES_FILE="$REPO_PATH/.gitattributes"

# Function to set git attributes
setup_git_protection() {
    echo "🔒 Setting up Git protection..."
    
    # Create or update .gitattributes
    cat > "$GIT_ATTRIBUTES_FILE" << EOF
# Protected files
src/db/migrations/*.ts lockfile
src/models/validation/**/*.ts lockfile
EOF
    
    # Configure Git to handle locked files
    cd "$REPO_PATH" || exit 1
    git config --local include.path ../.gitconfig
    git config --local core.protectFiles true
    git config --local core.protectHunks true
}

# Function to lock files
lock_files() {
    local path=$1
    echo "🔒 Locking files in $path"
    
    # Standard file permissions
    find "$path" -name "*.ts" -type f -exec chmod 444 {} \;
    
    # Set immutable flag (requires sudo)
    echo "🔐 Setting immutable flags (requires sudo)..."
    find "$path" -name "*.ts" -type f -exec sudo chflags schg {} \;
    
    update_checksums
    setup_git_protection
}

# Function to unlock files
unlock_files() {
    local path=$1
    echo "🔓 Unlocking files in $path"
    
    # Remove immutable flag (requires sudo)
    echo "🔓 Removing immutable flags (requires sudo)..."
    find "$path" -name "*.ts" -type f -exec sudo chflags noschg {} \;
    
    # Reset permissions
    find "$path" -name "*.ts" -type f -exec chmod 644 {} \;
}

# Function to update checksums
update_checksums() {
    echo "📝 Updating checksums"
    mkdir -p "$(dirname "$CHECKSUM_FILE")"
    find "$MIGRATIONS_PATH" "$SCHEMAS_PATH" -name "*.ts" -type f -exec sha256sum {} \; > "$CHECKSUM_FILE"
}

# Function to verify checksums
verify_checksums() {
    echo "🔍 Verifying file integrity"
    if [ -f "$CHECKSUM_FILE" ]; then
        sha256sum -c "$CHECKSUM_FILE" || {
            echo "❌ File integrity violation detected!"
            echo "🔄 Restoring protection..."
            lock_files "$MIGRATIONS_PATH"
            lock_files "$SCHEMAS_PATH"
            return 1
        }
    else
        echo "⚠️ No checksum file found. Run with lock command first."
        return 1
    fi
}

# Main script logic
case "$1" in
    "lock")
        case "$2" in
            "migrations")
                lock_files "$MIGRATIONS_PATH"
                ;;
            "schemas")
                lock_files "$SCHEMAS_PATH"
                ;;
            "all")
                lock_files "$MIGRATIONS_PATH"
                lock_files "$SCHEMAS_PATH"
                ;;
            *)
                echo "Usage: $0 lock [migrations|schemas|all]"
                exit 1
                ;;
        esac
        ;;
    "unlock")
        case "$2" in
            "migrations")
                unlock_files "$MIGRATIONS_PATH"
                ;;
            "schemas")
                unlock_files "$SCHEMAS_PATH"
                ;;
            "all")
                unlock_files "$MIGRATIONS_PATH"
                unlock_files "$SCHEMAS_PATH"
                ;;
            *)
                echo "Usage: $0 unlock [migrations|schemas|all]"
                exit 1
                ;;
        esac
        ;;
    "verify")
        verify_checksums
        ;;
    *)
        echo "Usage: $0 [lock|unlock|verify] [migrations|schemas|all]"
        exit 1
        ;;
esac
