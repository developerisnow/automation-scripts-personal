#!/usr/bin/env node

const { YoutubeTranscript } = require('youtube-transcript');
const ytdl = require('ytdl-core');

// Test video IDs
const testVideos = [
    { id: 'ZbHpinVP6mk', lang: 'ru', name: 'Russian video' },
    { id: 'kqB_xML1SfA', lang: 'en', name: 'English video' }
];

async function testTranscript() {
    for (const video of testVideos) {
        console.log(`\n=== Testing ${video.name} (${video.id}) ===`);
        
        try {
            // Test ytdl-core first
            console.log('1. Testing ytdl-core...');
            const info = await ytdl.getBasicInfo(video.id);
            console.log(`   ✓ Title: ${info.videoDetails.title}`);
            console.log(`   ✓ Channel: ${info.videoDetails.author.name}`);
            console.log(`   ✓ Published: ${info.videoDetails.publishDate}`);
            
            // Test youtube-transcript
            console.log('2. Testing youtube-transcript...');
            const transcript = await YoutubeTranscript.fetchTranscript(video.id, {
                lang: video.lang
            });
            
            console.log(`   ✓ Fetched ${transcript.length} transcript entries`);
            if (transcript.length > 0) {
                console.log(`   ✓ First entry: "${transcript[0].text.substring(0, 50)}..."`);
                console.log(`   ✓ Offset: ${transcript[0].offset}ms, Duration: ${transcript[0].duration}ms`);
            }
            
        } catch (err) {
            console.error(`   ✗ Error: ${err.message}`);
            if (err.cause) {
                console.error(`   ✗ Cause: ${err.cause}`);
            }
        }
    }
}

testTranscript();