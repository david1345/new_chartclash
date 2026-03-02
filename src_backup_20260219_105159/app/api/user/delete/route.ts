import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST() {
    const cookieStore = await cookies()

    // 1. Create a regular client to identify the user
    const supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                getAll() { return cookieStore.getAll() },
                setAll(cookiesToSet) {
                    try {
                        cookiesToSet.forEach(({ name, value, options }) =>
                            cookieStore.set(name, value, options)
                        )
                    } catch { }
                },
            },
        }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (authError || !user) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // 2. Create an admin client to perform the deletion
    // We use the service role key which bypasses RLS and can delete from auth.users
    const supabaseAdmin = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!, // This MUST be set in your env
        {
            cookies: {
                getAll() { return cookieStore.getAll() },
                setAll() { }, // Admin client doesn't need to set persistence cookies
            },
        }
    )

    // 3. Delete the user
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteError) {
        console.error('Delete error:', deleteError)
        return NextResponse.json({ error: deleteError.message }, { status: 500 })
    }

    // 4. Sign out the user (clear cookies)
    await supabase.auth.signOut()

    return NextResponse.json({ success: true })
}
