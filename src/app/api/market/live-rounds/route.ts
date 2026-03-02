import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const category = searchParams.get('category'); // ALL, CRYPTO, STOCKS, COMMODITIES
        const limit = parseInt(searchParams.get('limit') || '50');

        // Get all live rounds with stats
        const { data: rounds, error } = await supabase.rpc('get_live_rounds_with_stats', {
            p_category: category || 'ALL',
            p_limit: limit
        });

        if (error) {
            console.error('Failed to fetch live rounds:', error);
            return NextResponse.json({ success: false, error: error.message }, { status: 400 });
        }

        return NextResponse.json({ success: true, data: rounds || [] });
    } catch (err: any) {
        console.error('Live rounds API error:', err);
        return NextResponse.json({ success: false, error: err.message }, { status: 500 });
    }
}
