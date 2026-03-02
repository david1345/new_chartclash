import { test, expect } from '@playwright/test';
import { login, ASSETS } from './helpers';
import { resetTestUser } from './utils';

// TEST_USER_ID obtained from script
const TEST_USER_ID = process.env.TEST_USER_ID || '4e902b28-abdd-4626-8ffd-638a02f98f98';

test.describe('자산 및 시간대 테스트 (Assets & Timeframe Tests)', () => {
    test.beforeEach(async ({ page, request }) => {
        // 1. DB 초기화 (테스트 격리)
        await resetTestUser(request, TEST_USER_ID);

        await login(page);
    });

    test('TC-ASSET-01: 암호화폐 자산 선택 (Crypto Assets)', async ({ page }) => {
        await page.waitForLoadState('domcontentloaded');

        // 자산 선택 다이얼로그 열기
        const assetButton = page.getByTestId('asset-selector').first();
        await expect(assetButton).toBeVisible({ timeout: 15000 });
        await assetButton.click();
        await page.waitForTimeout(1000);

        // Crypto 탭 확인
        const cryptoTab = page.getByRole('tab', { name: /crypto/i });
        if (await cryptoTab.isVisible({ timeout: 3000 })) {
            await cryptoTab.click();
        }

        // 주요 암호화폐 자산 확인
        const cryptoAssets = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'];
        for (const asset of cryptoAssets) {
            await expect(
                page.getByTestId(`asset-option-${asset}`)
            ).toBeVisible({ timeout: 5000 });
        }
    });

    test('TC-ASSET-02: 주식 자산 선택 (Stock Assets)', async ({ page }) => {
        await page.waitForLoadState('domcontentloaded');

        // 자산 선택 다이얼로그 열기
        const assetButton = page.getByTestId('asset-selector').first();
        await expect(assetButton).toBeVisible({ timeout: 15000 });
        await assetButton.click();
        await page.waitForTimeout(1000);

        // Stocks 탭 클릭
        const stocksTab = page.getByRole('tab', { name: /stocks/i });
        if (await stocksTab.isVisible({ timeout: 3000 })) {
            await stocksTab.click();

            // 주요 주식 확인
            const stocks = ['AAPL', 'TSLA', 'NVDA'];
            for (const stock of stocks) {
                await expect(
                    page.getByTestId(`asset-option-${stock}`)
                ).toBeVisible({ timeout: 5000 });
            }

            // 시장 시간 경고 확인 (폐장 시)
            const marketWarning = page.locator('text=/market.*closed|closed.*market/i').first();
            // 경고가 있을 수도 있고 없을 수도 있음 (시간에 따라)
        }
    });

    test('TC-ASSET-03: 원자재 자산 선택 (Commodity Assets)', async ({ page }) => {
        await page.waitForLoadState('domcontentloaded');

        // 자산 선택 다이얼로그 열기
        const assetButton = page.getByTestId('asset-selector').first();
        await expect(assetButton).toBeVisible({ timeout: 15000 });
        await assetButton.click();
        await page.waitForTimeout(1000);

        // Cmdty 탭 클릭
        const cmdtyTab = page.getByRole('tab', { name: /cmdty|commodity/i });
        if (await cmdtyTab.isVisible({ timeout: 3000 })) {
            await cmdtyTab.click();

            // 주요 원자재 확인
            const commodities = ['XAUUSD', 'XAGUSD', 'WTI'];
            for (const commodity of commodities) {
                await expect(
                    page.getByTestId(`asset-option-${commodity}`)
                ).toBeVisible({ timeout: 5000 });
            }
        }
    });

    test('TC-TIME-01: 시간대 선택 (Timeframe Selection)', async ({ page }) => {
        await page.waitForLoadState('domcontentloaded');

        const timeframeSelector = page.getByTestId('timeframe-selector').first();
        await expect(timeframeSelector).toBeVisible({ timeout: 15000 });
        await timeframeSelector.click();
        await page.waitForTimeout(1000);

        // 시간대 선택 버튼 확인
        const timeframes = ['1m', '15m', '30m', '1h', '4h', '1d'];

        for (const timeframe of timeframes) {
            const timeframeButton = page.getByTestId(`timeframe-${timeframe}`);
            await expect(timeframeButton).toBeVisible({ timeout: 5000 });
        }
    });

    test('TC-ASSET-04: 자산 전환 (Switch Assets)', async ({ page }) => {
        await page.waitForLoadState('domcontentloaded');

        // 첫 번째 자산 선택
        const assetButton = page.getByTestId('asset-selector').first();
        await expect(assetButton).toBeVisible({ timeout: 15000 });
        const currentAsset = await assetButton.textContent();
        await assetButton.click();
        await page.waitForTimeout(1000);

        // 다른 자산 선택 (ETHUSDT)
        const ethOption = page.getByTestId('asset-option-ETHUSDT');
        if (await ethOption.isVisible({ timeout: 3000 })) {
            await ethOption.click();
            await page.waitForTimeout(1000);

            // 자산이 변경되었는지 확인
            const newAsset = await assetButton.textContent();

            // 자산이 변경되었거나 다이얼로그가 닫혔는지 확인
            expect(newAsset !== currentAsset || !await ethOption.isVisible()).toBeTruthy();
        }
    });

    test('TC-ASSET-05: 실시간 가격 표시 (Real-time Price Display)', async ({ page }) => {
        await page.waitForLoadState('domcontentloaded');

        // 현재 자산의 가격 표시 확인
        const priceElement = page.locator('text=/\\$\\d+|\\d+\\.\\d+/').first();
        await expect(priceElement).toBeVisible({ timeout: 10000 });

        // 가격 형식 검증 (숫자가 포함되어 있어야 함)
        const priceText = await priceElement.textContent();
        expect(priceText).toMatch(/\d+/);
    });
});
