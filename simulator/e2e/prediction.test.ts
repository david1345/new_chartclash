import { test, expect } from '@playwright/test';
import { selectAsset } from './helpers';
import { login, resetTestUser } from './utils';


// TEST_USER_ID obtained from script
const TEST_USER_ID = process.env.TEST_USER_ID || 'bd6880d7-c00d-44d8-abf8-832aeca7bd31';

test.describe('Prediction Submission', () => {
  test.beforeEach(async ({ page, request }) => {
    // 1. DB 초기화 (테스트 격리)
    await resetTestUser(request, TEST_USER_ID);

    await login(page);
    await selectAsset(page, 'SOLUSDT');
  });

  test('Submit UP prediction', async ({ page }) => {
    await selectAsset(page, 'SOLUSDT');
    await page.getByTestId('btn-up').click();
    await page.getByTestId('target-0.5').click();
    await page.getByTestId('bet-amount-input').fill('50');
    await page.getByTestId('submit-prediction').click();

    await expect(page.getByTestId('prediction-success')).toBeVisible({ timeout: 10000 });
  });

  test('Submit DOWN prediction', async ({ page }) => {
    await selectAsset(page, 'XRPUSDT');
    await page.getByTestId('btn-down').click();
    await page.getByTestId('target-1.0').click();
    await page.getByTestId('bet-amount-input').fill('100');
    await page.getByTestId('submit-prediction').click();

    await expect(page.getByTestId('prediction-success')).toBeVisible({ timeout: 10000 });
  });

  test('Minimum bet validation', async ({ page }) => {
    await selectAsset(page, 'DOGEUSDT');
    await page.getByTestId('btn-up').click();
    await page.getByTestId('target-0.5').click();
    await page.getByTestId('bet-amount-input').fill('5');
    await page.getByTestId('submit-prediction').click();

    await expect(page.getByTestId('error-min-bet')).toBeVisible({ timeout: 5000 });
  });

  test('Maximum bet validation', async ({ page }) => {
    await selectAsset(page, 'ADAUSDT');
    await page.getByTestId('btn-up').click();
    await page.getByTestId('target-0.5').click();
    await page.getByTestId('bet-amount-input').fill('500');
    await page.getByTestId('submit-prediction').click();

    await expect(page.getByTestId('error-max-bet')).toBeVisible({ timeout: 5000 });
  });



  test('Add comment to prediction', async ({ page }) => {
    await selectAsset(page, 'DOTUSDT');
    await page.getByTestId('btn-up').click();
    await page.getByTestId('target-0.5').click();
    await page.getByTestId('comment-input').fill('Strong bullish momentum!');
    await page.getByTestId('bet-amount-input').fill('50');
    await page.getByTestId('submit-prediction').click();

    await expect(page.getByTestId('prediction-success')).toBeVisible({ timeout: 10000 });
  });
});
