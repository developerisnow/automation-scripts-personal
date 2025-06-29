#!/usr/bin/env node

const ytdl = require('ytdl-core');

// Test video IDs
const testVideos = [
    { id: 'ZbHpinVP6mk', lang: 'ru', name: 'Russian video' },
    { id: 'kqB_xML1SfA', lang: 'en', name: 'English video' }
];

async function checkCaptions() {
    for (const video of testVideos) {
        console.log(`\n=== Checking ${video.name} (${video.id}) ===`);
        
        try {
            // Get full video info including formats
            const info = await ytdl.getInfo(video.id);
            
            console.log(`Title: ${info.videoDetails.title}`);
            console.log(`Channel: ${info.videoDetails.author.name}`);
            
            // Check caption tracks
            const captionTracks = info.player_response?.captions?.playerCaptionsTracklistRenderer?.captionTracks;
            
            if (captionTracks && captionTracks.length > 0) {
                console.log(`\nAvailable caption tracks:`);
                captionTracks.forEach(track => {
                    console.log(`  - ${track.languageCode}: ${track.name.simpleText || track.name.runs[0].text}`);
                    console.log(`    URL: ${track.baseUrl}`);
                });
            } else {
                console.log(`\nNo caption tracks found in player response`);
            }
            
            // Also check for automatic captions
            const translationLanguages = info.player_response?.captions?.playerCaptionsTracklistRenderer?.translationLanguages;
            if (translationLanguages && translationLanguages.length > 0) {
                console.log(`\nTranslation languages available: ${translationLanguages.length}`);
            }
            
        } catch (err) {
            console.error(`Error: ${err.message}`);
        }
    }
}

checkCaptions();