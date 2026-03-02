
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// Load production env
const envPath = path.resolve(process.cwd(), 'simulator/.env.production');
console.log(`Loading env from: ${envPath}`);
dotenv.config({ path: envPath });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('Missing Supabase credentials');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkAssets() {
    console.log('Checking assets in production DB...');
    const { data, error } = await supabase.from('assets').select('*');

    if (error) {
        console.error('Error fetching assets:', error);
        return;
    }

    console.log(`Found ${data.length} assets.`);
    if (data.length > 0) {
        console.log('Sample assets:', data.slice(0, 5).map(a => ({ symbol: a.symbol, name: a.name })));
    } else {
        console.warn('⚠️ NO ASSETS FOUND IN PRODUCTION DB');
    }
}

checkAssets();
