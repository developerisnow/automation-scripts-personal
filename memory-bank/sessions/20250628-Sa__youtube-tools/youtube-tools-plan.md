# YouTube Tools Implementation Plan

## 📋 TODO Checklist

### Core Components
- [ ] Create tool-youtube.zsh with all aliases
- [ ] Create unified yt-tools.sh script for complex operations
- [ ] Test each alias with real YouTube content
- [ ] Integrate with existing PKM output structure
- [ ] Ensure Python environment compatibility

### Aliases to Implement
- [x] `ytsubs` - Fixed, downloads subtitles for single video
- [ ] `ytplaylists` - List all playlists from channel
- [ ] `ytsubsplaylist` - Download subtitles for entire playlist
- [ ] `ytsubsall` - Download all subtitles from channel (organized by playlist)
- [ ] `ytvideosplaylist` - List videos in specific playlist
- [ ] `ytvideosall` - List all videos from channel
- [ ] `ytdownloadmin` - Minimal video download for transcription

### Technical Details
- Use existing youtube_channel_analyzer infrastructure
- Output to PKM structure: `/Users/user/____Sandruk/___PKM/_Outputs_External/`
- Support multiple input formats:
  - Channel ID: `UCxxxxxxxxxxxxxxxxxxxxxx`
  - Username: `@username`
  - Custom URL: `https://youtube.com/c/customname`
  - Direct URLs: `https://youtube.com/watch?v=xxx`

### Dependencies
- yt-dlp (installed via pyenv)
- Python environment from youtube_channel_analyzer
- Existing scripts to leverage

## Implementation Strategy

1. **Leverage Existing Code**
   - Use main.py from youtube_channel_analyzer
   - Adapt alias-runner-yt-dlp.sh patterns
   
2. **Create Unified Interface**
   - Single script handling all operations
   - Smart detection of input type
   - Consistent output organization

3. **PKM Integration**
   - Subtitles → `/subtitles-youtube/`
   - Playlists → `/youtube-playlists/`
   - Video lists → `/youtube-videos/`
   - Downloads → `/youtube-downloads/`