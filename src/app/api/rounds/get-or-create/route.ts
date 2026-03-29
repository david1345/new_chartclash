import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import { createRoundOnChain } from '@/lib/contract-server';
import { ASSETS } from '@/lib/constants';
import { requireAuthenticatedUser } from '@/lib/server-access';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const VALID_ASSETS = new Set(Object.values(ASSETS).flat().map((asset) => asset.symbol));
const VALID_TIMEFRAMES = new Set(['1h', '4h']);

function getDurationMs(timeframe: string): number | null {
    if (timeframe === '1h') return 60 * 60 * 1000;
    if (timeframe === '4h') return 4 * 60 * 60 * 1000;
    return null;
}

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
        const auth = await requireAuthenticatedUser();
        if (auth.response) return auth.response;

        const { asset, timeframe, openTime, closeTime, openPrice } = await req.json();

        if (!asset || !timeframe || !openTime || !closeTime || !openPrice) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
        }

        if (!VALID_ASSETS.has(asset)) {
            return NextResponse.json({ error: 'Unsupported asset' }, { status: 400 });
        }

        if (!VALID_TIMEFRAMES.has(timeframe)) {
            return NextResponse.json({ error: 'Unsupported timeframe' }, { status: 400 });
        }

        if (!Number.isFinite(openPrice) || openPrice <= 0) {
            return NextResponse.json({ error: 'Invalid open price' }, { status: 400 });
        }

        const durationMs = getDurationMs(timeframe);
        if (!durationMs) {
            return NextResponse.json({ error: 'Invalid timeframe duration' }, { status: 400 });
        }

        if (closeTime - openTime !== durationMs) {
            return NextResponse.json({ error: 'Invalid round timing' }, { status: 400 });
        }

        if (openTime % durationMs !== 0 || closeTime % durationMs !== 0) {
            return NextResponse.json({ error: 'Round timing must align to candle boundaries' }, { status: 400 });
        }

        const now = Date.now();
        const maxFutureSkew = durationMs;
        if (openTime > now + 5_000 || closeTime < now - 60_000 || closeTime > now + maxFutureSkew) {
            return NextResponse.json({ error: 'Round timing is outside the allowed window' }, { status: 400 });
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
