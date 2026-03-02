
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkUser() {
    console.log('Checking test1@mail.com...');
    const { data: authUser, error: authError } = await supabase.auth.admin.listUsers();
    if (authError) {
        console.error('Auth check error:', authError.message);
        return;
    }

    const testUser = authUser.users.find(u => u.email === 'test1@mail.com');
    if (!testUser) {
        console.error('User test1@mail.com NOT found in Auth');
        return;
    }

    console.log('User found in Auth:', testUser.id);

    const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', testUser.id)
        .single();

    if (profileError) {
        console.error('Profile check error:', profileError.message);
    } else {
        console.log('Profile found:', profile);
    }
}

checkUser();
