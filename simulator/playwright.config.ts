import { defineConfig, devices } from '@playwright/test';

// 날짜별 결과 디렉토리 생성
const getResultDir = () => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hour = String(now.getHours()).padStart(2, '0');
    const minute = String(now.getMinutes()).padStart(2, '0');

    const prefix = process.env.TEST_ENV === 'production' ? 'prod_' : '';
    return `./result/${prefix}${year}-${month}-${day}_${hour}-${minute}`;
};

const resultDir = getResultDir();

export default defineConfig({
    testDir: './e2e',
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,

    // 테스트 결과를 날짜별 디렉토리에 저장
    outputDir: `${resultDir}/test-artifacts`,

    reporter: process.env.CI ? [
        ['html', { outputFolder: `${resultDir}/html-report` }],
        ['json', { outputFile: `${resultDir}/test-results.json` }]
    ] : [
        ['html', { outputFolder: `${resultDir}/html-report` }],
        ['list']
    ],

    timeout: 30000, // 30초 (개별 테스트)
    expect: {
        timeout: 10000, // 10초 (assertion)
    },

    use: {
        baseURL: process.env.BASE_URL || 'http://localhost:3000',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
        actionTimeout: 15000, // 15초 (액션)

        // 스크린샷과 비디오를 결과 디렉토리에 저장
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

    webServer: {
        command: 'npm run dev',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
        timeout: 120000, // 2분 (서버 시작)
        cwd: '..',  // 프로젝트 루트에서 실행
    },
});
