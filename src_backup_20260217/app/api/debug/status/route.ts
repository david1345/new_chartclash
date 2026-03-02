import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET() {
    const now = Date.now();

    const { data: predictions, error } = await supabase
        .from('predictions')
        .select('*')
        .eq('status', 'pending');

    if (error) return NextResponse.json({ error });

    const analysis = predictions.map(p => {
        const closeTime = new Date(p.candle_close_at).getTime();
        return {
            id: p.id,
            symbol: p.asset_symbol,
            timeframe: p.timeframe,
            created_at: p.created_at,
            candle_close_at: p.candle_close_at,
            close_time_ts: closeTime,
            server_now_ts: now,
            seconds_remaining: (closeTime - now) / 1000,
            is_ready: now > closeTime + 10000, // 10s buffer matches route.ts
            should_have_resolved: now > closeTime + 10000
        };
    });

    return NextResponse.json({
        server_time: new Date(now).toISOString(),
        pending_count: predictions.length,
        analysis
    });
}
