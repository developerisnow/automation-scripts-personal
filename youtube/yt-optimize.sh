#!/bin/bash
# 🎯 YouTube Subtitle Optimizer Wrapper
# ====================================

OPTIMIZER_SCRIPT="$(dirname "$0")/yt-timestamp-optimizer.js"

# Make sure Node.js script is executable
chmod +x "$OPTIMIZER_SCRIPT"

# Function to show help
show_help() {
    echo "🎯 YouTube Subtitle Optimizer"
    echo ""
    echo "Usage:"
    echo "  yt-optimize <file_or_pattern> [interval]"
    echo ""
    echo "Examples:"
    echo "  yt-optimize subtitle.vtt                    # Optimize single file (default 2 min)"
    echo "  yt-optimize subtitle.vtt 5                  # Use 5 minute intervals"
    echo "  yt-optimize '*.vtt' 3                       # Batch optimize with 3 min intervals"
    echo "  yt-optimize-all anthropic_ai 5             # Optimize all subs for channel"
    echo ""
    echo "Intervals:"
    echo "  1   = Every minute (minimal reduction)"
    echo "  2   = Every 2 minutes (default, ~40% reduction)"
    echo "  5   = Every 5 minutes (~70% reduction)"
    echo "  10  = Every 10 minutes (~85% reduction)"
}

# Function to optimize a single file
optimize_file() {
    local file=$1
    local interval=${2:-2}
    
    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file"
        return 1
    fi
    
    echo "🔄 Optimizing: $file (${interval}min intervals)"
    node "$OPTIMIZER_SCRIPT" "$file" --interval "$interval"
}

# Function to optimize all subtitles for a channel
optimize_channel() {
    local channel_pattern=$1
    local interval=${2:-2}
    local base_dir="/Users/user/____Sandruk/___PKM/_Outputs_External/youtube"
    
    echo "🔍 Finding subtitles for channel pattern: $channel_pattern"
    
    # Find all subtitle files for the channel
    local count=0
    while IFS= read -r file; do
        optimize_file "$file" "$interval"
        ((count++))
    done < <(find "$base_dir" -name "*${channel_pattern}*" -type d -exec find {} -name "*.vtt" -o -name "*.srt" -o -name "*.md" \;)
    
    echo "✅ Optimized $count files"
}

# Main logic
case "$1" in
    "")
        show_help
        ;;
    -h|--help|help)
        show_help
        ;;
    *)
        # Check if it's a file first
        if [ -f "$1" ]; then
            # Single file
            optimize_file "$1" "$2"
        elif [[ "$1" == *"*"* ]]; then
            # Pattern - batch process
            interval=${2:-2}
            for file in $1; do
                optimize_file "$file" "$interval"
            done
        elif [[ "$1" == *_* ]] && [ ! -f "$1" ]; then
            # Channel pattern only if not a file
            optimize_channel "$1" "$2"
        else
            echo "❌ File or pattern not found: $1"
            exit 1
        fi
        ;;
esac