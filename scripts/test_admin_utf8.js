const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function checkData() {
    console.log("Checking profiles...");
    const { data: profiles, error: pErr } = await supabase.from('profiles').select('id, username, email').limit(10);
    if (pErr) console.error("Profiles error:", pErr);
    else console.log("Profiles snippet OK:", profiles?.length);

    console.log("Checking predictions...");
    const { data: preds, error: prErr } = await supabase.from('predictions').select('id, asset_symbol, comment').limit(50).order('created_at', { ascending: false });
    if (prErr) {
        console.error("Predictions error:", prErr);
    } else {
        console.log("Predictions fetched OK:", preds?.length);
        for (const p of (preds || [])) {
            try {
                JSON.stringify(p);
            } catch (e) {
                console.error("UTF8 / JSON Error on prediction", p.id, e);
            }
        }
    }
}

checkData();
