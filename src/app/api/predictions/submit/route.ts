import { createClient } from '@/lib/supabase/server';
import { createClient as createServiceClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

// Service role client only for RPC execution (after auth is verified)
const serviceSupabase = createServiceClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const getTimestamp = () => `[${new Date().toLocaleTimeString()}]`;

export async function POST(req: NextRequest) {
    try {
        // 1. Authenticate: get user from JWT server-side (never trust client-provided user id)
        const supabase = await createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json({ success: false, error: 'Unauthorized' }, { status: 401 });
        }

        const {
            p_asset_symbol,
            p_timeframe,
            p_direction,
            p_target_percent,
            p_entry_price,
            p_bet_amount
        } = await req.json();

        // 2. Fetch User Nickname for better logging
        const { data: profile } = await serviceSupabase.from('profiles').select('username').eq('id', user.id).single();
        const userLabel = profile?.username || user.id;

        // 3. Critical Logging for Vercel
        console.log(`${getTimestamp()} [BET ATTEMPT] User: ${userLabel}, Symbol: ${p_asset_symbol}, TF: ${p_timeframe}, Dir: ${p_direction}, Target: ${p_target_percent}%, Price: ${p_entry_price}, Amount: ${p_bet_amount}`);

        if (!p_asset_symbol) {
            return NextResponse.json({ success: false, error: 'Missing required fields' }, { status: 400 });
        }

        // 4. Execute RPC — user.id comes from verified JWT, not from client
        const { data, error } = await serviceSupabase.rpc('submit_prediction', {
            p_user_id: user.id,
            p_asset_symbol,
            p_timeframe,
            p_direction,
            p_target_percent,
            p_entry_price,
            p_bet_amount
        });

        if (error) {
            console.error(`${getTimestamp()} [BET FAILED] User: ${userLabel}, Error: ${error.message}`);
            return NextResponse.json({ success: false, error: error.message }, { status: 400 });
        }

        console.log(`${getTimestamp()} [BET SUCCESS] User: ${userLabel}, PredID: ${data?.prediction_id || '?'}`);

        return NextResponse.json({ success: true, data });

    } catch (err: any) {
        console.error(`${getTimestamp()} [BET CRITICAL ERROR]`, err);
        return NextResponse.json({ success: false, error: err.message }, { status: 500 });
    }
}
