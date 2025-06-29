#!/usr/bin/env zsh
# 🎬 YouTube Tools Aliases
# ========================

# Base YouTube tools script
YT_TOOLS_SCRIPT="$HOME/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/youtube/yt-tools.sh"

# Make sure script is executable
[ -f "$YT_TOOLS_SCRIPT" ] && chmod +x "$YT_TOOLS_SCRIPT"

# 📝 Subtitles
# ------------
# Single video subtitles (already fixed)
alias ytsubs="node /Users/user/__Repositories/youtube-scrapping/youtube-captions-scraper/yt-subs.js"

# Download and optimize subtitles in one command
alias ytsubso="bash /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/youtube/yt-subs-optimized.sh"

# Playlist subtitles
alias ytsubsplaylist="$YT_TOOLS_SCRIPT subsplaylist"

# All channel subtitles (organized by playlist)
alias ytsubsall="$YT_TOOLS_SCRIPT subsall"

# 📋 Playlists
# ------------
# List all playlists from a channel
alias ytplaylists="$YT_TOOLS_SCRIPT playlists"

# 🎥 Videos
# ---------
# List videos in a specific playlist
alias ytvideosplaylist="$YT_TOOLS_SCRIPT videosplaylist"

# List all videos from a channel
alias ytvideosall="$YT_TOOLS_SCRIPT videosall"

# ⬇️ Downloads
# ------------
# Minimal video download for transcription
alias ytdownloadmin="$YT_TOOLS_SCRIPT downloadmin"

# 🛠️ Utilities
# ------------
# Quick channel info
alias ytchannelinfo='yt-dlp --print "Channel: %(channel)s\nChannel ID: %(channel_id)s\nChannel URL: %(channel_url)s"'

# Check available subtitles for a video
alias ytsubsavailable='yt-dlp --list-subs'

# Get video metadata
alias ytvideometa='yt-dlp --print "Title: %(title)s\nDuration: %(duration_string)s\nUpload: %(upload_date)s\nViews: %(view_count)s"'

# 📊 Batch Operations
# -------------------
# Process multiple channels from a file
ytbatch() {
    local file=$1
    local action=$2
    
    if [ -z "$file" ] || [ -z "$action" ]; then
        echo "Usage: ytbatch <channels_file> <action>"
        echo "Actions: playlists, subsall, videosall"
        return 1
    fi
    
    while IFS= read -r channel; do
        [ -z "$channel" ] || [[ "$channel" =~ ^# ]] && continue
        echo "Processing: $channel"
        $YT_TOOLS_SCRIPT "$action" "$channel"
    done < "$file"
}

# 🔍 Search in downloaded content
# -------------------------------
# Search in subtitles
ytsearch() {
    local pattern=$1
    local base_dir="/Users/user/____Sandruk/___PKM/_Outputs_External/youtube"
    
    if [ -z "$pattern" ]; then
        echo "Usage: ytsearch <pattern>"
        return 1
    fi
    
    echo "🔍 Searching for: $pattern"
    rg -i "$pattern" "$base_dir" --type-add 'subs:*.{vtt,srt,md}' -t subs
}

# 📈 Statistics
# -------------
# Channel statistics
ytchannelstats() {
    local channel=$1
    if [ -z "$channel" ]; then
        echo "Usage: ytchannelstats <channel>"
        return 1
    fi
    
    echo "📊 Fetching channel statistics..."
    yt-dlp --flat-playlist --print "Videos: %(playlist_count)s" "$channel"
}

# 🎯 Quick Actions
# ----------------
# Download audio only (for podcasts/music)
alias ytaudio='yt-dlp -x --audio-format mp3 --audio-quality 0'

# Get transcript of latest video from channel
ytlatestrans() {
    local channel=$1
    if [ -z "$channel" ]; then
        echo "Usage: ytlatestrans <channel>"
        return 1
    fi
    
    local latest=$(yt-dlp --flat-playlist --playlist-items 1 --print "%(id)s" "$channel/videos")
    ytsubs "$latest"
}

# Optimize subtitles for reduced context
alias ytoptimize='bash /Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/youtube/yt-optimize.sh'
alias ytopt='ytoptimize'  # Short alias

# Batch optimize all subtitles in a folder
ytoptall() {
    local interval=${1:-2}
    echo "🔄 Optimizing all subtitles with ${interval}min intervals"
    find . -name "*.vtt" -o -name "*.srt" -o -name "*.md" | while read -r file; do
        ytoptimize "$file" "$interval"
    done
}

# 📝 Help
# -------
alias ythelp='echo "
🎬 YouTube Tools Help
====================

📝 Subtitles:
  ytsubs <video>              - Download subtitles for single video
  ytsubso <video> [lang] [min]- Download & optimize subtitles
  ytsubsplaylist <playlist>   - Download subtitles for playlist
  ytsubsall <channel>         - Download all channel subtitles

📋 Lists:
  ytplaylists <channel>       - List channel playlists
  ytvideosplaylist <playlist> - List playlist videos
  ytvideosall <channel>       - List all channel videos

⬇️ Downloads:
  ytdownloadmin <video>       - Minimal quality for transcription
  ytaudio <video>             - Audio only (MP3)

🔍 Utilities:
  ytsearch <pattern>          - Search in downloaded subtitles
  ytchannelinfo <video>       - Get channel info from video
  ytsubsavailable <video>     - Check available subtitles
  ytvideometa <video>         - Get video metadata

🎯 Quick Actions:
  ytlatestrans <channel>      - Get transcript of latest video
  ytbatch <file> <action>     - Process multiple channels
  ytoptimize <file> [mins]    - Optimize subtitle timestamps
  ytopt <file> [mins]         - Short alias for ytoptimize
  ytoptall [mins]             - Optimize all subs in folder

📊 All outputs saved to:
  ~/____Sandruk/___PKM/_Outputs_External/
"'