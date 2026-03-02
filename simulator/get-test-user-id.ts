
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

const isProd = process.env.TEST_ENV === 'production';
const envPath = isProd
    ? path.resolve(__dirname, '.env.production')
    : path.resolve(process.cwd(), '.env.local');

console.log(`Loading env from: ${envPath}`);
dotenv.config({ path: envPath });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function getUserId() {
    const { data: users, error } = await supabase.auth.admin.listUsers();
    if (error) {
        console.error(error);
        return;
    }
    const testUser = users.users.find(u => u.email === 'test1@mail.com');
    if (testUser) {
        console.log(`TEST_USER_ID=${testUser.id}`);
    } else {
        console.log('User not found');
    }
}

getUserId();
