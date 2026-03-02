import { test, expect } from '@playwright/test';

test.describe('인증 테스트 (Authentication Tests)', () => {
    test('TC-AUTH-01: 로그인 성공 (Successful Login)', async ({ page }) => {
        await page.goto('/');

        // 로그인 버튼 찾기
        const loginButton = page.getByTestId('login-button');

        if (await loginButton.isVisible({ timeout: 5000 })) {
            await loginButton.click();

            // 이메일과 비밀번호 입력
            await page.getByTestId('email-input').fill('test1@mail.com');
            await page.getByTestId('password-input').fill('123456');

            // 로그인 제출
            await page.getByTestId('submit-login').click();

            // 로그인 성공 검증 - 포인트 표시 확인
            await expect(
                page.getByTestId('user-points')
            ).toBeVisible({ timeout: 10000 });
        }
    });

    test('TC-AUTH-02: 로그인 실패 (Login Failure)', async ({ page }) => {
        await page.goto('/login');

        // 잘못된 자격증명으로 로그인 시도
        await page.getByTestId('email-input').fill('wrong@mail.com');
        await page.getByTestId('password-input').fill('wrongpassword');

        await page.getByTestId('submit-login').click();

        // 에러 메시지 확인
        await expect(
            page.locator('text=/invalid|error|wrong|failed/i').first()
        ).toBeVisible({ timeout: 5000 });
    });

    test('TC-AUTH-03: 로그아웃 (Logout)', async ({ page, context }) => {
        // 먼저 로그인
        await page.goto('/login');
        await page.getByTestId('email-input').fill('test1@mail.com');
        await page.getByTestId('password-input').fill('123456');
        await page.getByTestId('submit-login').click();
        await page.waitForTimeout(2000);

        // 프로필 메뉴 열기 (Selector based on element type since testid not added to profile icon yet)
        const profileButton = page.locator('button:has(img[alt*="avatar"]), button:has(img[alt*="profile"])').first();
        if (await profileButton.isVisible({ timeout: 5000 })) {
            await profileButton.click();

            // 로그아웃 버튼 클릭
            const logoutButton = page.getByRole('button', { name: /logout|sign out/i });
            await logoutButton.click();

            // 로그인 페이지로 리디렉션 확인
            await page.waitForTimeout(1000);
            await expect(
                page.getByTestId('login-button').or(page.getByTestId('submit-login'))
            ).toBeVisible({ timeout: 5000 });
        }
    });
});
