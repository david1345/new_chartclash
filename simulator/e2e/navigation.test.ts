import { test, expect } from '@playwright/test';
import { resetTestUser, login } from './utils';

// TEST_USER_ID obtained from script
const TEST_USER_ID = process.env.TEST_USER_ID || '4e902b28-abdd-4626-8ffd-638a02f98f98';

test.describe('네비게이션 테스트 (Navigation Tests)', () => {
    test.beforeEach(async ({ page, request }) => {
        // 1. DB 초기화
        await resetTestUser(request, TEST_USER_ID);

        // 2. 로그인
        await login(page);
    });

    test('TC-NAV-01: 홈 페이지 접근 (Home Page)', async ({ page }) => {
        await page.goto('/', { timeout: 20000 });

        // 주요 요소 확인
        await expect(page).toHaveURL(/.*\//);

        // 헤더는 항상 표시되어야 함
        await expect(page.locator('header')).toBeVisible({ timeout: 15000 });

        // OrderPanel이 로드되는지 확인 (시간이 좀 걸릴 수 있음)
        await expect(
            page.locator('text=Make Prediction').or(page.getByTestId('btn-up'))
        ).toBeVisible({ timeout: 15000 });
    });

    test('TC-NAV-01: 내 통계 페이지 (My Stats)', async ({ page }) => {
        await page.goto('/my-stats');

        await expect(page).toHaveURL(/.*my-stats/);

        // 통계 요소 확인 (빈 상태일 수도 있음)
        // 페이지 제목 또는 주요 컨테이너 확인
        await expect(page.locator('h1').or(page.getByTestId('total-predictions'))).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 매치 히스토리 페이지 (Match History)', async ({ page }) => {
        await page.goto('/match-history');

        await expect(page).toHaveURL(/.*match-history/);

        // 히스토리 테이블이나 리스트 확인
        await expect(
            page.locator('text=/history|predictions|matches/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 업적 페이지 (Achievements)', async ({ page }) => {
        await page.goto('/achievements');

        await expect(page).toHaveURL(/.*achievements/);

        // 업적 뱃지 확인
        await expect(
            page.locator('text=/badge|achievement|unlock/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 리더보드 페이지 (Leaderboard)', async ({ page }) => {
        await page.goto('/leaderboard');

        await expect(page).toHaveURL(/.*leaderboard/);

        // 리더보드 테이블 확인
        await expect(
            page.locator('text=/rank|leaderboard|top/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 감성 분석 페이지 (Sentiment)', async ({ page }) => {
        await page.goto('/sentiment');

        await expect(page).toHaveURL(/.*sentiment/);

        // 감성 차트 확인
        await expect(
            page.locator('text=/sentiment|crowd|analysis/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 보상 페이지 (Rewards)', async ({ page }) => {
        await page.goto('/rewards');

        await expect(page).toHaveURL(/.*rewards/);

        // 보상 정보 확인
        await expect(
            page.locator('text=/reward|tier|season/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 작동 원리 페이지 (How It Works)', async ({ page }) => {
        await page.goto('/how-it-works');

        await expect(page).toHaveURL(/.*how-it-works/);

        // 설명 콘텐츠 확인
        await expect(
            page.locator('text=/how|works|mechanism/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 도움말 페이지 (Help)', async ({ page }) => {
        await page.goto('/help');

        await expect(page).toHaveURL(/.*help/);

        // 도움말 콘텐츠 확인
        await expect(
            page.locator('text=/help|support|faq/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-01: 설정 페이지 (Settings)', async ({ page }) => {
        await page.goto('/settings');

        await expect(page).toHaveURL(/.*settings/);

        // 설정 옵션 확인
        await expect(
            page.locator('text=/settings|preferences|account/i').first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('TC-NAV-02: 미로그인 시 보호된 페이지 리디렉션', async ({ page, context }) => {
        // 로그아웃 후 보호된 페이지 접근 시도
        await context.clearCookies();
        await page.evaluate(() => localStorage.clear());
        await page.reload(); // Ensure state is cleared

        await page.goto('/my-stats');

        // 로그인 페이지로 리디렉션되거나 로그인 다이얼로그 표시
        await page.waitForTimeout(2000);

        const isLoginPage = page.url().includes('/login');
        const hasLoginModal = await page.getByTestId('submit-login').isVisible({ timeout: 3000 });

        expect(isLoginPage || hasLoginModal).toBeTruthy();
    });
});
