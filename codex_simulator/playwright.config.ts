import { defineConfig, devices } from '@playwright/test';

const getResultDir = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hour = String(now.getHours()).padStart(2, '0');
  const minute = String(now.getMinutes()).padStart(2, '0');
  const prefix = process.env.TEST_ENV === 'production' ? 'prod_' : '';
  return `../codex_result/${prefix}${year}-${month}-${day}_${hour}-${minute}`;
};

const resultDir = getResultDir();

export default defineConfig({
  testDir: './e2e',
  globalSetup: './global-setup.mjs',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 2,

  outputDir: `${resultDir}/test-artifacts`,

  reporter: process.env.CI
    ? [
        ['html', { outputFolder: `${resultDir}/html-report` }],
        ['json', { outputFile: `${resultDir}/test-results.json` }],
      ]
    : [
        ['html', { outputFolder: `${resultDir}/html-report` }],
        ['list'],
      ],

  timeout: 30000,
  expect: {
    timeout: 10000,
  },

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    storageState: './storageState.json',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15000,
    contextOptions: {
      recordVideo: {
        dir: `${resultDir}/videos`,
      },
    },
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: process.env.TEST_ENV === 'production'
    ? undefined
    : {
        command: 'npm run dev',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
        timeout: 120000,
        cwd: '..',
      },
});
