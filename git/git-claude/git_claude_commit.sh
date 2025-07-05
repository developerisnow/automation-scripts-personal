#!/usr/bin/env bash
# 🤖 Git Claude Commit Script v2.0
# =================================
# Commits .claude folders and CLAUDE* files across multiple repositories
# Uses dynamic config file with auto-discovery and 24h cooldown

set -euo pipefail

# 📁 Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/claude-folders-registry.json"
SEARCH_PATHS=("$HOME/__Repositories" "$HOME/____Sandruk")

# ✨ Cleanup logic for temp files
TEMP_FILES=()
cleanup() {
    # The check prevents errors if the array is empty
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        rm -f "${TEMP_FILES[@]}"
    fi
}
trap cleanup EXIT

# 🎨 Colors for ADHD-friendly output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 🔧 Utility Functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_header() { echo -e "${PURPLE}$1${NC}"; }

# 📅 Get current timestamp in ISO format
get_current_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# 🕒 Check if discovery should run (24h cooldown)
should_run_discovery() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 0  # Run discovery if config doesn't exist
    fi
    
    local last_discovery
    last_discovery=$(jq -r '.meta.last_discovery // empty' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$last_discovery" || "$last_discovery" == "null" ]]; then
        return 0  # Run discovery if never run before
    fi
    
    # Convert timestamps to seconds since epoch
    local last_seconds current_seconds interval_seconds
    # Try GNU date first, fall back to BSD date (macOS)
    if date --version >/dev/null 2>&1; then
        # GNU date
        last_seconds=$(date -d "$last_discovery" +%s 2>/dev/null || echo 0)
    else
        # BSD date (macOS)
        last_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_discovery" +%s 2>/dev/null || echo 0)
    fi
    current_seconds=$(date +%s)
    interval_seconds=$((24 * 60 * 60))  # 24 hours
    
    if [[ $((current_seconds - last_seconds)) -gt $interval_seconds ]]; then
        return 0  # Run discovery if more than 24h passed
    else
        local hours_left=$(( (interval_seconds - (current_seconds - last_seconds)) / 3600 ))
        log_info "Discovery cooldown active. Next discovery in ~${hours_left}h"
        return 1  # Skip discovery
    fi
}

# 🔍 Auto-discover .claude folders
discover_claude_folders() {
    log_header "🔍 Auto-discovering .claude folders..."
    
    local new_paths_found=0
    local current_timestamp
    current_timestamp=$(get_current_timestamp)
    
    # Create temp file for new discoveries
    local temp_discoveries
    temp_discoveries=$(mktemp)
    TEMP_FILES+=("$temp_discoveries") # Register for cleanup

    for search_path in "${SEARCH_PATHS[@]}"; do
        if [[ ! -d "$search_path" ]]; then
            log_warning "Search path doesn't exist: $search_path"
            continue
        fi
        
        log_info "Searching in: $search_path"
        
        # Find .claude directories and process them one by one
        find "$search_path" -type d -name ".claude" -maxdepth 5 2>/dev/null | while IFS= read -r claude_dir; do
            # Skip if already in config
            if jq -e --arg path "$claude_dir" '.claude_paths | has($path)' "$CONFIG_FILE" >/dev/null 2>&1; then
                continue
            fi
            
            echo "$claude_dir" >> "$temp_discoveries"
            log_success "Found new .claude folder: $claude_dir"
        done
    done
    
    new_paths_found=$(grep -c . "$temp_discoveries")

    # Add new discoveries to config
    if [[ "$new_paths_found" -gt 0 ]]; then
        log_header "📝 Adding ${new_paths_found} new paths to registry..."
        
        # Update config with new paths
        local temp_config="/tmp/claude_config_$$"
        jq --arg timestamp "$current_timestamp" \
           --rawfile newpaths "$temp_discoveries" \
           '.meta.last_discovery = $timestamp |
            (.claude_paths += (
                $newpaths | split("\n") | map(select(length > 0)) | 
                map({
                    key: ., 
                    value: {
                        "added_timestamp": $timestamp,
                        "type": "auto-discovered",
                        "active": true
                    }
                }) | from_entries
            ))' "$CONFIG_FILE" > "$temp_config"
        
        mv "$temp_config" "$CONFIG_FILE"
        log_success "Updated registry with $new_paths_found new paths"
    else
        # Update last discovery time even if no new paths found
        jq --arg timestamp "$current_timestamp" '.meta.last_discovery = $timestamp' "$CONFIG_FILE" > "/tmp/claude_config_$$"
        mv "/tmp/claude_config_$$" "$CONFIG_FILE"
        log_info "No new .claude folders found"
    fi
    
    # The trap will handle cleanup
}

# 📚 Load paths from config file
load_claude_paths() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Extract active paths from config
    jq -r '.claude_paths | to_entries[] | select(.value.active == true) | .key' "$CONFIG_FILE"
}

# 💾 Main commit function
commit_claude_files() {
    # Use a temporary file to store paths, avoiding process substitution
    local temp_paths_file
    temp_paths_file=$(mktemp)
    TEMP_FILES+=("$temp_paths_file") # Register for cleanup

    load_claude_paths > "$temp_paths_file"

    if [[ ! -s "$temp_paths_file" ]]; then
        log_warning "No active Claude directories found in config"
        return 0
    fi
    
    local path_count
    path_count=$(wc -l < "$temp_paths_file" | tr -d '[:space:]')
    
    log_header "🤖 Starting Claude files commit across ${path_count} repositories..."
    echo
    
    local committed_count=0
    local skipped_count=0
    
    while IFS= read -r dir; do
        if [[ -z "$dir" ]]; then continue; fi # Skip empty lines

        log_info "📁 Checking: $dir"
        
        # Check if directory exists
        if [[ ! -d "$dir" ]]; then
            log_warning "Directory doesn't exist, skipping..."
            ((skipped_count++))
            echo
            continue
        fi
        
        # Get the repository root (go up until we find .git)
        local repo_root="$dir"
        while [[ "$repo_root" != "/" && ! -d "$repo_root/.git" ]]; do
            repo_root="$(dirname "$repo_root")"
        done
        
        # Check if we found a git repository
        if [[ ! -d "$repo_root/.git" ]]; then
            log_warning "Not in a git repository, skipping..."
            ((skipped_count++))
            echo
            continue
        fi
        
        log_success "Found git repo at: $repo_root"
        
        # Change to repository root
        cd "$repo_root" || continue
        
        # Add Claude files (both .claude dirs and CLAUDE* files)
        echo -e "${PURPLE}📝 Adding Claude files...${NC}"
        
        # Calculate relative path from repo root to target directory
        local rel_path="${dir#$repo_root}"
        rel_path="${rel_path#/}"  # Remove leading slash if present
        
        # Add files with different strategies based on directory structure
        if [[ -n "$rel_path" ]]; then
            # Target directory is a subdirectory of repo root
            git add "$rel_path" 2>/dev/null || true
            git add "$rel_path"/.claude 2>/dev/null || true
            git add "$rel_path"/CLAUDE* 2>/dev/null || true
        else
            # Target directory IS the repo root
            git add .claude 2>/dev/null || true
            git add CLAUDE* 2>/dev/null || true
            git add . 2>/dev/null || true  # Add everything in claude config repo
        fi
        
        # Check if anything was actually staged
        if ! git diff --cached --quiet; then
            # Commit with message
            log_success "💾 Committing changes..."
            git commit -m "chore(claude): bulk changes" --no-verify
            
            if [[ $? -eq 0 ]]; then
                log_success "Successfully committed in: $repo_root"
                ((committed_count++))
            else
                log_error "Commit failed in: $repo_root"
            fi
        else
            log_warning "📝 No changes to commit, skipping..."
            ((skipped_count++))
        fi
        echo
    done < "$temp_paths_file"
    
    # 📊 Summary
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    log_success "Successfully committed: $committed_count repositories"
    log_warning "Skipped: $skipped_count locations"
    log_header "🎉 Claude commit operation completed!"
}

# 🧠 Commit memory-bank directories
commit_memory_bank_folders() {
    log_header "🧠 Starting memory-bank commit..."
    
    local found_banks=0
    local temp_banks_file
    temp_banks_file=$(mktemp)
    TEMP_FILES+=("$temp_banks_file")

    for search_path in "${SEARCH_PATHS[@]}"; do
        if [[ ! -d "$search_path" ]]; then
            continue
        fi
        
        # Find directories named "memory-bank", up to a reasonable depth
        find "$search_path" -type d -name "memory-bank" -maxdepth 5 2>/dev/null | while IFS= read -r mb_dir; do
            # Check if it is a real directory and not a symbolic link
            if [[ -d "$mb_dir" && ! -L "$mb_dir" ]]; then
                echo "$mb_dir" >> "$temp_banks_file"
                ((found_banks++))
            fi
        done
    done

    if [[ $found_banks -eq 0 ]]; then
        log_info "No 'memory-bank' directories found to commit."
        echo
        return
    fi

    log_info "Found $found_banks 'memory-bank' directories to process."

    while IFS= read -r dir; do
        if [[ -z "$dir" ]]; then continue; fi

        log_info "📁 Checking memory-bank: $dir"
        
        local repo_root="$dir"
        while [[ "$repo_root" != "/" && ! -d "$repo_root/.git" ]]; do
            repo_root="$(dirname "$repo_root")"
        done
        
        if [[ ! -d "$repo_root/.git" ]]; then
            log_warning "Not in a git repository, skipping..."
            ((skipped_count++))
            echo
            continue
        fi
        
        log_success "Found git repo at: $repo_root"
        cd "$repo_root" || continue
        
        echo -e "${PURPLE}📝 Adding memory-bank files...${NC}"
        
        local rel_path="${dir#$repo_root}"
        rel_path="${rel_path#/}"
        
        git add "$rel_path"
        
        if ! git diff --cached --quiet; then
            log_success "💾 Committing changes..."
            git commit -m "chore(memory-bank): bulk changes" --no-verify
            
            if [[ $? -eq 0 ]]; then
                log_success "Successfully committed in: $repo_root"
                ((committed_count++))
            else
                log_error "Commit failed in: $repo_root"
            fi
        else
            log_warning "📝 No changes to commit, skipping..."
            ((skipped_count++))
        fi
        echo
    done < "$temp_banks_file"
}

# 🚀 Main execution
main() {
    log_header "🤖 Git Claude Commit Script v2.0"
    echo
    
    # Check if config file exists, create if not
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warning "Config file not found, creating initial config..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << 'EOF'
{
  "meta": {
    "last_discovery": null,
    "discovery_interval_hours": 24,
    "version": "2.0"
  },
  "claude_paths": {}
}
EOF
        log_success "Created initial config file"
    fi
    
    # Run discovery if needed (24h cooldown)
    if should_run_discovery; then
        discover_claude_folders
        echo
    fi
    
    # Initialize counters for summary
    committed_count=0
    skipped_count=0

    # Run main commit process for claude files
    commit_claude_files
    
    # Run commit process for memory-bank
    commit_memory_bank_folders

    # 📊 Summary
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    log_success "Successfully committed: $committed_count repositories"
    log_warning "Skipped: $skipped_count locations"
    log_header "🎉 Full operation completed!"
}

# Execute main function
main "$@"
