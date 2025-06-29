#!/bin/bash
# 🎯 YouTube Subtitle Download & Optimize
# =======================================
# Downloads subtitles and immediately optimizes them

# Base directories
PKM_BASE="/Users/user/____Sandruk/___PKM/_Outputs_External/subtitles-youtube"
OPTIMIZER_SCRIPT="$(dirname "$0")/yt-timestamp-optimizer.js"
YTSUBS_SCRIPT="/Users/user/__Repositories/youtube-scrapping/youtube-captions-scraper/yt-subs.js"

# Default values
DEFAULT_LANG="en"
DEFAULT_INTERVAL=2

# Function to show usage
show_usage() {
    echo "Usage: ytsubso <video_url|video_id> [language] [interval]"
    echo ""
    echo "Downloads subtitles and optimizes them with grouped timestamps"
    echo ""
    echo "Parameters:"
    echo "  video      YouTube video URL or ID"
    echo "  language   Subtitle language (default: en)"
    echo "  interval   Grouping interval in minutes (default: 2)"
    echo ""
    echo "Examples:"
    echo "  ytsubso dQw4w9WgXcQ              # English, 2-minute intervals"
    echo "  ytsubso dQw4w9WgXcQ ru           # Russian, 2-minute intervals"
    echo "  ytsubso dQw4w9WgXcQ en 5         # English, 5-minute intervals"
    echo ""
    echo "Output naming:"
    echo "  Original: YYYY-MM-DD-subs-title__by-channel.md"
    echo "  Optimized: YYYY-MM-DD-subs-title_grouped2m__by-channel.md"
}

# Check parameters
if [ -z "$1" ]; then
    show_usage
    exit 1
fi

VIDEO="$1"
LANG="${2:-$DEFAULT_LANG}"
INTERVAL="${3:-$DEFAULT_INTERVAL}"

echo "🎬 Downloading subtitles for video: $VIDEO"
echo "📝 Language: $LANG"
echo "⏱️  Interval: ${INTERVAL} minutes"
echo ""

# Step 1: Download subtitles
echo "Step 1: Downloading subtitles..."
cd "$PKM_BASE" || exit 1
node "$YTSUBS_SCRIPT" "$VIDEO" "$LANG"

# Check if download was successful by finding the most recent .md file
SUBTITLE_FILE=$(ls -t *.md 2>/dev/null | head -1)

if [ -z "$SUBTITLE_FILE" ] || [ ! -f "$SUBTITLE_FILE" ]; then
    echo "❌ Failed to download subtitles"
    exit 1
fi

echo "✅ Downloaded: $SUBTITLE_FILE"
echo ""

# Step 2: Optimize the subtitle file
echo "Step 2: Optimizing with ${INTERVAL}-minute intervals..."
node "$OPTIMIZER_SCRIPT" "$SUBTITLE_FILE" --interval "$INTERVAL"

# Check if optimization was successful
OPTIMIZED_FILE="${SUBTITLE_FILE%.md}_grouped${INTERVAL}m.md"

if [ -f "$OPTIMIZED_FILE" ]; then
    echo ""
    echo "✅ Success! Files created:"
    echo "   Original: $SUBTITLE_FILE"
    echo "   Optimized: $OPTIMIZED_FILE"
    
    # Show file sizes for comparison
    ORIGINAL_SIZE=$(wc -l < "$SUBTITLE_FILE")
    OPTIMIZED_SIZE=$(wc -l < "$OPTIMIZED_FILE")
    REDUCTION=$(( 100 - (OPTIMIZED_SIZE * 100 / ORIGINAL_SIZE) ))
    
    echo ""
    echo "📊 Statistics:"
    echo "   Original lines: $ORIGINAL_SIZE"
    echo "   Optimized lines: $OPTIMIZED_SIZE"
    echo "   Reduction: ${REDUCTION}%"
else
    echo "❌ Optimization failed"
    exit 1
fi