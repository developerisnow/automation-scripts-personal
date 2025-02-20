#!/bin/bash
##### START OBSIDIAN TO PROMPT #####
# Default paths and settings
export O2P_SCRIPT_PATH="/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/obsidian/obs2prompt_obsidian_to_prompt.py"
export OBSIDIAN_VAULT_PATH="/Users/user/____Sandruk/___PKM"
export O2P_OUTPUT_DIR="/Users/user/____Sandruk/___PKM/temp"

# Create output directory if it doesn't exist
[ ! -d "$O2P_OUTPUT_DIR" ] && mkdir -p "$O2P_OUTPUT_DIR"

# Main o2p function
function o2p {
    local start_file="$1"
    local depth="${2:-1}"
    local debug_flag="${3:-}"

    # Check if script exists
    if [ ! -f "$O2P_SCRIPT_PATH" ]; then
        echo "Error: Script not found at $O2P_SCRIPT_PATH"
        return 1
    fi

    # Check if input file is provided
    if [ -z "$start_file" ]; then
        echo "Usage: o2p <filename> [depth] [debug]"
        echo "Example: o2p 'my note.md' 2"
        return 1
    fi

    # Execute python script
    if [ -n "$debug_flag" ]; then
        python3 "$O2P_SCRIPT_PATH" "$start_file" \
            --vault "$OBSIDIAN_VAULT_PATH" \
            --depth "$depth" \
            --output "$O2P_OUTPUT_DIR/aggregate_${start_file%.md}.txt" \
            --debug
    else
        python3 "$O2P_SCRIPT_PATH" "$start_file" \
            --vault "$OBSIDIAN_VAULT_PATH" \
            --depth "$depth" \
            --output "$O2P_OUTPUT_DIR/aggregate_${start_file%.md}.txt"
    fi
}

# Convenience functions
function o2p1 { o2p "$1" 1; }
function o2p2 { o2p "$1" 2; }
function o2p3 { o2p "$1" 3; }
function o2pd { o2p "$1" 1 "debug"; }

# Setup check function
function o2p-check {
    echo "Checking o2p setup..."
    echo "Script path: $O2P_SCRIPT_PATH"
    echo "Vault path: $OBSIDIAN_VAULT_PATH"
    echo "Output directory: $O2P_OUTPUT_DIR"
    
    if [ -f "$O2P_SCRIPT_PATH" ]; then
        echo "✅ Script exists"
    else
        echo "❌ Script not found"
    fi
    
    if [ -d "$OBSIDIAN_VAULT_PATH" ]; then
        echo "✅ Vault exists"
    else
        echo "❌ Vault not found"
    fi
    
    if [ -d "$O2P_OUTPUT_DIR" ]; then
        echo "✅ Output directory exists"
    else
        echo "❌ Output directory not found"
    fi
    
    echo "Python environment:"
    which python3 || echo "❌ Python3 not found"
    python3 --version || echo "❌ Cannot get Python version"
    
    echo "Required packages:"
    if python3 -c "import pyperclip" 2>/dev/null; then
        echo "✅ pyperclip installed"
    else
        echo "❌ pyperclip not installed"
    fi
}
##### END OBSIDIAN TO PROMPT #####
