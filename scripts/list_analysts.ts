import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function listAnalysts() {
    console.log('--- Listing Analyst Profiles ---');
    const { data: analysts, error } = await supabase
        .from('profiles')
        .select('username, email')
        .ilike('username', 'Analyst_%');

    if (error) {
        console.error(error);
        return;
    }

    console.log(`Total Analysts Found: ${analysts?.length || 0}`);
    for (const a of analysts || []) {
        console.log(`- ${a.username}`);
    }
}

listAnalysts();
