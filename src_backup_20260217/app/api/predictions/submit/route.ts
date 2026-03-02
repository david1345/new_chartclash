// Nudge: Forcing re-compile after structure fix
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const getTimestamp = () => `[${new Date().toLocaleTimeString()}]`;

export async function POST(req: NextRequest) {
    try {
        const {
            p_user_id,
            p_asset_symbol,
            p_timeframe,
            p_direction,
            p_target_percent,
            p_entry_price,
            p_bet_amount
        } = await req.json();

        // 1. Fetch User Nickname for better logging
        const { data: profile } = await supabase.from('profiles').select('username').eq('id', p_user_id).single();
        const userLabel = profile?.username || p_user_id;

        // 2. Critical Logging for Vercel
        console.log(`${getTimestamp()} [BET ATTEMPT] User: ${userLabel}, Symbol: ${p_asset_symbol}, TF: ${p_timeframe}, Dir: ${p_direction}, Target: ${p_target_percent}%, Price: ${p_entry_price}, Amount: ${p_bet_amount}`);

        if (!p_user_id || !p_asset_symbol) {
            return NextResponse.json({ success: false, error: "Missing required fields" }, { status: 400 });
        }

        // 3. Execute RPC
        const { data, error } = await supabase.rpc('submit_prediction', {
            p_user_id,
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

        console.log(`${getTimestamp()} [BET SUCCESS] User: ${userLabel}, PredID: ${data?.id || '?'}`);

        return NextResponse.json({ success: true, data });

    } catch (err: any) {
        console.error(`${getTimestamp()} [BET CRITICAL ERROR]`, err);
        return NextResponse.json({ success: false, error: err.message }, { status: 500 });
    }
}
