import { expect, test } from '@playwright/test';

test.describe('Production smoke', () => {
    test('home renders the redesigned landing shell', async ({ page, baseURL }) => {
        expect(baseURL).toBeTruthy();

        await page.goto('/', { waitUntil: 'domcontentloaded' });

        await expect(page).toHaveTitle(/ChartClash/i);
        await expect(page.getByText('Signal Deck')).toBeVisible({ timeout: 15000 });
        await expect(page.getByRole('link', { name: /open live docket/i })).toBeVisible({ timeout: 15000 });
        await expect(page.locator('footer')).toContainText('Terms');
    });

    test('battle page exposes the thesis-market layout', async ({ page }) => {
        await page.goto('/play/BTCUSDT/1h', { waitUntil: 'domcontentloaded' });

        await expect(page).toHaveURL(/\/play\/BTCUSDT\/1h/);
        await expect(page.getByText('Decision Board')).toBeVisible({ timeout: 20000 });
        await expect(page.getByText('Long Desk').first()).toBeVisible({ timeout: 20000 });
        await expect(page.getByText('Short Desk').first()).toBeVisible({ timeout: 20000 });
        await expect(page.getByText('Stake Composer')).toBeVisible({ timeout: 20000 });
    });

    test('wallet is reachable and admin remains protected', async ({ page }) => {
        await page.goto('/wallet', { waitUntil: 'domcontentloaded' });

        await expect(page).toHaveURL(/\/wallet/);
        await expect(page.getByText('Contract Balance')).toBeVisible({ timeout: 15000 });
        await expect(
            page.getByRole('button', { name: /connect metamask/i })
                .or(page.getByRole('button', { name: /deposit/i }))
        ).toBeVisible({ timeout: 15000 });

        await page.goto('/admin', { waitUntil: 'domcontentloaded' });
        await page.waitForURL((url) => !url.pathname.startsWith('/admin'), { timeout: 15000 });
        expect(page.url()).not.toContain('/admin');
    });
});
