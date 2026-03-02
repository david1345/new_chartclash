import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// .env.local에서 환경 변수 로드
dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('❌ Missing environment variables in .env.local');
    process.exit(1);
}

// Admin 권한을 가진 클라이언트 생성
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

const testUsers = [
    { email: 'test1@mail.com', password: '123456' },
    { email: 'test2@mail.com', password: '123456' },
    { email: 'test3@mail.com', password: '123456' },
    { email: 'test4@mail.com', password: '123456' },
    { email: 'test5@mail.com', password: '123456' },
];

async function seedUsers() {
    console.log('🚀 Starting to seed test users in development database...');
    console.log(`URL: ${supabaseUrl}\n`);

    for (const user of testUsers) {
        console.log(`👥 Creating user: ${user.email}...`);

        // 1. 유저 생성 (Admin API 사용 - 이메일 인증 건너뜀)
        const { data, error } = await supabase.auth.admin.createUser({
            email: user.email,
            password: user.password,
            email_confirm: true // 즉시 활성화
        });

        if (error) {
            if (error.message.includes('already registered')) {
                console.log(`   ℹ️  User already exists.`);
            } else {
                console.error(`   ❌ Failed: ${error.message}`);
            }
        } else {
            console.log(`   ✅ Success! User ID: ${data.user?.id}`);
        }
    }

    console.log('\n✨ Seeding completed!');
}

seedUsers().catch(console.error);
