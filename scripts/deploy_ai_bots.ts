
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!; // Must be Service Role
const supabase = createClient(supabaseUrl, supabaseKey);

async function deployBots() {
    console.log('🚀 Starting AI Bots Deployment...');

    const bots = JSON.parse(fs.readFileSync('scripts/ai_bots_data.json', 'utf8'));

    for (const bot of bots) {
        console.log(`- Creating ${bot.username} (${bot.email})...`);

        // 1. Create User in Auth (Admin SDK)
        // We use a fixed password for bots or just let them stay as is
        const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
            email: bot.email,
            password: 'VibeBotPassword123!', // Standard bot password
            email_confirm: true,
            user_metadata: { is_bot: true, bot_persona: bot.persona }
        });

        if (authError) {
            if (authError.message.includes('already registered')) {
                console.log(`  [Skip] Auth user already exists.`);
            } else {
                console.error(`  [Error] Failed to create auth user:`, authError.message);
                continue;
            }
        }

        // 2. Profile is already handled by our 'on_auth_user_created' trigger!
        // But we need to update it with is_bot flag and persona
        const targetId = authUser?.user?.id;
        if (targetId) {
            const { error: profError } = await supabase
                .from('profiles')
                .update({
                    is_bot: true,
                    bot_persona: bot.persona,
                    username: bot.username,
                    tier: bot.tier,
                    points: 100000 // Give them some starting points
                })
                .eq('id', targetId);

            if (profError) {
                console.error(`  [Error] Failed to update profile:`, profError.message);
            } else {
                console.log(`  [Success] Bot ${bot.username} is now active.`);
            }
        }
    }

    console.log('✅ AI Bots Deployment Phase 1 Complete.');
}

deployBots();
