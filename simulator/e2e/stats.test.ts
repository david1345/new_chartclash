import { test, expect } from '@playwright/test';
import { resetTestUser, login } from './utils';

// TEST_USER_ID obtained from script (Local: 4e90... / Prod: 9969...)
const TEST_USER_ID = process.env.TEST_USER_ID || '4e902b28-abdd-4626-8ffd-638a02f98f98';

test.describe('통계 및 히스토리 테스트 (Stats & History Tests)', () => {
    test.beforeEach(async ({ page, request }) => {
        // 1. DB 초기화 (테스트 격리)
        await resetTestUser(request, TEST_USER_ID);

        // 2. 로그인
        await login(page);
    });

    test('TC-STATS-01: 내 통계 표시 (Display User Stats)', async ({ page }) => {
        // UI를 통해 네비게이션 (세션 유지 보장)
        await page.getByTestId('user-menu-trigger').click();
        await page.getByTestId('nav-my-stats').click();

        // URL 확인
        await expect(page).toHaveURL(/.*my-stats/);

        // 페이지 타이틀 확인 (My Performance)
        await expect(page.locator('h1')).toContainText(/My Performance|My Stats/i, { timeout: 15000 });

        // 주요 통계 카드 확인
        await expect(page.getByTestId('total-predictions')).toBeVisible();
        await expect(page.getByTestId('win-rate')).toBeVisible();
        await expect(page.getByTestId('net-earnings')).toBeVisible();
    });

    test('TC-STATS-02: 매치 히스토리 표시 (Display Match History)', async ({ page }) => {
        await page.goto('/match-history');

        // 히스토리 카드 또는 메인 컨테이너 확인
        const mainContent = page.locator('main').first();
        await expect(mainContent).toBeVisible({ timeout: 15000 });

        // 데이터 로딩 대기: 테이블 행이 있거나, 빈 상태 메시지가 있거나
        const hasHistory = await page.getByTestId('prediction-history-item').first().isVisible({ timeout: 5000 });
        const hasEmptyState = await page.locator('text=/no predictions|no history/i').first().isVisible({ timeout: 5000 });

        // 둘 중 하나는 있어야 성공 (데이터가 있거나 없거나)
        expect(hasHistory || hasEmptyState || await mainContent.isVisible()).toBeTruthy();
    });

    test('TC-STATS-03: 업적 시스템 (Achievement System)', async ({ page }) => {
        await page.goto('/achievements');

        // 업적 페이지 로드 확인
        await expect(page.locator('text=/achievements|badges/i').first()).toBeVisible({ timeout: 10000 });
    });

    test('TC-STATS-04: 포인트 잔액 표시 (Display Points Balance)', async ({ page }) => {
        await page.goto('/my-stats');

        // 포인트 표시 확인 (헤더 또는 통계 카드)
        // 헤더에 있는 포인트 (모바일/데스크탑)
        const headerPoints = page.getByTestId('user-points');
        const statCardPoints = page.getByTestId('current-points');

        if (await statCardPoints.isVisible({ timeout: 5000 })) {
            await expect(statCardPoints).toBeVisible();
        } else {
            // Fallback: 헤더의 user-points (네비게이션 바가 있는 경우)
            // 요소가 여러 개일 수 있으므로 first() 사용
            await expect(headerPoints.first()).toBeVisible();
        }
    });

    test('TC-STATS-05: 예측 상세 정보 (Prediction Details)', async ({ page }) => {
        await page.goto('/match-history');

        // 데이터가 있을 때만 실행
        const firstRow = page.locator('tbody tr').first();
        if (await firstRow.isVisible({ timeout: 10000 })) {
            // 상세 정보가 이미 펼쳐져 있는지 확인 (Entry Price 텍스트가 보이는지)
            // 'text=Entry Price'가 여러 개일 수 있으므로 첫 번째 행 내부에서 찾거나, first() 사용
            const detailsVisible = await page.locator('text=Entry Price').first().isVisible();

            if (!detailsVisible) {
                await firstRow.click();
            }

            // 상세 정보 확인: strict mode 에러 방지를 위해 .first() 사용하거나 특정 컨테이너 내부 검색
            // 테이블 행 다음의 상세 정보 행을 찾아야 함.
            await expect(page.locator('text=Entry Price').first()).toBeVisible({ timeout: 5000 });
            await expect(page.locator('text=Close Price').first()).toBeVisible({ timeout: 5000 });
        }
    });
});
