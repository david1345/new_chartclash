-- [CAUTION] This script deletes the accidental bot accounts from the production environment.
-- Run this in the Supabase SQL Editor.

BEGIN;

-- 1. Delete from auth.users (This will cascade to profiles if ON DELETE CASCADE is set)
DELETE FROM auth.users 
WHERE email IN (
  'bot_rsi@chartclash.app',
  'bot_momentum@chartclash.app',
  'bot_trend@chartclash.app',
  'bot_volatility@chartclash.app',
  'bot_levels@chartclash.app',
  'bot_volume@chartclash.app',
  'bot_breakout@chartclash.app',
  'bot_reversal@chartclash.app',
  'bot_correlation@chartclash.app',
  'bot_regime@chartclash.app'
);

-- 2. Cleanup any orphaned profiles (Username pattern for analyst bots)
DELETE FROM public.profiles 
WHERE username LIKE 'Analyst_%'
   OR id NOT IN (SELECT id FROM auth.users);

COMMIT;
