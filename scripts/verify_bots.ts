
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

async function verifyBots() {
    const { data, error } = await supabase
        .from('profiles')
        .select('username, is_bot, bot_persona')
        .eq('is_bot', true);

    if (error) {
        console.error('❌ Verification Error:', error.message);
    } else {
        console.log(`✅ Found ${data?.length || 0} bots in profiles:`);
        data?.forEach(b => console.log(` - ${b.username}: ${JSON.stringify(b.bot_persona).substring(0, 50)}...`));
    }
}

verifyBots();
