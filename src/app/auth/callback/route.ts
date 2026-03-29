import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const requestedNext = searchParams.get('next') ?? '/play/BTCUSDT/1h'
  const next = requestedNext.startsWith('/') ? requestedNext : '/play/BTCUSDT/1h'

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`)
    }

    const loginUrl = new URL('/login', origin)
    loginUrl.searchParams.set('error', 'auth')
    loginUrl.searchParams.set('reason', error.message)
    return NextResponse.redirect(loginUrl)
  }

  const loginUrl = new URL('/login', origin)
  loginUrl.searchParams.set('error', 'auth')
  loginUrl.searchParams.set('reason', 'Missing OAuth code in callback.')
  return NextResponse.redirect(loginUrl)
}
