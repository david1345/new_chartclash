/**
 * Render.com Background Worker
 * This script runs 24/7 and triggers the API endpoints at exact candle boundaries.
 * 
 * LOCAL TEST: npx tsx scripts/render_worker.ts
 */

import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

const TARGET_URL = process.env.PRODUCTION_URL || 'http://localhost:3000';
const CRON_SECRET = process.env.CRON_SECRET || 'your_development_secret';

const SCHEDULER_ENDPOINT = `${TARGET_URL}/api/cron/analyst-scheduler`;
const RESOLVE_ENDPOINT = `${TARGET_URL}/api/cron/resolve`;

console.log(`\n--- 🚀 Render Worker Started (DEV MODE) ---`);
console.log(`Target: ${TARGET_URL}`);
console.log(`Wait Interval: 5 seconds\n`);

async function trigger(url: string, label: string) {
    try {
        console.log(`[${new Date().toLocaleTimeString()}] ⚡ Triggering ${label}...`);
        const res = await axios.get(url, {
            headers: { 'Authorization': `Bearer ${CRON_SECRET}` },
            timeout: 60000 // 60s timeout for long-running AI tasks
        });
        console.log(`   ✅ ${label} Success:`, res.data.message || res.data.processed || 'OK');
    } catch (e: any) {
        console.error(`   ❌ ${label} Failed:`, e.response?.data || e.message);
    }
}

async function heartbeat() {
    const now = new Date();
    const min = now.getMinutes();
    const sec = now.getSeconds();

    // Trigger Resolution every minute (approx)
    if (sec < 30) {
        await trigger(RESOLVE_ENDPOINT, 'Resolution');
    }

    // Trigger Scheduler at 15m boundaries (±30s)
    if (min % 15 === 0 && sec < 30) {
        await trigger(SCHEDULER_ENDPOINT, 'AI Analyst Scheduler');
    }
}

// Main Loop
setInterval(heartbeat, 30000); // Check every 30s
heartbeat(); // Initial run
