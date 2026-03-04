import { createBrowserClient } from '@supabase/ssr'
import { type SupabaseClient } from '@supabase/supabase-js'

let client: SupabaseClient | null = null;

export function createClient(): SupabaseClient {
    if (client) return client;

    client = createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookieOptions: {
                path: '/',
                sameSite: 'lax',
                secure: false, // Must be false for local IP HTTP development!
            }
        }
    )
    return client;
}
