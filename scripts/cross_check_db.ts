
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

async function check() {
    const configs = [
        { name: 'PROD_ENV', url: process.env.NEXT_PUBLIC_SUPABASE_URL, key: process.env.SUPABASE_SERVICE_ROLE_KEY },
    ];

    // Also check .env manually if available
    const fs = require('fs');
    if (fs.existsSync('.env')) {
        const envContent = fs.readFileSync('.env', 'utf8');
        const prodUrl = envContent.match(/NEXT_PUBLIC_SUPABASE_URL=(.*)/)?.[1];
        const prodKey = envContent.match(/SUPABASE_SERVICE_ROLE_KEY=(.*)/)?.[1];
        if (prodUrl && prodKey) {
            configs.push({ name: 'PROD_CORE', url: prodUrl.trim(), key: prodKey.trim() });
        }
    }

    for (const conf of configs) {
        console.log(`\n--- CHECKING PROJECT: ${conf.name} (${conf.url}) ---`);
        const supabase = createClient(conf.url, conf.key);

        const { count, error } = await supabase.from('predictions').select('*', { count: 'exact', head: true });
        if (error) {
            console.error(`Error fetching count: ${error.message}`);
            continue;
        }
        console.log(`Total predictions: ${count}`);

        const { data: latest } = await supabase
            .from('predictions')
            .select('*, profiles(email, username)')
            .order('created_at', { ascending: false })
            .limit(5);
        console.log('Latest 5 predictions:', JSON.stringify(latest, null, 2));

        const { data: sysConfigs } = await supabase.from('system_configs').select('*');
        console.log('System Configs:', JSON.stringify(sysConfigs, null, 2));
    }
}

check();
