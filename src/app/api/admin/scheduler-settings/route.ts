import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

import { requireAdminUser } from '@/lib/server-access';

const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// GET: Fetch current scheduler settings
export async function GET(req: Request) {
    try {
        const auth = await requireAdminUser();
        if (auth.response) return auth.response;

        const { data, error } = await supabase.rpc('get_scheduler_settings', {
            p_service_name: 'ai_analyst'
        });

        if (error) throw error;

        return NextResponse.json({
            success: true,
            data: data?.[0] || { enabled: false, timeframes: ['15m', '30m', '1h', '4h', '1d'] }
        });
    } catch (error: any) {
        console.error('Failed to fetch scheduler settings:', error);
        return NextResponse.json({
            success: false,
            error: error.message
        }, { status: 500 });
    }
}

// POST: Update scheduler settings
export async function POST(req: Request) {
    try {
        const auth = await requireAdminUser();
        if (auth.response) return auth.response;

        const body = await req.json();
        const { enabled, timeframes } = body;

        // Validate timeframes if provided
        const validTimeframes = ['15m', '30m', '1h', '4h', '1d'];
        if (timeframes && !Array.isArray(timeframes)) {
            return NextResponse.json({
                success: false,
                error: 'Timeframes must be an array'
            }, { status: 400 });
        }

        if (timeframes) {
            const invalid = timeframes.filter((tf: string) => !validTimeframes.includes(tf));
            if (invalid.length > 0) {
                return NextResponse.json({
                    success: false,
                    error: `Invalid timeframes: ${invalid.join(', ')}`
                }, { status: 400 });
            }
        }

        const { data, error } = await supabase.rpc('update_scheduler_settings', {
            p_service_name: 'ai_analyst',
            p_enabled: enabled ?? null,
            p_timeframes: timeframes ?? null
        });

        if (error) throw error;

        return NextResponse.json({
            success: true,
            message: 'Scheduler settings updated successfully'
        });
    } catch (error: any) {
        console.error('Failed to update scheduler settings:', error);
        return NextResponse.json({
            success: false,
            error: error.message
        }, { status: 500 });
    }
}
