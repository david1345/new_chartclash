
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

const ADJECTIVES = ['Alpha', 'Crystal', 'Crypto', 'Moon', 'Short', 'Bull', 'Bear', 'Rocket', 'Scanner', 'Wizard', 'Vibe', 'Chart', 'Logic', 'Trend', 'Rich'];
const NOUNS = ['Hunter', 'Genius', 'Master', 'Whale', 'Prophet', 'Signal', 'Runner', 'Pro', 'God', 'Ace', 'Tamer', 'Seeker', 'Legend'];
const TIERS = ['silver', 'gold', 'platinum', 'diamond'];

function generatePersona(index: number) {
    const styleIdx = index % 4;
    const styles = ['Scalper', 'Swinger', 'Hodler', 'Contrarian'];
    const assets = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XAUUSD', 'NQ'];

    return {
        style: styles[styleIdx],
        bias: index % 2 === 0 ? 'BULLISH' : 'BEARISH',
        favorite_assets: [assets[index % assets.length]],
        risk_score: Math.random().toFixed(2),
        active_tf: index % 3 === 0 ? ['15m', '30m'] : ['1h', '4h', '1d']
    };
}

async function createBots(count: number) {
    console.log(`🚀 Preparing ${count} AI Bots...`);
    const bots = [];

    for (let i = 1; i <= count; i++) {
        const username = `${ADJECTIVES[i % ADJECTIVES.length]}${NOUNS[i % NOUNS.length]}${i}`;
        const email = `bot_${username.toLowerCase()}@vibe.ai`;
        const tier = TIERS[i % TIERS.length];

        // In a real scenario, we'd use supabase.auth.admin.createUser 
        // but for this script, we'll just generate the data for the user to review.
        bots.push({
            id: `00000000-0000-0000-0000-${i.toString(16).padStart(12, '0')}`, // Deterministic IDs for testing
            email,
            username,
            tier,
            persona: generatePersona(i)
        });
    }

    fs.writeFileSync('scripts/ai_bots_data.json', JSON.stringify(bots, null, 2));
    console.log(`✅ Generated data for ${count} bots in scripts/ai_bots_data.json`);

    // Generate SQL for direct injection if needed
    let sql = '-- [AI BOTS INJECTION]\n';
    for (const b of bots) {
        // We'd need to insert into auth.users first if doing pure SQL
        // This is a simplified version for the user to see the scale
    }
}

createBots(100);
