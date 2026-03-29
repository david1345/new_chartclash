import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const requestedNext = searchParams.get('next') ?? '/play/BTCUSDT/1h'
  const next = requestedNext.startsWith('/') ? requestedNext : '/play/BTCUSDT/1h'
  const error = searchParams.get('error')
  const errorDescription = searchParams.get('error_description')

  const loginUrl = new URL('/login', origin)
  loginUrl.searchParams.set('next', next)

  if (code) {
    loginUrl.searchParams.set('code', code)
    return NextResponse.redirect(loginUrl)
  }

  if (error) {
    loginUrl.searchParams.set('error', error)
  } else {
    loginUrl.searchParams.set('error', 'auth')
  }

  if (errorDescription) {
    loginUrl.searchParams.set('reason', errorDescription)
  } else {
    loginUrl.searchParams.set('reason', 'Missing OAuth code in callback.')
  }

  return NextResponse.redirect(loginUrl)
}
