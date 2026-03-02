import { test, expect } from '@playwright/test';
import { login } from './helpers';

test.describe('Internal Feedback System', () => {
    test.beforeEach(async ({ page }) => {
        await login(page);
    });

    test('Submit feedback successfully', async ({ page }) => {
        // 1. Open Feedback Dialog
        await page.getByRole('button', { name: /support/i }).first().click();
        await expect(page.getByText(/submit feedback/i)).toBeVisible();

        // 2. Fill Form
        await page.selectOption('select', 'suggestion'); // Adjust selector if needed
        await page.getByPlaceholder(/describe your feedback/i).fill('This is an automated test feedback.');

        // 3. Submit
        await page.getByRole('button', { name: /send feedback/i }).click();

        // 4. Verify Success Toast
        await expect(page.getByText(/feedback sent successfully/i)).toBeVisible({ timeout: 10000 });
    });

    test('Feedback validation - empty message', async ({ page }) => {
        await page.getByRole('button', { name: /support/i }).first().click();

        // Try to submit empty
        const submitBtn = page.getByRole('button', { name: /send feedback/i });
        await expect(submitBtn).toBeDisabled();
    });
});
