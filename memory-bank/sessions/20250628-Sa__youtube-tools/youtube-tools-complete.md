# 🎬 YouTube Tools - Complete Implementation

## ✅ What Was Done

### 1. Fixed `ytsubs` Command
- **Problem**: Empty subtitle files due to broken npm package
- **Solution**: Rewrote using YouTube's internal API
- **Location**: `/Users/user/__Repositories/youtube-scrapping/youtube-captions-scraper/yt-subs.js`
- **Result**: Successfully downloads subtitles with proper content

### 2. Created Comprehensive YouTube Tools
- **Main Script**: `/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/youtube/yt-tools.sh`
- **Aliases File**: `/Users/user/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/aliases/tool-youtube.zsh`
- **Integration**: Added to `llms.zsh` for automatic loading

### 3. Implemented All Requested Commands

#### Core Aliases
```bash
ytsubs <video>              # Download subtitles for single video
ytplaylists <channel>       # List all playlists from channel
ytsubsplaylist <playlist>   # Download subtitles for playlist
ytsubsall <channel>         # Download all channel subtitles (organized)
ytvideosplaylist <playlist> # List videos in playlist
ytvideosall <channel>       # List all videos from channel
ytdownloadmin <video>       # Minimal download for transcription
```

#### Bonus Utilities
```bash
ytaudio <video>             # Audio-only download (MP3)
ytsearch <pattern>          # Search in downloaded subtitles
ytchannelinfo <video>       # Get channel info from video
ytsubsavailable <video>     # Check available subtitle languages
ytvideometa <video>         # Get video metadata
ytlatestrans <channel>      # Get transcript of latest video
ytbatch <file> <action>     # Process multiple channels
ythelp                      # Show help information
```

## 📁 Output Organization

All outputs are saved to PKM structure:
```
/Users/user/____Sandruk/___PKM/_Outputs_External/
├── subtitles-youtube/
│   ├── channels/
│   │   └── {channel_name}/
│   │       ├── {playlist_name}/
│   │       └── no-playlist/
│   └── playlists/
│       └── {playlist_id}/
├── youtube-playlists/
│   └── {channel_name}_playlists_{date}.csv
├── youtube-videos/
│   ├── {channel_name}_all_videos_{date}.csv
│   └── playlist_{id}_videos_{date}.csv
└── youtube-downloads/
    └── {date}-{title}__by-{channel}__{id}.mp4
```

## 🎯 Usage Examples

### Download subtitles for a video
```bash
ytsubs "https://www.youtube.com/watch?v=dQw4w9WgXcQ" en
ytsubs dQw4w9WgXcQ ru  # Just the ID works too
```

### Get all playlists from a channel
```bash
ytplaylists "@mkbhd"
ytplaylists "https://youtube.com/@mkbhd"
ytplaylists UCBJycsmduvYEL83R_U4JriQ  # Channel ID
```

### Download all subtitles from a channel
```bash
ytsubsall "@veritasium" en
# Creates organized folder structure with playlists
```

### Download video for transcription
```bash
ytdownloadmin "https://www.youtube.com/watch?v=xxx" 480p
# Then use: transcribe or superwhisper
```

### Batch process channels
```bash
# Create a file with channel list
echo "@mkbhd
@veritasium
@3blue1brown" > channels.txt

# Process all
ytbatch channels.txt subsall
```

## 🔧 Technical Details

### Dependencies
- yt-dlp (installed via pyenv)
- Node.js (for ytsubs)
- Python (for youtube_channel_analyzer integration)
- ripgrep (for ytsearch)

### Input Format Support
- Video: `xxxxxxxxxxx`, `youtube.com/watch?v=xxx`, `youtu.be/xxx`
- Playlist: `PLxxxxxx`, `youtube.com/playlist?list=PLxxxx`
- Channel: `@username`, `UCxxxxx`, `youtube.com/@username`, `youtube.com/c/custom`

### Smart Features
- Automatic input type detection
- Russian transliteration for filenames
- Fallback language selection
- Progress tracking
- Error handling

## 🐛 Troubleshooting

### If aliases don't work
```bash
source ~/.zshrc
# Or manually source:
source ~/____Sandruk/___PARA/__Areas/_5_CAREER/DEVOPS/automations/zsh/aliases/tool-youtube.zsh
```

### If Python script fails
Check youtube_channel_analyzer environment:
```bash
cd /Users/user/__Repositories/youtube-scrapping/youtube_channel_analyzer
poetry install
```

### If yt-dlp is not found
```bash
which yt-dlp  # Should show pyenv path
# If not: pip install yt-dlp
```

## 🚀 Future Enhancements

1. **Auto-transcription pipeline**
   - Download → SuperWhisper → Entity extraction → PKM

2. **Channel monitoring**
   - Cron job to check for new videos
   - Auto-download new subtitles

3. **Content analysis**
   - Topic extraction from subtitles
   - Knowledge graph building

4. **Integration with your Digital Twin**
   - Feed YouTube content to context engine
   - Build STAR cases from tech videos