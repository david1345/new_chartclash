
import { Page, expect, APIRequestContext } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// Load env vars based on TEST_ENV
const isProd = process.env.TEST_ENV === 'production';
const envPath = isProd
    ? path.resolve(__dirname, '../.env.production')
    : path.resolve(__dirname, '../../.env.local');

console.log(`Loading env from: ${envPath}`);
dotenv.config({ path: envPath });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

/**
 * Resets the test user's data directly via Supabase.
 */
export async function resetTestUser(request: any, userId: string) {
    if (isProd) {
        console.warn('⚠️⚠️⚠️ WARNING: RUNNING RESET ON PRODUCTION DB ⚠️⚠️⚠️');
        console.warn(`Target User ID: ${userId}`);
        console.warn('Waiting 3 seconds before proceeding...');
        await new Promise(r => setTimeout(r, 3000));
    }
    console.log(`Resetting user ${userId}...`);

    try {
        const { error } = await supabase.rpc('reset_test_user', { p_user_id: userId });
        if (error) throw error;
        console.log('User reset successful via RPC');
    } catch (e: any) {
        console.warn('RPC reset failed, attempting fallback...', e.message);
        try {
            // Individual table deletions to handle missing tables gracefully
            await supabase.from('activity_logs').delete().eq('user_id', userId);
            await supabase.from('notifications').delete().eq('user_id', userId);
            await supabase.from('predictions').delete().eq('user_id', userId);
            await supabase.from('prediction_likes').delete().eq('user_id', userId);

            await supabase.from('profiles').update({
                points: 1000,
                streak: 0,
                streak_count: 0,
                total_games: 0,
                total_wins: 0
            }).eq('id', userId);
            console.log('User reset successful (fallback partial)');
        } catch (fallbackError: any) {
            console.error('Fallback reset also failed:', fallbackError.message);
            throw fallbackError;
        }
    }
}

export async function login(page: Page) {
    await page.goto('/');

    // 헤더 로딩 대기
    await expect(page.locator('header')).toBeVisible({ timeout: 15000 });

    // 로그인 상태 확인
    const userAvatar = page.locator('[data-testid="user-points"], .rounded-full.bg-gradient-to-b');
    const loginButton = page.getByTestId('login-button');

    // 이미 로그인되어 있는지 확인
    if (await userAvatar.count() > 0 && await userAvatar.first().isVisible()) {
        console.log('✅ Already logged in');
        return;
    }

    // 로그인 버튼 대기 및 클릭
    await expect(loginButton).toBeVisible({ timeout: 10000 });
    await loginButton.click();

    // 로그인 폼 입력
    await page.getByTestId('email-input').fill('test1@mail.com');
    await page.getByTestId('password-input').fill('123456');
    await page.getByTestId('submit-login').click();

    // 로그인 완료 대기 (Toast 또는 아바타/포인트 표시)
    await expect(page.getByTestId('user-points')).toBeVisible({ timeout: 15000 });
    console.log('✅ Login successful');
}

export async function waitForHydration(page: Page) {
    await page.waitForFunction(() => {
        return document.readyState === 'complete';
    });
}
