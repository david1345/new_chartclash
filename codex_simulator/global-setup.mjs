import { chromium } from '@playwright/test';
import 'dotenv/config';

const BASE_URL = process.env.BASE_URL || 'https://vibe-forecast.vercel.app/';
const EMAIL = process.env.TEST_USER_EMAIL || 'test2@mail.com';
const PASSWORD = process.env.TEST_USER_PASSWORD || '123456';

export default async function globalSetup() {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle').catch(() => null);

  // Try to dismiss blocking tutorial overlays (force-remove if needed)
  await page.evaluate(() => {
    const selectors = [
      '.fixed.inset-0.z-[100]',
      '.fixed.inset-0',
      '[data-testid="tour-overlay"]',
      '[data-testid="onboarding-overlay"]',
      '[data-testid="modal-overlay"]',
      '[data-testid="blocking-overlay"]',
    ];
    selectors.forEach((sel) => {
      document.querySelectorAll(sel).forEach((el) => {
        el.style.pointerEvents = 'none';
        el.remove();
      });
    });
  }).catch(() => null);

  const loginButton = page.getByTestId('login-button');
  if (await loginButton.isVisible({ timeout: 3000 }).catch(() => false)) {
    await loginButton.click({ timeout: 5000 }).catch(async () => {
      // Retry after removing overlays again
      await page.evaluate(() => {
        document.querySelectorAll('.fixed.inset-0.z-[100], .fixed.inset-0').forEach((el) => {
          el.style.pointerEvents = 'none';
          el.remove();
        });
      });
      await loginButton.click({ timeout: 5000 });
    });
    await page.getByTestId('email-input').fill(EMAIL);
    await page.getByTestId('password-input').fill(PASSWORD);
    await page.getByTestId('submit-login').click();
    await page.waitForLoadState('networkidle').catch(() => null);
  }

  await page.context().storageState({ path: new URL('./storageState.json', import.meta.url).pathname });
  await browser.close();
}
