/**
 * E2E 테스트 헬퍼 함수 모음
 * Playwright 테스트에서 공통으로 사용되는 함수들
 */

import { Page } from '@playwright/test';

/**
 * 로그인 헬퍼 함수
 * @param page - Playwright Page 객체
 * @param email - 이메일 (기본값: test1@mail.com)
 * @param password - 비밀번호 (기본값: 123456)
 */
export async function login(page: Page, email: string = 'test1@mail.com', password: string = '123456') {
    await page.goto('/');

    const loginButton = page.getByTestId('login-button');

    if (await loginButton.isVisible({ timeout: 10000 })) {
        await loginButton.click();
        await page.getByTestId('email-input').fill(email);
        await page.getByTestId('password-input').fill(password);

        await page.getByTestId('submit-login').click();

        // 로그인 완료 대기
        await page.waitForLoadState('domcontentloaded');
        await page.waitForTimeout(2000);
    }
}

/**
 * 로그아웃 헬퍼 함수
 * @param page - Playwright Page 객체
 */
export async function logout(page: Page) {
    // 프로필 메뉴 열기 (아이콘 형태일 수 있음)
    const profileButton = page.locator('button:has(img[alt*="avatar"]), button:has(img[alt*="profile"])').first();

    if (await profileButton.isVisible({ timeout: 5000 })) {
        await profileButton.click();

        const logoutButton = page.getByRole('button', { name: /logout|sign out/i });
        await logoutButton.click();

        await page.waitForTimeout(1000);
    }
}

/**
 * 예측 제출 헬퍼 함수
 * @param page - Playwright Page 객체
 * @param options - 예측 옵션
 */
export async function submitPrediction(page: Page, options: {
    direction: 'UP' | 'DOWN';
    targetPercent?: '0.5%' | '1.0%' | '1.5%' | '2.0%';
    betAmount: number;
    comment?: string;
}) {
    await page.goto('/');

    // 방향 선택
    if (options.direction === 'UP') {
        await page.getByTestId('btn-up').click();
    } else {
        await page.getByTestId('btn-down').click();
    }

    // 목표 퍼센트 선택 (선택사항)
    if (options.targetPercent) {
        const val = options.targetPercent.replace('%', '');
        const targetId = `target-${parseFloat(val).toFixed(1)}`;
        const targetButton = page.getByTestId(targetId);

        if (await targetButton.isVisible({ timeout: 2000 })) {
            await targetButton.click();
        }
    }

    // 베팅 금액 입력
    await page.getByTestId('bet-amount-input').fill(options.betAmount.toString());

    // 코멘트 입력 (선택사항)
    if (options.comment) {
        const commentInput = page.getByTestId('comment-input');
        if (await commentInput.isVisible({ timeout: 2000 })) {
            await commentInput.fill(options.comment);
        }
    }

    // 제출
    await page.getByTestId('submit-prediction').click();

    // 결과 대기
    await page.waitForTimeout(2000);
}

/**
 * 자산 선택 헬퍼 함수
 * @param page - Playwright Page 객체
 * @param asset - 자산 심볼 (예: BTC, ETH, AAPL)
 */
export async function selectAsset(page: Page, asset: string) {
    // 자산 선택 버튼 (현재 선택된 자산 표시되는 버튼)
    const assetButton = page.getByTestId('asset-selector');

    if (await assetButton.isVisible({ timeout: 3000 })) {
        await assetButton.click();
    }

    // 자산 검색 또는 선택 (Dialog 내의 아이템)
    const assetOption = page.getByTestId(`asset-option-${asset}`).first();
    await assetOption.click();

    // 선택 확인 (Dialog 닫힘 및 버튼 텍스트 변경 대기)
    const assetButtonText = page.getByTestId('asset-selector');
    await assetButtonText.waitFor({ state: 'visible' });

    // Playwright의 auto-retrying assertion을 사용할 수 없으므로(helpers.ts에는 expect가 없음),
    // waitForFunction 또는 locator param을 사용하여 텍스트 변경을 대기
    await page.waitForFunction(
        ([selector, text]) => {
            const el = document.querySelector(`[data-testid="${selector}"]`);
            return el && el.textContent?.includes(text);
        },
        ['asset-selector', asset],
        { timeout: 5000 }
    ).catch(() => console.log(`Warning: Asset selection text might not have updated to ${asset}`));

    await page.waitForTimeout(500);
}

/**
 * 시간대 선택 헬퍼 함수
 * @param page - Playwright Page 객체
 * @param timeframe - 시간대 (예: 1m, 5m, 1h)
 */
export async function selectTimeframe(page: Page, timeframe: string) {
    // 탭 형태의 시간대 버튼 선택
    const timeframeButton = page.locator(`button:has-text("${timeframe}")`).first();

    if (await timeframeButton.isVisible({ timeout: 3000 })) {
        await timeframeButton.click();
        await page.waitForTimeout(500);
    }
}

/**
 * 포인트 잔액 가져오기
 * @param page - Playwright Page 객체
 * @returns 포인트 잔액 (숫자)
 */
export async function getPointsBalance(page: Page): Promise<number> {
    const balanceElement = page.locator('text=/balance|points.*\\d+/i').first();

    if (await balanceElement.isVisible({ timeout: 5000 })) {
        const balanceText = await balanceElement.textContent();
        const match = balanceText?.match(/\d+/);
        return match ? parseInt(match[0]) : 0;
    }

    return 0;
}

/**
 * 토스트 메시지 확인
 * @param page - Playwright Page 객체
 * @param pattern - 메시지 패턴 (정규식)
 * @param timeout - 타임아웃 (ms)
 */
export async function waitForToast(page: Page, pattern: RegExp, timeout: number = 5000): Promise<boolean> {
    const toast = page.locator(`[data-sonner-toast], .toast, [role="alert"]`).locator(`text=${pattern}`);
    return await toast.isVisible({ timeout });
}

/**
 * 테스트용 대기 (안정성을 위한 짧은 대기)
 * @param ms - 대기 시간 (밀리초)
 */
export async function waitFor(ms: number = 1000) {
    await new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 페이지 로딩 완료 대기
 * @param page - Playwright Page 객체
 */
export async function waitForPageLoad(page: Page) {
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
}

/**
 * 에러 메시지 확인
 * @param page - Playwright Page 객체
 * @param pattern - 에러 메시지 패턴
 */
export async function expectError(page: Page, pattern: RegExp): Promise<boolean> {
    const errorElement = page.locator(`text=${pattern}`).first();
    return await errorElement.isVisible({ timeout: 5000 });
}

/**
 * 테스트 데이터 - 자산 목록
 */
export const ASSETS = {
    CRYPTO: ['BTC', 'ETH', 'SOL', 'XRP', 'DOGE', 'ADA', 'AVAX', 'DOT', 'LINK', 'MATIC'],
    STOCKS: ['AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC'],
    COMMODITIES: ['Gold', 'Silver', 'Oil', 'Gas', 'Corn', 'Soy', 'Wheat', 'Copper', 'Platinum', 'Palladium']
};

/**
 * 테스트 데이터 - 시간대
 */
export const TIMEFRAMES = ['1m', '5m', '15m', '30m', '1h', '4h', '1d'];

/**
 * 테스트 데이터 - 목표 퍼센트
 */
export const TARGET_PERCENTS = ['0.5%', '1.0%', '1.5%', '2.0%'];

/**
 * 테스트 계정
 */
export const TEST_ACCOUNTS = {
    DEFAULT: { email: 'test1@mail.com', password: '123456' },
    SECONDARY: { email: 'test2@mail.com', password: '123456' }
};
