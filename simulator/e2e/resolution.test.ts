import { test, expect } from '@playwright/test';
import { login, selectAsset, selectTimeframe, getPointsBalance } from './helpers';
import { resetTestUser } from './utils';

const TEST_USER_ID = process.env.TEST_USER_ID || '4e902b28-abdd-4626-8ffd-638a02f98f98';

test.describe('Prediction Resolution', () => {
    test.beforeEach(async ({ page, request }) => {
        await resetTestUser(request, TEST_USER_ID);
        await login(page);
    });

    test('Full cycle: Submit 1m prediction and resolve', async ({ page, request }) => {
        await selectAsset(page, 'BTCUSDT');
        await selectTimeframe(page, '1m');

        const initialPoints = await getPointsBalance(page);
        console.log(`Initial points: ${initialPoints}`);

        // 1. Submit Prediction
        await page.getByTestId('btn-up').click();
        await page.getByTestId('target-0.5').click();
        await page.getByTestId('bet-amount-input').fill('100');
        await page.getByTestId('submit-prediction').click();

        await expect(page.getByTestId('prediction-success')).toBeVisible({ timeout: 10000 });

        const afterBetPoints = await getPointsBalance(page);
        expect(afterBetPoints).toBe(initialPoints - 100);

        // 2. Wait for 1m candle to close + buffer
        console.log('Waiting for candle to close (75s)...');
        await page.waitForTimeout(75000);

        // 3. Manually trigger resolution API for faster test
        console.log('Triggering resolution API...');
        const resolveRes = await request.get('/api/resolve');
        const resolveData = await resolveRes.json();
        console.log('Resolve API Response:', resolveData);

        // 4. Verify Resolution in UI
        // Navigate to History or check Notifications
        await page.goto('/match-history');

        // Wait for the status to NOT be pending
        const firstStatus = page.locator('[data-testid^="prediction-status-"]').first();
        await expect(firstStatus).not.toHaveText(/pending/i, { timeout: 30000 });

        const finalPoints = await getPointsBalance(page);
        console.log(`Final points: ${finalPoints}`);

        // Final points should be different from afterBetPoints
        expect(finalPoints).not.toBe(afterBetPoints);
    });
});
