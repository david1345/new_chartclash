import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import { createRoundOnChain } from '@/lib/contract-server';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

/**
 * POST /api/rounds/get-or-create
 * Body: { asset, timeframe, openTime (ms), closeTime (ms), openPrice }
 * Returns: { onChainId: string }
 *
 * Idempotent: creates the on-chain round once, stores in Supabase `rounds` table.
 * Subsequent calls return the existing onChainId.
 */
export async function POST(req: NextRequest) {
    try {
        const { asset, timeframe, openTime, closeTime, openPrice } = await req.json();

        if (!asset || !timeframe || !openTime || !closeTime || !openPrice) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
        }

        // Look up existing round
        const { data: existing } = await supabase
            .from('rounds')
            .select('on_chain_id')
            .eq('asset', asset)
            .eq('timeframe', timeframe)
            .eq('open_time', openTime)
            .maybeSingle();

        if (existing?.on_chain_id) {
            return NextResponse.json({ onChainId: existing.on_chain_id });
        }

        // Create round on-chain (oracle signs)
        const closeTimeSec = Math.floor(closeTime / 1000);
        const onChainId = await createRoundOnChain(asset, timeframe, openPrice, closeTimeSec);

        // Store in Supabase
        await supabase.from('rounds').upsert({
            asset,
            timeframe,
            open_time: openTime,
            close_time: closeTime,
            open_price: openPrice,
            on_chain_id: onChainId,
            status: 'open'
        }, { onConflict: 'asset,timeframe,open_time' });

        return NextResponse.json({ onChainId });

    } catch (err: any) {
        console.error('[rounds/get-or-create] Error:', err.message);
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
