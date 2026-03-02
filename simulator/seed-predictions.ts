
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

async function seedPredictions() {
    console.log('🚀 Starting to seed predictions...');

    // 1. Get test user
    const { data: { users }, error: userError } = await supabase.auth.admin.listUsers();
    if (userError) {
        console.error('❌ Failed to list users:', userError);
        return;
    }

    const testUser = users.find(u => u.email === 'test1@mail.com');
    if (!testUser) {
        console.error('❌ test1@mail.com not found. Run seed-users.ts first.');
        return;
    }

    console.log(`👤 Seeding for user: ${testUser.id} (${testUser.email})`);

    // 2. Insert dummy predictions
    const predictions = [
        {
            user_id: testUser.id,
            asset_symbol: 'BTCUSDT',
            direction: 'UP',
            timeframe: '15m',
            entry_price: 50000,
            target_percent: 1.0,
            bet_amount: 100,
            status: 'WIN',
            actual_price: 50600,
            profit: 180,
            created_at: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
            candle_close_at: new Date(Date.now() - 86400000 + 900000).toISOString(),
            resolved_at: new Date(Date.now() - 86400000 + 900000).toISOString()
        },
        {
            user_id: testUser.id,
            asset_symbol: 'ETHUSDT',
            direction: 'DOWN',
            timeframe: '1h',
            entry_price: 3000,
            target_percent: 0.5,
            bet_amount: 50,
            status: 'LOSS',
            actual_price: 3010,
            profit: -50,
            created_at: new Date(Date.now() - 172800000).toISOString(), // 2 days ago
            candle_close_at: new Date(Date.now() - 172800000 + 3600000).toISOString(),
            resolved_at: new Date(Date.now() - 172800000 + 3600000).toISOString()
        }
    ];

    const { error } = await supabase.from('predictions').insert(predictions);

    if (error) {
        console.error('❌ Failed to insert predictions:', error);
    } else {
        console.log('✅ Successfully seeded dummy predictions!');
    }
}

seedPredictions().catch(console.error);
