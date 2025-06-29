#!/usr/bin/env node

const { getSubtitles } = require('youtube-captions-scraper');
const ytdl = require('ytdl-core');

// Test video IDs
const testVideos = [
    { id: 'ZbHpinVP6mk', lang: 'ru', name: 'Russian video' },
    { id: 'kqB_xML1SfA', lang: 'en', name: 'English video' }
];

async function testSubtitles() {
    for (const video of testVideos) {
        console.log(`\n=== Testing ${video.name} (${video.id}) ===`);
        
        try {
            // Test ytdl-core first
            console.log('1. Testing ytdl-core...');
            const info = await ytdl.getBasicInfo(video.id);
            console.log(`   ✓ Title: ${info.videoDetails.title}`);
            console.log(`   ✓ Channel: ${info.videoDetails.author.name}`);
            console.log(`   ✓ Published: ${info.videoDetails.publishDate}`);
            
            // Test youtube-captions-scraper
            console.log('2. Testing youtube-captions-scraper...');
            const captions = await getSubtitles({
                videoID: video.id,
                lang: video.lang
            });
            
            console.log(`   ✓ Fetched ${captions.length} caption entries`);
            if (captions.length > 0) {
                console.log(`   ✓ First caption: "${captions[0].text.substring(0, 50)}..."`);
                console.log(`   ✓ Start time: ${captions[0].start}`);
            }
            
        } catch (err) {
            console.error(`   ✗ Error: ${err.message}`);
            console.error(`   Stack: ${err.stack}`);
        }
    }
}

testSubtitles();