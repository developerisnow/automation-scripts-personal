#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const slugify = require('slugify');
const https = require('https');

const args = process.argv.slice(2);

if (args.length === 0) {
    console.log('Usage: yt-subs-fixed <videoURL|videoID> [language] [outputPath]');
    console.log('Example: yt-subs-fixed ZbHpinVP6mk ru /path/to/save/');
    process.exit(1);
}

let input = args[0];
const lang = args[1] || 'en';
const outputPath = args[2] || '/Users/user/____Sandruk/___PKM/_Outputs_External/subtitles-youtube/';

// Function to extract videoID if a full URL is provided
function extractVideoID(input) {
    const urlPattern = /(?:youtube\.com\/.*(?:v=|\/embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/;
    const match = input.match(urlPattern);
    return match ? match[1] : input;
}

const videoID = extractVideoID(input);

// Function to format strings
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

// Function to format time
function formatTime(seconds) {
    if (isNaN(seconds)) return '00:00:00,000';
    const date = new Date(seconds * 1000);
    const hh = date.getUTCHours().toString().padStart(2, '0');
    const mm = date.getUTCMinutes().toString().padStart(2, '0');
    const ss = date.getUTCSeconds().toString().padStart(2, '0');
    const ms = date.getUTCMilliseconds().toString().padStart(3, '0');
    return `${hh}:${mm}:${ss},${ms}`;
}

// Function to fetch video info using YouTube's oEmbed API
async function getVideoInfo(videoID) {
    return new Promise((resolve, reject) => {
        const url = `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoID}&format=json`;
        
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const info = JSON.parse(data);
                    resolve({
                        title: info.title || 'Unknown Video',
                        author: info.author_name || 'Unknown Channel'
                    });
                } catch (err) {
                    reject(err);
                }
            });
        }).on('error', reject);
    });
}

// Function to parse XML captions
function parseXMLCaptions(xml) {
    const captions = [];
    const textRegex = /<text start="([^"]+)" dur="([^"]+)"[^>]*>([^<]*)<\/text>/g;
    let match;
    
    while ((match = textRegex.exec(xml)) !== null) {
        const start = parseFloat(match[1]);
        const duration = parseFloat(match[2]);
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
                   .replace(/&#x60;/g, '`');
        
        captions.push({
            start: start,
            duration: duration,
            text: text.trim()
        });
    }
    
    return captions;
}

// Function to fetch captions directly
async function fetchCaptions(videoID, lang) {
    return new Promise((resolve, reject) => {
        // Try multiple caption URLs
        const urls = [
            `https://www.youtube.com/api/timedtext?v=${videoID}&lang=${lang}&fmt=srv1`,
            `https://www.youtube.com/api/timedtext?v=${videoID}&lang=${lang}&fmt=srv3`,
            `https://www.youtube.com/api/timedtext?v=${videoID}&lang=${lang}`,
            // Try auto-generated captions
            `https://www.youtube.com/api/timedtext?v=${videoID}&lang=${lang}&kind=asr`,
            // Try without language to get default
            `https://www.youtube.com/api/timedtext?v=${videoID}`
        ];
        
        let attemptIndex = 0;
        
        function tryNextUrl() {
            if (attemptIndex >= urls.length) {
                reject(new Error('No captions found after trying all URLs'));
                return;
            }
            
            const url = urls[attemptIndex++];
            console.log(`Trying: ${url}`);
            
            https.get(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    'Accept-Language': 'en-US,en;q=0.9',
                    'Cache-Control': 'no-cache',
                    'Pragma': 'no-cache'
                }
            }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    if (res.statusCode === 200 && data && data.includes('<transcript>')) {
                        const captions = parseXMLCaptions(data);
                        if (captions.length > 0) {
                            resolve(captions);
                        } else {
                            tryNextUrl();
                        }
                    } else {
                        tryNextUrl();
                    }
                });
            }).on('error', (err) => {
                console.error(`Error fetching from ${url}:`, err.message);
                tryNextUrl();
            });
        }
        
        tryNextUrl();
    });
}

// Main function
(async function() {
    try {
        console.log(`Fetching info for video: ${videoID}`);
        
        // Get video info
        const videoInfo = await getVideoInfo(videoID);
        console.log(`Title: ${videoInfo.title}`);
        console.log(`Channel: ${videoInfo.author}`);
        
        // Format the filename
        const formattedTitle = formatString(videoInfo.title, lang);
        const formattedChannelName = formatChannelName(videoInfo.author, lang);
        const today = formatDate(new Date());
        
        const outputFile = path.join(
            outputPath,
            `${today}-subs-${formattedTitle}__by-${formattedChannelName}.md`
        );
        
        // Fetch captions
        console.log(`\nFetching ${lang} captions...`);
        const captions = await fetchCaptions(videoID, lang);
        
        console.log(`Found ${captions.length} caption entries`);
        
        // Format output
        const output = captions.map(caption => {
            const startTime = formatTime(caption.start);
            return `[${startTime}] ${caption.text}`;
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
        console.error('\nThis might be because:');
        console.error('1. The video has no captions available');
        console.error('2. YouTube is blocking automated requests');
        console.error('3. The video is private or age-restricted');
        console.error('\nTry using a different video or checking if captions are available on YouTube directly.');
    }
})();