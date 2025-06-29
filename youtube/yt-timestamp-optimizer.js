#!/usr/bin/env node

/**
 * YouTube Subtitle Timestamp Optimizer
 * Reduces context usage by 30-40% while preserving navigation
 * 
 * Features:
 * - Configurable chunk intervals (default: 2 minutes)
 * - Removes excessive line breaks
 * - Preserves timestamps at chunk boundaries
 * - Simple format: [HH:MM:SS] text continues...
 */

const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length < 1) {
    console.log(`
Usage: yt-timestamp-optimizer <input_file> [options]

Options:
  --interval <minutes>   Timestamp interval in minutes (default: 2)
  --output <file>       Output file (default: adds .optimized before extension)
  --format <type>       Input format: vtt, srt, or md (default: auto-detect)
  
Examples:
  yt-timestamp-optimizer subtitle.vtt --interval 5
  yt-timestamp-optimizer subtitle.md --interval 2 --output optimized.md
`);
    process.exit(1);
}

const inputFile = args[0];
const options = {
    interval: 2, // minutes
    output: null,
    format: null
};

// Parse options
for (let i = 1; i < args.length; i += 2) {
    const flag = args[i];
    const value = args[i + 1];
    
    switch (flag) {
        case '--interval':
            options.interval = parseFloat(value);
            break;
        case '--output':
            options.output = value;
            break;
        case '--format':
            options.format = value;
            break;
    }
}

// Auto-detect format if not specified
if (!options.format) {
    const ext = path.extname(inputFile).toLowerCase();
    if (ext === '.vtt') options.format = 'vtt';
    else if (ext === '.srt') options.format = 'srt';
    else if (ext === '.md') options.format = 'md';
    else {
        console.error('Could not detect format. Please specify with --format');
        process.exit(1);
    }
}

// Generate output filename if not specified
if (!options.output) {
    const dir = path.dirname(inputFile);
    const basename = path.basename(inputFile, path.extname(inputFile));
    const ext = path.extname(inputFile);
    // Use _grouped{interval}m naming convention
    const intervalStr = options.interval < 1 ? `${Math.round(options.interval * 60)}s` : `${options.interval}m`;
    options.output = path.join(dir, `${basename}_grouped${intervalStr}${ext}`);
}

// Convert time to seconds
function timeToSeconds(timeStr) {
    // Handle different time formats
    // HH:MM:SS,mmm or HH:MM:SS.mmm
    timeStr = timeStr.replace(',', '.');
    
    const parts = timeStr.split(':');
    if (parts.length === 3) {
        const hours = parseInt(parts[0], 10);
        const minutes = parseInt(parts[1], 10);
        const seconds = parseFloat(parts[2]);
        return hours * 3600 + minutes * 60 + seconds;
    } else if (parts.length === 2) {
        const minutes = parseInt(parts[0], 10);
        const seconds = parseFloat(parts[1]);
        return minutes * 60 + seconds;
    }
    return parseFloat(timeStr);
}

// Convert seconds to timestamp
function secondsToTimestamp(seconds, includeMs = false) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (includeMs) {
        const ms = Math.floor((seconds % 1) * 1000);
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
    }
    
    return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

// Parse VTT format
function parseVTT(content) {
    const lines = content.split('\n');
    const captions = [];
    let currentCaption = null;
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        
        // Skip WEBVTT header and empty lines
        if (line === 'WEBVTT' || line === '') continue;
        
        // Time range line
        if (line.includes('-->')) {
            const [start, end] = line.split('-->').map(t => t.trim());
            currentCaption = {
                start: timeToSeconds(start.split(' ')[0]), // Remove position info
                end: timeToSeconds(end.split(' ')[0]),
                text: ''
            };
        } else if (currentCaption && line) {
            // Text line
            if (currentCaption.text) currentCaption.text += ' ';
            currentCaption.text += line;
        } else if (currentCaption && line === '' && currentCaption.text) {
            // End of caption
            captions.push(currentCaption);
            currentCaption = null;
        }
    }
    
    // Don't forget last caption
    if (currentCaption && currentCaption.text) {
        captions.push(currentCaption);
    }
    
    return captions;
}

// Parse SRT format
function parseSRT(content) {
    const lines = content.split('\n');
    const captions = [];
    let currentCaption = null;
    let expectingTime = false;
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        
        // Caption number
        if (/^\d+$/.test(line)) {
            expectingTime = true;
            continue;
        }
        
        // Time range
        if (expectingTime && line.includes('-->')) {
            const [start, end] = line.split('-->').map(t => t.trim());
            currentCaption = {
                start: timeToSeconds(start),
                end: timeToSeconds(end),
                text: ''
            };
            expectingTime = false;
        } else if (currentCaption && line) {
            // Text line
            if (currentCaption.text) currentCaption.text += ' ';
            currentCaption.text += line;
        } else if (currentCaption && line === '' && currentCaption.text) {
            // End of caption
            captions.push(currentCaption);
            currentCaption = null;
        }
    }
    
    // Don't forget last caption
    if (currentCaption && currentCaption.text) {
        captions.push(currentCaption);
    }
    
    return captions;
}

// Parse our MD format (from ytsubs)
function parseMD(content) {
    const lines = content.split('\n');
    const captions = [];
    
    for (const line of lines) {
        const match = line.match(/^\[(\d{2}:\d{2}:\d{2}),\d{3}\]\s*(.+)$/);
        if (match) {
            const timeStr = match[1];
            const text = match[2];
            const seconds = timeToSeconds(timeStr);
            
            captions.push({
                start: seconds,
                end: seconds + 2, // Approximate
                text: text
            });
        }
    }
    
    return captions;
}

// Optimize captions with configurable intervals
function optimizeCaptions(captions, intervalMinutes) {
    const intervalSeconds = intervalMinutes * 60;
    const optimized = [];
    let currentChunk = {
        start: 0,
        text: ''
    };
    let nextTimestamp = intervalSeconds;
    
    for (const caption of captions) {
        // Check if we've crossed a timestamp boundary
        if (caption.start >= nextTimestamp) {
            // Save current chunk
            if (currentChunk.text) {
                optimized.push({
                    timestamp: secondsToTimestamp(currentChunk.start),
                    text: currentChunk.text.trim()
                });
            }
            
            // Start new chunk
            currentChunk = {
                start: Math.floor(caption.start / intervalSeconds) * intervalSeconds,
                text: caption.text
            };
            nextTimestamp = currentChunk.start + intervalSeconds;
        } else {
            // Add to current chunk
            if (currentChunk.text) currentChunk.text += ' ';
            currentChunk.text += caption.text;
        }
    }
    
    // Don't forget last chunk
    if (currentChunk.text) {
        optimized.push({
            timestamp: secondsToTimestamp(currentChunk.start),
            text: currentChunk.text.trim()
        });
    }
    
    return optimized;
}

// Main processing
try {
    const content = fs.readFileSync(inputFile, 'utf8');
    let captions;
    
    // Parse based on format
    switch (options.format) {
        case 'vtt':
            captions = parseVTT(content);
            break;
        case 'srt':
            captions = parseSRT(content);
            break;
        case 'md':
            captions = parseMD(content);
            break;
    }
    
    console.log(`📄 Parsed ${captions.length} caption entries`);
    
    // Optimize
    const optimized = optimizeCaptions(captions, options.interval);
    console.log(`⚡ Optimized to ${optimized.length} chunks (${options.interval} min intervals)`);
    
    // Calculate savings
    const originalLines = captions.length;
    const optimizedLines = optimized.length;
    const savings = Math.round((1 - optimizedLines / originalLines) * 100);
    console.log(`📉 Context reduction: ${savings}%`);
    
    // Write output
    let output = '';
    for (const chunk of optimized) {
        output += `[${chunk.timestamp}] ${chunk.text}\n\n`;
    }
    
    fs.writeFileSync(options.output, output.trim());
    console.log(`✅ Saved to: ${options.output}`);
    
    // Show sample
    console.log('\n📝 Sample output:');
    console.log(optimized.slice(0, 3).map(c => `[${c.timestamp}] ${c.text.substring(0, 80)}...`).join('\n'));
    
} catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
}