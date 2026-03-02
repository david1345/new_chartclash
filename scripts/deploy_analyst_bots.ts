
import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
console.log(`📡 Deployment Target URL: ${supabaseUrl}`);
const supabase = createClient(supabaseUrl, supabaseKey);

async function deployAnalystBots() {
    console.log('🚀 Deploying 10 System Analyst Bots...');

    const bots = JSON.parse(fs.readFileSync('scripts/analyst_bots_data.json', 'utf8'));

    for (const bot of bots) {
        console.log(`- Setting up ${bot.username} (${bot.email})...`);

        // 1. Create User in Auth (Admin SDK)
        const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
            email: bot.email,
            password: 'AnalystBotAuth!', // Standard password
            email_confirm: true,
            user_metadata: { is_bot: true, bot_role: bot.role }
        });

        if (authError) {
            if (authError.message.includes('already registered')) {
                console.log(`  [Skip] Auth user already exists.`);
            } else {
                console.error(`  [Error] Failed to create auth user:`, authError.message);
                continue;
            }
        }

        // 2. Profile update (Trigger usually creates profile, we just hydrate it)
        // We'll search by email if authUser is null (already exists case)
        let targetId = authUser?.user?.id;

        if (!targetId) {
            const { data: userData } = await supabase.auth.admin.listUsers();
            targetId = userData.users.find(u => u.email === bot.email)?.id;
        }

        if (targetId) {
            const { error: profError } = await supabase
                .from('profiles')
                .update({
                    is_bot: true,
                    bot_persona: bot.persona,
                    username: bot.username,
                    tier: 'PRO', // Analysts are PROs
                    points: 1000000 // Unlimited points effectively
                })
                .eq('id', targetId);

            if (profError) {
                console.error(`  [Error] Failed to update profile:`, profError.message);
            } else {
                console.log(`  [Success] Analyst ${bot.username} is ready.`);
            }
        }
    }

    console.log('✅ Analyst Bots Deployment Complete.');
}

deployAnalystBots();
