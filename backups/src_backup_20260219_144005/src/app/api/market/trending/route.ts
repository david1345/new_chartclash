import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const category = searchParams.get('category') || 'CRYPTO';

        // Get top 3 trending assets for the selected category
        const { data: trending, error } = await supabase.rpc('get_trending_by_single_category', {
            p_category: category
        });

        if (error) {
            console.error('Failed to fetch trending:', error);
            return NextResponse.json({ success: false, error: error.message }, { status: 400 });
        }

        return NextResponse.json({ success: true, data: trending || [] });
    } catch (err: any) {
        console.error('Trending API error:', err);
        return NextResponse.json({ success: false, error: err.message }, { status: 500 });
    }
}
