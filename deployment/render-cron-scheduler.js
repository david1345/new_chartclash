#!/usr/bin/env node
/**
 * Render.com Cron Job - AI Analyst Scheduler
 *
 * This script runs on Render.com as a Cron Job to trigger
 * AI analysis generation for all assets at scheduled times.
 *
 * Schedule: */15 * * * * (every 15 minutes)
 */

const https = require('https');

// Configuration
const VERCEL_URL = process.env.VERCEL_URL || process.env.PRODUCTION_URL;
const CRON_SECRET = process.env.CRON_SECRET;

if (!VERCEL_URL) {
    console.error('❌ VERCEL_URL or PRODUCTION_URL environment variable is required');
    process.exit(1);
}

if (!CRON_SECRET) {
    console.error('❌ CRON_SECRET environment variable is required');
    process.exit(1);
}

// Ensure URL starts with https://
const baseUrl = VERCEL_URL.startsWith('http') ? VERCEL_URL : `https://${VERCEL_URL}`;
const url = `${baseUrl}/api/cron/analyst-scheduler`;

console.log(`[${new Date().toISOString()}] 🚀 Render.com Cron Job triggered`);
console.log(`   Target: ${url}`);

// Make HTTPS request
const req = https.request(url, {
    method: 'GET',
    headers: {
        'Authorization': `Bearer ${CRON_SECRET}`,
        'User-Agent': 'Render.com-Cron-Job',
        'X-Triggered-By': 'render-cron'
    },
    timeout: 300000 // 5 minutes timeout
}, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log(`   Status: ${res.statusCode}`);

        try {
            const result = JSON.parse(data);
            console.log('   Response:', JSON.stringify(result, null, 2));

            if (res.statusCode === 200) {
                console.log('✅ Cron job completed successfully');
                process.exit(0);
            } else {
                console.error('❌ Cron job failed with non-200 status');
                process.exit(1);
            }
        } catch (e) {
            console.error('❌ Failed to parse response:', data);
            process.exit(1);
        }
    });
});

req.on('error', (error) => {
    console.error('❌ Request failed:', error.message);
    process.exit(1);
});

req.on('timeout', () => {
    console.error('❌ Request timed out (5 minutes)');
    req.destroy();
    process.exit(1);
});

req.end();
