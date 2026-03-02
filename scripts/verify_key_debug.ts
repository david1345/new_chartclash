
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

async function checkKey() {
    console.log("Checking Service Role Key...");
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!url || !key) {
        console.error("Missing URL or Key in .env.local");
        return;
    }

    console.log("URL:", url);
    // Show first/last chars only
    console.log("Key:", key.substring(0, 5) + "..." + key.substring(key.length - 5));

    const supabase = createClient(url, key);

    // Try a simple admin operation (count users)
    const { count, error } = await supabase.from('profiles').select('*', { count: 'exact', head: true });

    if (error) {
        console.error("FAIL: Key failed to authenticate.", error.message);
    } else {
        console.log(`SUCCESS: Key is valid. User count: ${count}`);
    }
}

checkKey();
