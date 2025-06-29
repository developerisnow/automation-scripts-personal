#!/usr/bin/env node

// YouTube Subtitle Fetcher - Fixed Version
// Uses YouTube's internal API directly instead of broken npm packages

const https = require('https');
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);

if (args.length === 0) {
    console.log('Usage: yt-subs <videoURL|videoID> [language]');
    console.log('Example: yt-subs ZbHpinVP6mk ru');
    console.log('Example: yt-subs https://www.youtube.com/watch?v=kqB_xML1SfA en');
    process.exit(1);
}

let input = args[0];
const lang = args[1] || 'en';

// Output directory
const OUTPUT_DIR = '/Users/user/____Sandruk/___PKM/_Outputs_External/subtitles-youtube';

// Function to extract videoID if a full URL is provided
function extractVideoID(input) {
    const urlPattern = /(?:youtube\.com\/.*(?:v=|\/embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/;
    const match = input.match(urlPattern);
    return match ? match[1] : input;
}

const videoID = extractVideoID(input);

// Function to transliterate Russian to Latin
function transliterateRussian(str) {
    const ru2en = {
        'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'zh',
        'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o',
        'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'ts',
        'ч': 'ch', 'ш': 'sh', 'щ': 'sch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu',
        'я': 'ya', 'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
        'Ж': 'Zh', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M', 'Н': 'N',
        'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U', 'Ф': 'F', 'Х': 'H',
        'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Sch', 'Ъ': '', 'Ы': 'Y', 'Ь': '', 'Э': 'E',
        'Ю': 'Yu', 'Я': 'Ya'
    };
    
    return str.split('').map(char => ru2en[char] || char).join('');
}

// Function to format string for filename
function formatString(str, lang) {
    if (lang === 'ru') {
        str = transliterateRussian(str);
    }
    
    return str
        .toLowerCase()
        .replace(/[\s\.,]+/g, '-')
        .replace(/[^a-z0-9\-]/g, '')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, '');
}

// Function to format channel name
function formatChannelName(str, lang) {
    const formattedStr = formatString(str, lang);
    return formattedStr.replace(/-/g, '_');
}

// Function to format date
function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

// Function to format time from seconds
function formatTime(seconds) {
    if (isNaN(seconds)) return '00:00:00,000';
    const date = new Date(seconds * 1000);
    const hh = date.getUTCHours().toString().padStart(2, '0');
    const mm = date.getUTCMinutes().toString().padStart(2, '0');
    const ss = date.getUTCSeconds().toString().padStart(2, '0');
    const ms = date.getUTCMilliseconds().toString().padStart(3, '0');
    return `${hh}:${mm}:${ss},${ms}`;
}

// Function to parse XML captions
function parseXMLCaptions(xml) {
    const captions = [];
    const textRegex = /<text start="([^"]+)" dur="([^"]+)"[^>]*>([^<]+)<\/text>/g;
    let match;
    
    while ((match = textRegex.exec(xml)) !== null) {
        const start = parseFloat(match[1]);
        const duration = parseFloat(match[2]);
        let text = match[3];
        
        // Decode HTML entities
        text = text
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/&#(\d+);/g, (match, code) => String.fromCharCode(code));
        
        captions.push({
            start: start,
            dur: duration,
            text: text.trim()
        });
    }
    
    return captions;
}

// Function to make HTTPS request
function httpsRequest(options, postData = null) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(data);
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

// Main function to fetch subtitles
async function fetchSubtitles() {
    try {
        console.log(`Fetching subtitles for video ID: ${videoID} in language: ${lang}`);
        
        // First, get video info from YouTube's internal API
        const apiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8'; // YouTube's web player API key
        const postData = JSON.stringify({
            context: {
                client: {
                    clientName: 'WEB',
                    clientVersion: '2.20240628.00.00'
                }
            },
            videoId: videoID
        });
        
        const options = {
            hostname: 'www.youtube.com',
            path: '/youtubei/v1/player?key=' + apiKey,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': postData.length,
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            }
        };
        
        const response = await httpsRequest(options, postData);
        const data = JSON.parse(response);
        
        if (!data.videoDetails) {
            throw new Error('Failed to get video details');
        }
        
        // Extract video info
        const title = data.videoDetails.title || 'video';
        const channelName = data.videoDetails.author || 'Unknown';
        const publishDate = new Date(data.microformat?.playerMicroformatRenderer?.publishDate || new Date());
        
        // Format filename
        const formattedTitle = formatString(title, lang);
        const formattedChannelName = formatChannelName(channelName, lang);
        const formattedPublishDate = formatDate(publishDate);
        
        // Find caption track for requested language
        const captionTracks = data.captions?.playerCaptionsTracklistRenderer?.captionTracks || [];
        let captionTrack = captionTracks.find(track => 
            track.languageCode === lang || 
            track.languageCode.startsWith(lang + '-')
        );
        
        // If exact language not found, try auto-generated
        if (!captionTrack) {
            captionTrack = captionTracks.find(track => 
                track.vssId && track.vssId.includes('.' + lang)
            );
        }
        
        // If still not found, use first available
        if (!captionTrack && captionTracks.length > 0) {
            captionTrack = captionTracks[0];
            console.log(`Language '${lang}' not found, using: ${captionTrack.languageCode}`);
        }
        
        if (!captionTrack) {
            throw new Error('No captions available for this video');
        }
        
        // Fetch the caption XML
        const captionUrl = new URL(captionTrack.baseUrl);
        const captionOptions = {
            hostname: captionUrl.hostname,
            path: captionUrl.pathname + captionUrl.search,
            method: 'GET',
            headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            }
        };
        
        const captionXML = await httpsRequest(captionOptions);
        const captions = parseXMLCaptions(captionXML);
        
        if (captions.length === 0) {
            throw new Error('No captions found in the XML');
        }
        
        // Format output
        const output = captions.map(caption => {
            const startTime = formatTime(caption.start);
            return `[${startTime}] ${caption.text}`;
        }).join('\n');
        
        // Save to file
        const outputFile = path.join(OUTPUT_DIR, 
            `${formattedPublishDate}-subs-${formattedTitle}__by-${formattedChannelName}.md`);
        
        // Ensure output directory exists
        if (!fs.existsSync(OUTPUT_DIR)) {
            fs.mkdirSync(OUTPUT_DIR, { recursive: true });
        }
        
        fs.writeFileSync(outputFile, output);
        
        console.log(`Subtitles saved to ${path.basename(outputFile)}`);
        console.log(`Video published on: ${publishDate.toISOString()}`);
        console.log(`Channel: ${channelName}`);
        console.log(`Total captions: ${captions.length}`);
        
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

// Run the main function
fetchSubtitles();