#!/bin/zsh
# 🚀 Clean Terminal Workspace Functions (Enhanced with Path Aliases)
# ================================================================

# 📁 Path Aliases - Common Project Locations
declare -A WORKSPACE_PATHS
WORKSPACE_PATHS[back]="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-backend"
WORKSPACE_PATHS[front]="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-frontend"
WORKSPACE_PATHS[mono]="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-monorepo"
WORKSPACE_PATHS[api]="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-api"
WORKSPACE_PATHS[docs]="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-docs"
WORKSPACE_PATHS[garden]="/Users/user/__Repositories/HypeTrain/repositories/hypetrain-garden"
WORKSPACE_PATHS[pkm]="/Users/user/____Sandruk/___PKM"
WORKSPACE_PATHS[repos]="/Users/user/__Repositories"
WORKSPACE_PATHS[twin]="/Users/user/__Repositories/twin1-workspace"

# 🔧 Helper function to resolve path aliases
resolve_workspace_path() {
    local input="$1"
    
    # If it's empty, return current directory
    if [[ -z "$input" ]]; then
        echo "$PWD"
        return
    fi
    
    # If it's an alias, resolve it
    if [[ -n "${WORKSPACE_PATHS[$input]}" ]]; then
        echo "${WORKSPACE_PATHS[$input]}"
        return
    fi
    
    # If it starts with ~, expand it
    if [[ "$input" =~ ^~ ]]; then
        echo "${input/#\~/$HOME}"
        return
    fi
    
    # If it's an absolute path, use as-is
    if [[ "$input" =~ ^/ ]]; then
        echo "$input"
        return
    fi
    
    # Otherwise, treat as relative to current directory
    echo "$PWD/$input"
}

# 🎯 Enhanced launcher function with path support
launch_workspace() {
    local workspace_name="$1"
    local layout="${2:-2h}"  # Default to 2h (horizontal)
    local path_input="${3:-$PWD}"
    
    # Resolve the path using aliases
    local start_dir
    start_dir=$(resolve_workspace_path "$path_input")
    
    # Validate directory exists
    if [[ ! -d "$start_dir" ]]; then
        echo "❌ Directory not found: $start_dir"
        echo "💡 Available aliases: ${(k)WORKSPACE_PATHS}"
        echo "💡 Or provide a valid path"
        return 1
    fi
    
    echo "🚀 Launching workspace: $workspace_name with layout: $layout"
    echo "📁 Directory: $start_dir"
    
    # Kill existing session if it exists
    tmux kill-session -t "$workspace_name" 2>/dev/null
    
    case "$layout" in
        "1")
            # Single pane with neovim
            tmux new-session -d -s "$workspace_name" -c "$start_dir"
            tmux send-keys -t "$workspace_name:0" "nvim" Enter
            ;;
        "2h")
            # 2 horizontal panes: neovim + terminal
            tmux new-session -d -s "$workspace_name" -c "$start_dir"
            tmux split-window -h -t "$workspace_name:0" -c "$start_dir"
            tmux send-keys -t "$workspace_name:0.0" "nvim" Enter
            tmux select-pane -t "$workspace_name:0.1"
            ;;
        "2v")
            # 2 vertical panes: neovim + terminal
            tmux new-session -d -s "$workspace_name" -c "$start_dir"
            tmux split-window -v -t "$workspace_name:0" -c "$start_dir"
            tmux send-keys -t "$workspace_name:0.0" "nvim" Enter
            tmux select-pane -t "$workspace_name:0.1"
            ;;
        "3")
            # 3 panes: neovim (left) + 2 terminals (right, stacked)
            tmux new-session -d -s "$workspace_name" -c "$start_dir"
            tmux split-window -h -t "$workspace_name:0" -c "$start_dir"
            tmux split-window -v -t "$workspace_name:0.1" -c "$start_dir"
            tmux send-keys -t "$workspace_name:0.0" "nvim" Enter
            tmux select-pane -t "$workspace_name:0.1"
            ;;
        *)
            echo "❌ Unknown layout: $layout"
            echo "💡 Available layouts: 1, 2h, 2v, 3"
            return 1
            ;;
    esac
    
    # Attach to session
    tmux attach-session -t "$workspace_name"
}

# 🎯 Enhanced workspace launchers with path support
htgo() {
    local layout="${1:-2h}"
    local path_input="${2:-}"
    
    # If no path provided, try default hypetrain location
    if [[ -z "$path_input" ]]; then
        if [[ -d "/Users/user/__Repositories/hypetrain-workspace" ]]; then
            path_input="/Users/user/__Repositories/hypetrain-workspace"
        else
            path_input="$PWD"
        fi
    fi
    
    launch_workspace "hypetrain" "$layout" "$path_input"
}

twin1() {
    local layout="${1:-2h}"
    local path_input="${2:-}"
    
    # If no path provided, try default twin1 location
    if [[ -z "$path_input" ]]; then
        if [[ -d "/Users/user/__Repositories/twin1-workspace" ]]; then
            path_input="/Users/user/__Repositories/twin1-workspace"
        else
            path_input="$PWD"
        fi
    fi
    
    launch_workspace "twin1" "$layout" "$path_input"
}

# 🚀 Specific workspace functions for common paths
htgoback() {
    local layout="${1:-2h}"
    launch_workspace "hypetrain-backend" "$layout" "back"
}

htgofront() {
    local layout="${1:-2h}"
    launch_workspace "hypetrain-frontend" "$layout" "front"
}

htgomono() {
    local layout="${1:-2h}"
    launch_workspace "hypetrain-monorepo" "$layout" "mono"
}

htgoapi() {
    local layout="${1:-2h}"
    launch_workspace "hypetrain-api" "$layout" "api"
}

htgodocs() {
    local layout="${1:-2h}"
    launch_workspace "hypetrain-docs" "$layout" "docs"
}

htgogarden() {
    local layout="${1:-2h}"
    launch_workspace "hypetrain-garden" "$layout" "garden"
}

htgopkm() {
    local layout="${1:-2h}"
    launch_workspace "pkm-workspace" "$layout" "pkm"
}

# 🚀 Generic launcher for any workspace with full path support
workspace() {
    local name="$1"
    local layout="${2:-2h}"
    local path_input="${3:-$PWD}"
    
    if [[ -z "$name" ]]; then
        echo "❌ Usage: workspace <name> [layout] [path_or_alias]"
        echo "💡 Layouts: 1, 2h, 2v, 3"
        echo "💡 Aliases: ${(k)WORKSPACE_PATHS}"
        echo "💡 Examples:"
        echo "    workspace myproject 3 back"
        echo "    workspace coding 2v /path/to/project"
        echo "    workspace quick 1 pkm"
        return 1
    fi
    
    launch_workspace "$name" "$layout" "$path_input"
}

# 🔧 Workspace utilities
ws_list() {
    echo "🎯 Active workspaces:"
    tmux list-sessions 2>/dev/null || echo "No active sessions"
}

ws_kill() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "❌ Usage: ws_kill <workspace_name>"
        return 1
    fi
    tmux kill-session -t "$name" 2>/dev/null && echo "✅ Killed: $name" || echo "❌ Not found: $name"
}

ws_attach() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "❌ Usage: ws_attach <workspace_name>"
        echo "📋 Available sessions:"
        ws_list
        return 1
    fi
    tmux attach-session -t "$name" 2>/dev/null || echo "❌ Session not found: $name"
}

# 📁 Path alias utilities
ws_paths() {
    echo "📁 Available Path Aliases:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for alias path in ${(kv)WORKSPACE_PATHS}; do
        if [[ -d "$path" ]]; then
            echo "✅ $alias → $path"
        else
            echo "❌ $alias → $path (not found)"
        fi
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

ws_add_path() {
    local alias_name="$1"
    local path="$2"
    
    if [[ -z "$alias_name" ]] || [[ -z "$path" ]]; then
        echo "❌ Usage: ws_add_path <alias> <path>"
        echo "💡 Example: ws_add_path myproject /path/to/project"
        return 1
    fi
    
    # Expand path if needed
    local full_path
    full_path=$(resolve_workspace_path "$path")
    
    if [[ ! -d "$full_path" ]]; then
        echo "❌ Directory not found: $full_path"
        return 1
    fi
    
    WORKSPACE_PATHS[$alias_name]="$full_path"
    echo "✅ Added alias: $alias_name → $full_path"
    echo "💡 This is temporary. Add to config file for persistence."
}
