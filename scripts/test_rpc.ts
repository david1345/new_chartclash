import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

async function check() {
    const rpcs = ['exec_sql', 'execute_sql', 'run_sql'];
    const sql = `
        SELECT objid, classid, objsubid
        FROM pg_depend LIMIT 1;
    `;
    let success = false;
    for (const rpc of rpcs) {
        const { data, error } = await supabase.rpc(rpc, { sql });
        if (!error) {
            console.log(`✅ Success via ${rpc}`);
            console.log(data);
            success = true;
            break;
        }
    }
    if (!success) console.log('❌ All RPCs failed');
}
check();
