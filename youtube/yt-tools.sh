#!/bin/bash
# 🎬 YouTube Tools V2 - Organized folder structure
# ================================================

# Configuration
PKM_BASE="/Users/user/____Sandruk/___PKM/_Outputs_External/youtube"
YOUTUBE_ANALYZER="/Users/user/__Repositories/youtube-scrapping/youtube_channel_analyzer"
PYTHON_SCRIPT="$YOUTUBE_ANALYZER/src/main.py"
TEMP_CSV="/tmp/yt_temp_$$.csv"

# Ensure base directory exists
mkdir -p "$PKM_BASE"

# Function to detect input type and normalize
normalize_input() {
    local input=$1
    
    # Direct video URL
    if [[ $input =~ youtube\.com/watch\?v=([a-zA-Z0-9_-]{11}) ]] || [[ $input =~ youtu\.be/([a-zA-Z0-9_-]{11}) ]]; then
        echo "video:${BASH_REMATCH[1]}"
        return
    fi
    
    # Playlist URL
    if [[ $input =~ [\?\&]list=([^\&]+) ]]; then
        echo "playlist:${BASH_REMATCH[1]}"
        return
    fi
    
    # Channel formats
    if [[ $input =~ youtube\.com/@([^/]+) ]]; then
        echo "channel:@${BASH_REMATCH[1]}"
    elif [[ $input =~ youtube\.com/c/([^/]+) ]]; then
        echo "channel:c/${BASH_REMATCH[1]}"
    elif [[ $input =~ youtube\.com/channel/([^/]+) ]]; then
        echo "channel:channel/${BASH_REMATCH[1]}"
    elif [[ $input =~ ^UC[a-zA-Z0-9_-]{22}$ ]]; then
        echo "channel:channel/$input"
    elif [[ $input =~ ^@[a-zA-Z0-9_-]+$ ]]; then
        echo "channel:$input"
    else
        echo "channel:@$input"  # Assume it's a username
    fi
}

# Function to get channel info (name and ID)
get_channel_info() {
    local input=$1
    local type=$(echo "$input" | cut -d: -f1)
    local value=$(echo "$input" | cut -d: -f2)
    
    if [ "$type" = "channel" ]; then
        local channel_url="https://youtube.com/$value/videos"
        # Get both channel name and channel ID (use /videos endpoint for speed)
        local info=$(yt-dlp --flat-playlist --playlist-items 1 --print "%(channel)s|%(channel_id)s" "$channel_url" 2>/dev/null | head -1)
        if [ -n "$info" ]; then
            local name=$(echo "$info" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
            local id=$(echo "$info" | cut -d'|' -f2)
            echo "${name}_${id}"
        else
            # Fallback
            echo "${value##*/}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g'
        fi
    else
        echo "$value" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g'
    fi
}

# Function to create temporary CSV for Python script
create_temp_csv() {
    local name=$1
    local id=$2
    echo "Channel Name,Channel ID" > "$TEMP_CSV"
    echo "$name,$id" >> "$TEMP_CSV"
}

# Clean up on exit
cleanup() {
    rm -f "$TEMP_CSV"
}
trap cleanup EXIT

# Main function
case "$1" in
    playlists)
        # List all playlists from a channel
        if [ -z "$2" ]; then
            echo "Usage: $0 playlists <channel_url|@username|channel_id>"
            exit 1
        fi
        
        normalized=$(normalize_input "$2")
        type=$(echo "$normalized" | cut -d: -f1)
        value=$(echo "$normalized" | cut -d: -f2)
        
        if [ "$type" != "channel" ]; then
            echo "Error: Please provide a channel URL, @username, or channel ID"
            exit 1
        fi
        
        channel_folder=$(get_channel_info "$normalized")
        channel_url="https://youtube.com/$value"
        
        echo "📋 Fetching playlists for channel: $channel_folder"
        
        # Create channel directory
        channel_dir="$PKM_BASE/$channel_folder"
        mkdir -p "$channel_dir"
        
        # Use yt-dlp directly to list playlists
        output_file="$channel_dir/playlists_$(date +%Y%m%d).csv"
        echo "Playlist ID,Playlist Title" > "$output_file"
        
        # Get playlists using yt-dlp
        yt-dlp --flat-playlist \
            --print "%(id)s,%(title)s" \
            "$channel_url/playlists" 2>/dev/null | \
            grep -v "^NA," >> "$output_file" || true
        
        echo "✅ Playlists saved to: $output_file"
        
        # Show count
        local count=$(tail -n +2 "$output_file" | wc -l)
        echo "📊 Found $count playlists"
        ;;
        
    subsplaylist)
        # Download subtitles for a playlist
        if [ -z "$2" ]; then
            echo "Usage: $0 subsplaylist <playlist_url|playlist_id> [language]"
            exit 1
        fi
        
        lang=${3:-en}
        normalized=$(normalize_input "$2")
        type=$(echo "$normalized" | cut -d: -f1)
        value=$(echo "$normalized" | cut -d: -f2)
        
        if [ "$type" = "playlist" ]; then
            playlist_url="https://youtube.com/playlist?list=$value"
        else
            playlist_url="$2"
        fi
        
        echo "📝 Downloading subtitles for playlist in language: $lang"
        
        # Get channel info from first video in playlist
        first_video=$(yt-dlp --flat-playlist --playlist-items 1 --print "%(channel)s|%(channel_id)s" "$playlist_url" 2>/dev/null | head -1)
        if [ -n "$first_video" ]; then
            channel_name=$(echo "$first_video" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
            channel_id=$(echo "$first_video" | cut -d'|' -f2)
            channel_folder="${channel_name}_${channel_id}"
        else
            channel_folder="unknown_channel"
        fi
        
        # Get playlist title
        playlist_title=$(yt-dlp --flat-playlist --print "%(playlist_title)s" "$playlist_url" 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
        
        # Create directory structure
        playlist_dir="$PKM_BASE/$channel_folder/playlists/$playlist_title"
        mkdir -p "$playlist_dir"
        
        # Download subtitles
        yt-dlp --skip-download \
            --write-sub --write-auto-sub \
            --sub-langs "$lang" \
            --sub-format "vtt/srt/best" \
            -o "$playlist_dir/%(upload_date)s-%(title)s__%(id)s.%(ext)s" \
            --restrict-filenames \
            "$playlist_url"
        
        echo "✅ Subtitles saved to: $playlist_dir"
        ;;
        
    subsall)
        # Download all subtitles from a channel
        if [ -z "$2" ]; then
            echo "Usage: $0 subsall <channel_url|@username|channel_id> [language]"
            exit 1
        fi
        
        lang=${3:-en}
        normalized=$(normalize_input "$2")
        type=$(echo "$normalized" | cut -d: -f1)
        value=$(echo "$normalized" | cut -d: -f2)
        
        if [ "$type" != "channel" ]; then
            echo "Error: Please provide a channel URL, @username, or channel ID"
            exit 1
        fi
        
        channel_folder=$(get_channel_info "$normalized")
        channel_url="https://youtube.com/$value"
        
        echo "📚 Downloading all subtitles from channel: $channel_folder"
        
        # Create channel directory structure
        channel_dir="$PKM_BASE/$channel_folder"
        mkdir -p "$channel_dir/playlists"
        mkdir -p "$channel_dir/video-subtitles"
        
        # First get playlists
        echo "Step 1: Fetching playlists..."
        $0 playlists "$2"
        
        # Read playlists if they exist
        playlist_file="$channel_dir/playlists_$(date +%Y%m%d).csv"
        if [ -f "$playlist_file" ]; then
            echo "Step 2: Downloading subtitles from playlists..."
            tail -n +2 "$playlist_file" | while IFS=, read -r playlist_id playlist_title; do
                playlist_id=$(echo "$playlist_id" | tr -d '"' | xargs)
                playlist_title=$(echo "$playlist_title" | tr -d '"' | xargs | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
                
                echo "  📁 Processing playlist: $playlist_title"
                playlist_dir="$channel_dir/playlists/$playlist_title"
                mkdir -p "$playlist_dir"
                
                yt-dlp --skip-download \
                    --write-sub --write-auto-sub \
                    --sub-langs "$lang" \
                    --sub-format "vtt/srt/best" \
                    -o "$playlist_dir/%(upload_date)s-%(title)s__%(id)s.%(ext)s" \
                    --restrict-filenames \
                    "https://youtube.com/playlist?list=$playlist_id"
            done
        fi
        
        # Get videos not in playlists
        echo "Step 3: Downloading subtitles from videos not in playlists..."
        yt-dlp --skip-download \
            --write-sub --write-auto-sub \
            --sub-langs "$lang" \
            --sub-format "vtt/srt/best" \
            -o "$channel_dir/video-subtitles/%(upload_date)s-%(title)s__%(id)s.%(ext)s" \
            --restrict-filenames \
            --match-filter "playlist_title is None" \
            "$channel_url/videos"
        
        echo "✅ All subtitles saved to: $channel_dir"
        ;;
        
    videosplaylist)
        # List videos in a playlist
        if [ -z "$2" ]; then
            echo "Usage: $0 videosplaylist <playlist_url|playlist_id>"
            exit 1
        fi
        
        normalized=$(normalize_input "$2")
        type=$(echo "$normalized" | cut -d: -f1)
        value=$(echo "$normalized" | cut -d: -f2)
        
        if [ "$type" = "playlist" ]; then
            playlist_url="https://youtube.com/playlist?list=$value"
        else
            playlist_url="$2"
        fi
        
        echo "📹 Listing videos in playlist..."
        
        # Get channel info from first video
        first_video=$(yt-dlp --flat-playlist --playlist-items 1 --print "%(channel)s|%(channel_id)s" "$playlist_url" 2>/dev/null | head -1)
        if [ -n "$first_video" ]; then
            channel_name=$(echo "$first_video" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
            channel_id=$(echo "$first_video" | cut -d'|' -f2)
            channel_folder="${channel_name}_${channel_id}"
        else
            channel_folder="unknown_channel"
        fi
        
        # Get playlist title
        playlist_title=$(yt-dlp --flat-playlist --print "%(playlist_title)s" "$playlist_url" 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
        
        # Create directory
        playlist_dir="$PKM_BASE/$channel_folder/playlists/$playlist_title"
        mkdir -p "$playlist_dir"
        
        output_file="$playlist_dir/videos_list_$(date +%Y%m%d).csv"
        
        # Get video list with metadata
        yt-dlp --flat-playlist \
            --print "%(id)s,%(title)s,%(duration)s,%(upload_date)s,%(view_count)s" \
            "$playlist_url" > "$output_file"
        
        # Add header
        sed -i '' '1i\
Video ID,Title,Duration,Upload Date,View Count' "$output_file"
        
        echo "✅ Video list saved to: $output_file"
        ;;
        
    videosall)
        # List all videos from a channel
        if [ -z "$2" ]; then
            echo "Usage: $0 videosall <channel_url|@username|channel_id>"
            exit 1
        fi
        
        normalized=$(normalize_input "$2")
        type=$(echo "$normalized" | cut -d: -f1)
        value=$(echo "$normalized" | cut -d: -f2)
        
        if [ "$type" != "channel" ]; then
            echo "Error: Please provide a channel URL, @username, or channel ID"
            exit 1
        fi
        
        channel_folder=$(get_channel_info "$normalized")
        channel_url="https://youtube.com/$value"
        
        echo "🎬 Listing all videos from channel: $channel_folder"
        
        # Create channel directory
        channel_dir="$PKM_BASE/$channel_folder"
        mkdir -p "$channel_dir"
        
        output_file="$channel_dir/all_videos_$(date +%Y%m%d).csv"
        
        # Get comprehensive video list
        yt-dlp --flat-playlist \
            --print "%(id)s,%(title)s,%(duration)s,%(upload_date)s,%(view_count)s,%(playlist_title)s,%(playlist_id)s" \
            "$channel_url/videos" > "$output_file"
        
        # Add header
        sed -i '' '1i\
Video ID,Title,Duration,Upload Date,View Count,Playlist Title,Playlist ID' "$output_file"
        
        echo "✅ Video list saved to: $output_file"
        ;;
        
    downloadmin)
        # Minimal video download for transcription
        if [ -z "$2" ]; then
            echo "Usage: $0 downloadmin <video_url|video_id> [quality]"
            echo "Quality options: 144p, 240p, 360p, 480p (default), 720p"
            exit 1
        fi
        
        quality=${3:-480p}
        normalized=$(normalize_input "$2")
        type=$(echo "$normalized" | cut -d: -f1)
        value=$(echo "$normalized" | cut -d: -f2)
        
        if [ "$type" = "video" ]; then
            video_url="https://youtube.com/watch?v=$value"
        else
            video_url="$2"
        fi
        
        echo "⬇️ Downloading video in $quality for transcription..."
        
        # Get video info first
        video_info=$(yt-dlp --print "%(title)s|%(upload_date)s|%(channel)s|%(channel_id)s|%(id)s" "$video_url")
        IFS='|' read -r title upload_date channel channel_id video_id <<< "$video_info"
        
        # Create channel folder
        safe_channel=$(echo "$channel" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
        channel_folder="${safe_channel}_${channel_id}"
        downloads_dir="$PKM_BASE/$channel_folder/downloads"
        mkdir -p "$downloads_dir"
        
        # Sanitize for filename
        safe_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g' | cut -c1-50)
        
        output_file="$downloads_dir/${upload_date}-${safe_title}__${video_id}.mp4"
        
        # Download with specific quality
        yt-dlp -f "bestvideo[height<=${quality%p}]+bestaudio/best[height<=${quality%p}]" \
            --merge-output-format mp4 \
            -o "$output_file" \
            "$video_url"
        
        echo "✅ Video saved to: $output_file"
        echo "💡 Tip: Use SuperWhisper or 'transcribe' alias to extract text"
        ;;
        
    *)
        echo "🎬 YouTube Tools V2 - Available commands:"
        echo ""
        echo "  $0 playlists <channel>      - List all playlists from channel"
        echo "  $0 subsplaylist <playlist>  - Download subtitles for playlist"
        echo "  $0 subsall <channel>        - Download all subtitles (organized by playlist)"
        echo "  $0 videosplaylist <playlist>- List videos in playlist"
        echo "  $0 videosall <channel>      - List all videos from channel"
        echo "  $0 downloadmin <video>      - Minimal download for transcription"
        echo ""
        echo "📁 Folder structure:"
        echo "  $PKM_BASE/"
        echo "  └── {channel_name}_{channel_id}/"
        echo "      ├── playlists/"
        echo "      │   └── {playlist_name}/"
        echo "      │       ├── *.vtt (subtitles)"
        echo "      │       └── videos_list_YYYYMMDD.csv"
        echo "      ├── video-subtitles/"
        echo "      │   └── *.vtt (videos not in playlists)"
        echo "      ├── downloads/"
        echo "      │   └── *.mp4"
        echo "      ├── playlists_YYYYMMDD.csv"
        echo "      └── all_videos_YYYYMMDD.csv"
        echo ""
        echo "Input formats supported:"
        echo "  - Channel: @username, UCxxxxxx, youtube.com/@username"
        echo "  - Playlist: PLxxxxxx, youtube.com/playlist?list=PLxxxxxx"
        echo "  - Video: xxxxxxxxxxx, youtube.com/watch?v=xxxxxxxxxxx"
        ;;
esac