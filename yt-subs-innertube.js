#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const slugify = require('slugify');

const args = process.argv.slice(2);

if (args.length === 0) {
    console.log('Usage: yt-subs-innertube <videoURL|videoID> [language] [outputPath]');
    console.log('Example: yt-subs-innertube ZbHpinVP6mk ru /path/to/save/');
    console.log('\nNote: This uses YouTube\'s internal API and may require updates if YouTube changes their system.');
    process.exit(1);
}

let input = args[0];
const lang = args[1] || 'en';
const outputPath = args[2] || '/Users/user/____Sandruk/___PKM/_Outputs_External/subtitles-youtube/';

// Extract videoID from URL
function extractVideoID(input) {
    const urlPattern = /(?:youtube\.com\/.*(?:v=|\/embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/;
    const match = input.match(urlPattern);
    return match ? match[1] : input;
}

const videoID = extractVideoID(input);

// Format functions
function formatString(str, lang) {
    if (lang === 'ru') {
        return slugify(str, { lower: true, strict: true, locale: 'ru' });
    } else {
        return str
            .toLowerCase()
            .replace(/[\s\.,]+/g, '-')
            .replace(/[^a-z0-9\-]/g, '')
            .replace(/-+/g, '-')
            .replace(/^-|-$/g, '');
    }
}

function formatChannelName(str, lang) {
    const formattedStr = formatString(str, lang);
    return formattedStr.replace(/-/g, '_');
}

function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

function formatTime(ms) {
    const totalSeconds = Math.floor(ms / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const milliseconds = ms % 1000;
    
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')},${milliseconds.toString().padStart(3, '0')}`;
}

// Make HTTPS request with proper headers
function httpsRequest(options, postData) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(new Error('Invalid JSON response'));
                    }
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });
        
        req.on('error', reject);
        
        if (postData) {
            req.write(postData);
        }
        
        req.end();
    });
}

// Get video details using Innertube API
async function getVideoDetails(videoId) {
    const postData = JSON.stringify({
        videoId: videoId,
        context: {
            client: {
                clientName: 'WEB',
                clientVersion: '2.20250101.00.00',
                hl: 'en',
                gl: 'US',
                timeZone: 'UTC',
                utcOffsetMinutes: 0
            }
        }
    });
    
    const options = {
        hostname: 'www.youtube.com',
        path: '/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData),
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Origin': 'https://www.youtube.com',
            'Referer': `https://www.youtube.com/watch?v=${videoId}`
        }
    };
    
    return httpsRequest(options, postData);
}

// Get transcript using Innertube API
async function getTranscript(videoId, lang) {
    // First, get video details to find caption tracks
    const videoDetails = await getVideoDetails(videoId);
    
    if (!videoDetails.captions || !videoDetails.captions.playerCaptionsTracklistRenderer) {
        throw new Error('No captions available for this video');
    }
    
    const captionTracks = videoDetails.captions.playerCaptionsTracklistRenderer.captionTracks || [];
    
    // Find the requested language track or fallback to first available
    let selectedTrack = captionTracks.find(track => track.languageCode === lang);
    
    if (!selectedTrack && captionTracks.length > 0) {
        console.log(`Language '${lang}' not found. Available languages:`);
        captionTracks.forEach(track => {
            console.log(`  - ${track.languageCode}: ${track.name.simpleText || track.name.runs[0].text}`);
        });
        selectedTrack = captionTracks[0];
        console.log(`\nUsing: ${selectedTrack.languageCode}`);
    }
    
    if (!selectedTrack) {
        throw new Error('No caption tracks found');
    }
    
    // Fetch the transcript
    const transcriptUrl = new URL(selectedTrack.baseUrl);
    
    const options = {
        hostname: transcriptUrl.hostname,
        path: transcriptUrl.pathname + transcriptUrl.search,
        method: 'GET',
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/xml',
            'Accept-Language': 'en-US,en;q=0.9'
        }
    };
    
    return new Promise((resolve, reject) => {
        https.get(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    // Parse XML response
                    const captions = [];
                    const textRegex = /<text start="([^"]+)" dur="([^"]+)"[^>]*>([^<]*)<\/text>/g;
                    let match;
                    
                    while ((match = textRegex.exec(data)) !== null) {
                        let text = match[3];
                        
                        // Decode HTML entities
                        text = text.replace(/&amp;/g, '&')
                                   .replace(/&lt;/g, '<')
                                   .replace(/&gt;/g, '>')
                                   .replace(/&quot;/g, '"')
                                   .replace(/&#39;/g, "'")
                                   .replace(/&#x27;/g, "'")
                                   .replace(/&#x2F;/g, '/')
                                   .replace(/&#x5C;/g, '\\')
                                   .replace(/&#x60;/g, '`')
                                   .replace(/&#(\d+);/g, (match, dec) => String.fromCharCode(dec));
                        
                        captions.push({
                            start: parseFloat(match[1]) * 1000, // Convert to milliseconds
                            duration: parseFloat(match[2]) * 1000,
                            text: text.trim()
                        });
                    }
                    
                    resolve({
                        captions,
                        videoTitle: videoDetails.videoDetails?.title || 'Unknown Video',
                        channelName: videoDetails.videoDetails?.author || 'Unknown Channel'
                    });
                } else {
                    reject(new Error(`Failed to fetch transcript: HTTP ${res.statusCode}`));
                }
            });
        }).on('error', reject);
    });
}

// Main function
(async function() {
    try {
        console.log(`Fetching transcript for video: ${videoID}`);
        console.log(`Requested language: ${lang}`);
        
        const result = await getTranscript(videoID, lang);
        
        console.log(`\nVideo: ${result.videoTitle}`);
        console.log(`Channel: ${result.channelName}`);
        console.log(`Found ${result.captions.length} caption entries`);
        
        if (result.captions.length === 0) {
            console.error('No captions found!');
            process.exit(1);
        }
        
        // Format filename
        const formattedTitle = formatString(result.videoTitle, lang);
        const formattedChannelName = formatChannelName(result.channelName, lang);
        const today = formatDate(new Date());
        
        const outputFile = path.join(
            outputPath,
            `${today}-subs-${formattedTitle}__by-${formattedChannelName}.md`
        );
        
        // Format output
        const output = result.captions.map(caption => {
            const time = formatTime(caption.start);
            return `[${time}] ${caption.text}`;
        }).join('\n');
        
        // Ensure output directory exists
        if (!fs.existsSync(outputPath)) {
            fs.mkdirSync(outputPath, { recursive: true });
        }
        
        // Write to file
        fs.writeFileSync(outputFile, output);
        console.log(`\nSubtitles saved to: ${outputFile}`);
        
    } catch (err) {
        console.error('\nError:', err.message);
        console.error('\nPossible issues:');
        console.error('1. Video has no captions/subtitles');
        console.error('2. Video is private or age-restricted');
        console.error('3. YouTube API has changed');
        console.error('4. Network connectivity issues');
        console.error('\nTry checking if the video has captions on YouTube directly.');
    }
})();