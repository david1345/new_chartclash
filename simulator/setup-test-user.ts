
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setupTestUser() {
    console.log('Setting up test1@mail.com...');

    const email = 'test1@mail.com';
    const password = '123456';

    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { display_name: 'Test Hunter' }
    });

    if (authError) {
        if (authError.message.includes('already exists')) {
            console.log('User already exists in Auth.');
            // But if it exists, why did previous check fail? Maybe it was listing only 50 users?
        } else {
            console.error('Auth create error:', authError.message);
            return;
        }
    } else {
        console.log('User created in Auth:', authUser.user.id);
    }

    // Now check/create profile
    // The ID might be different if it already exists
    const uid = authUser?.user?.id || (await supabase.auth.admin.listUsers()).data.users.find(u => u.email === email)?.id;

    if (!uid) {
        console.error('Could not find user ID');
        return;
    }

    const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .upsert({
            id: uid,
            username: 'test_hunter',
            points: 1000,
            tier: 'Bronze',
            total_games: 0,
            total_wins: 0
        })
        .select()
        .single();

    if (profileError) {
        console.error('Profile setup error:', profileError.message);
    } else {
        console.log('Profile setup successful:', profile);
    }
}

setupTestUser();
