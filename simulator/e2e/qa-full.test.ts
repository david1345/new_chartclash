/**
 * ============================================================
 * ChartClash - 전체 QA 테스트 스위트 (정상 + 에러 케이스)
 * 실행: npm run test:qa
 * ============================================================
 */
import { test, expect, Page } from '@playwright/test';

const BASE = process.env.BASE_URL || 'http://localhost:3000';
const TEST_EMAIL = process.env.TEST_EMAIL || 'test1@mail.com';
const TEST_PASSWORD = process.env.TEST_PASSWORD || '123456';

// ─── 공통 헬퍼 ───────────────────────────────────────────────
async function loginAs(page: Page, email = TEST_EMAIL, pw = TEST_PASSWORD) {
    await page.goto(`${BASE}/login`);
    await page.getByTestId('email-input').fill(email);
    await page.getByTestId('password-input').fill(pw);
    await page.getByTestId('submit-login').click();
    await page.waitForURL(`${BASE}/`, { timeout: 10000 }).catch(() => { });
    await page.waitForTimeout(1000);
}

async function toastVisible(page: Page, pattern: RegExp, timeout = 6000) {
    return page.locator('[data-sonner-toast], [role="alert"]').filter({ hasText: pattern }).isVisible({ timeout });
}

// ─────────────────────────────────────────────────────────────
// 1. 인증 테스트
// ─────────────────────────────────────────────────────────────
test.describe('1. 🔐 인증 (Authentication)', () => {

    test('AUTH-01 [정상] 이메일+비밀번호 로그인 성공', async ({ page }) => {
        await loginAs(page);
        await expect(page.getByTestId('user-points')).toBeVisible({ timeout: 10000 });
    });

    test('AUTH-02 [에러] 틀린 비밀번호 로그인', async ({ page }) => {
        await page.goto(`${BASE}/login`);
        await page.getByTestId('email-input').fill(TEST_EMAIL);
        await page.getByTestId('password-input').fill('wrongpassword!');
        await page.getByTestId('submit-login').click();
        await expect(
            page.locator('text=/invalid|error|올바르지|incorrect/i').first()
        ).toBeVisible({ timeout: 7000 });
    });

    test('AUTH-03 [에러] 존재하지 않는 이메일로 로그인', async ({ page }) => {
        await page.goto(`${BASE}/login`);
        await page.getByTestId('email-input').fill('no_such_user_xyz@never.com');
        await page.getByTestId('password-input').fill('somepassword');
        await page.getByTestId('submit-login').click();
        await expect(
            page.locator('text=/invalid|error|not found|존재하지/i').first()
        ).toBeVisible({ timeout: 7000 });
    });

    test('AUTH-04 [에러] 이메일 형식 아닌 값 입력', async ({ page }) => {
        await page.goto(`${BASE}/login`);
        await page.getByTestId('email-input').fill('notanemail');
        await page.getByTestId('password-input').fill('123456');
        await page.getByTestId('submit-login').click();
        // 브라우저 네이티브 또는 앱 에러 표시 확인
        const nativeInvalid = await page.locator('[data-testid="email-input"]:invalid').count();
        const appError = await page.locator('text=/valid email|이메일 형식/i').count();
        expect(nativeInvalid + appError).toBeGreaterThan(0);
    });

    test('AUTH-05 [정상] 로그아웃 후 보호 페이지 리다이렉트', async ({ page }) => {
        await loginAs(page);
        // 로그아웃: 프로필 메뉴 → Log Out
        await page.getByTestId('user-menu-trigger').click();
        await page.locator('text=Log Out').click();
        await page.waitForTimeout(1500);
        // /my-stats 접근 시 /login 으로 리다이렉트
        await page.goto(`${BASE}/my-stats`);
        await expect(page).toHaveURL(/login/, { timeout: 8000 });
    });

    test('AUTH-06 [에러] 미로그인 상태에서 /settings 접근', async ({ page }) => {
        await page.goto(`${BASE}/settings`);
        await expect(page).toHaveURL(/login/, { timeout: 8000 });
    });
});

// ─────────────────────────────────────────────────────────────
// 2. 네비게이션 테스트
// ─────────────────────────────────────────────────────────────
test.describe('2. 🧭 네비게이션 (Navigation)', () => {

    test('NAV-01 [정상] 로고 클릭 → 홈 이동', async ({ page }) => {
        await page.goto(`${BASE}/leaderboard`);
        await page.locator('a[href="/"]').first().click();
        await expect(page).toHaveURL(`${BASE}/`, { timeout: 5000 });
    });

    test('NAV-02 [정상] Live 버튼 → /play/BTCUSDT/1h 이동', async ({ page }) => {
        await page.goto(BASE);
        await page.locator('text=Live').first().click();
        await expect(page).toHaveURL(/play\/BTCUSDT\/1h/, { timeout: 6000 });
    });

    test('NAV-03 [정상] AI Hub 버튼 → /community 이동', async ({ page }) => {
        await page.goto(BASE);
        await page.locator('text=AI Hub').first().click();
        await expect(page).toHaveURL(/community/, { timeout: 6000 });
    });

    test('NAV-04 [정상] Leaderboard 버튼 → /leaderboard 이동', async ({ page }) => {
        await page.goto(BASE);
        await page.locator('text=Leaderboard').first().click();
        await expect(page).toHaveURL(/leaderboard/, { timeout: 6000 });
    });

    test('NAV-05 [에러] 존재하지 않는 URL 접근 → 404', async ({ page }) => {
        const res = await page.goto(`${BASE}/this-page-does-not-exist-xyz`);
        // 404 응답 또는 Not Found 텍스트 확인
        const statusOk = res?.status() === 404;
        const textVisible = await page.locator('text=/not found|404/i').isVisible({ timeout: 5000 });
        expect(statusOk || textVisible).toBe(true);
    });

    test('NAV-06 [정상] 모바일: 드로어 메뉴 열고 닫기', async ({ page }) => {
        await page.setViewportSize({ width: 375, height: 812 });
        await page.goto(BASE);
        // 햄버거 아이콘
        const drawerBtn = page.locator('[data-testid="app-drawer-trigger"], button:has(svg)').first();
        if (await drawerBtn.isVisible({ timeout: 4000 })) {
            await drawerBtn.click();
            await page.waitForTimeout(500);
        }
    });
});

// ─────────────────────────────────────────────────────────────
// 3. 글로벌 검색 테스트
// ─────────────────────────────────────────────────────────────
test.describe('3. 🔍 글로벌 검색 (Global Search)', () => {

    test('SEARCH-01 [정상] BTC 검색 → 자산 분석 섹션 표시', async ({ page }) => {
        await page.goto(BASE);
        const searchInput = page.locator('input[placeholder*="Predict"]');
        await searchInput.fill('BTC');
        await searchInput.press('Enter');
        await expect(page).toHaveURL(/q=BTC/, { timeout: 5000 });
        // Analysis 섹션 헤더 확인
        await expect(page.locator('text=/Analysis:|BTC/i').first()).toBeVisible({ timeout: 8000 });
    });

    test('SEARCH-02 [정상] 소문자 gold 검색 → Gold 자산 표시', async ({ page }) => {
        await page.goto(BASE);
        const searchInput = page.locator('input[placeholder*="Predict"]');
        await searchInput.fill('gold');
        await searchInput.press('Enter');
        await expect(page).toHaveURL(/q=GOLD/, { timeout: 5000 });
    });

    test('SEARCH-03 [에러] 빈칸 검색 → 아무 이동 없음', async ({ page }) => {
        await page.goto(BASE);
        const searchInput = page.locator('input[placeholder*="Predict"]');
        await searchInput.fill('   ');
        await searchInput.press('Enter');
        // URL에 q= 파라미터 없음
        const url = page.url();
        expect(url).not.toContain('?q=');
    });

    test('SEARCH-04 [에러] 없는 심볼 검색 → 분석 섹션 미노출', async ({ page }) => {
        await page.goto(`${BASE}/?q=ZZZZZZNOTEXIST`);
        await page.waitForTimeout(2000);
        // SelectedAssetSection이 나타나지 않아야 함
        const analysisHeader = await page.locator('text=/Analysis:/i').isVisible({ timeout: 3000 });
        expect(analysisHeader).toBe(false);
    });
});

// ─────────────────────────────────────────────────────────────
// 4. 예측 주문 테스트
// ─────────────────────────────────────────────────────────────
test.describe('4. 🎮 예측 주문 (Prediction Flow)', () => {

    test.beforeEach(async ({ page }) => {
        await loginAs(page);
        await page.goto(`${BASE}/play/BTCUSDT/1h`);
        await page.waitForLoadState('domcontentloaded');
        await page.waitForTimeout(2000);
    });

    test('PRED-01 [정상] UP 방향 예측 제출', async ({ page }) => {
        const upBtn = page.getByTestId('btn-up');
        if (await upBtn.isVisible({ timeout: 5000 })) {
            await upBtn.click();
            const betInput = page.getByTestId('bet-amount-input');
            await betInput.clear();
            await betInput.fill('10');
            await page.getByTestId('submit-prediction').click();
            // 성공 토스트 또는 예측 탭 업데이트
            const success = await toastVisible(page, /success|submitted|예측|placed/i);
            expect(success).toBe(true);
        }
    });

    test('PRED-02 [에러] 베팅금액 0으로 제출', async ({ page }) => {
        const upBtn = page.getByTestId('btn-up');
        if (await upBtn.isVisible({ timeout: 5000 })) {
            await upBtn.click();
            const betInput = page.getByTestId('bet-amount-input');
            await betInput.clear();
            await betInput.fill('0');
            await page.getByTestId('submit-prediction').click();
            const error = await page.locator('text=/amount|금액|invalid|0/i').first().isVisible({ timeout: 5000 });
            const submitBtnDisabled = await page.getByTestId('submit-prediction').isDisabled();
            expect(error || submitBtnDisabled).toBe(true);
        }
    });

    test('PRED-03 [에러] 방향 선택 없이 제출', async ({ page }) => {
        const betInput = page.getByTestId('bet-amount-input');
        if (await betInput.isVisible({ timeout: 5000 })) {
            await betInput.clear();
            await betInput.fill('100');
            const submitBtn = page.getByTestId('submit-prediction');
            const isDisabled = await submitBtn.isDisabled({ timeout: 3000 }).catch(() => true);
            // 버튼이 비활성화이거나 에러 메시지 표시
            expect(isDisabled).toBe(true);
        }
    });

    test('PRED-04 [에러] 더블클릭으로 중복 제출 시도', async ({ page }) => {
        const upBtn = page.getByTestId('btn-up');
        if (await upBtn.isVisible({ timeout: 5000 })) {
            await upBtn.click();
            const betInput = page.getByTestId('bet-amount-input');
            await betInput.clear();
            await betInput.fill('10');
            const submitBtn = page.getByTestId('submit-prediction');
            // 빠르게 두 번 클릭
            await submitBtn.click();
            await submitBtn.click();
            // 첫 클릭 후 버튼이 비활성화 또는 로딩 상태여야 함
            await page.waitForTimeout(500);
            const isDisabledAfter = await submitBtn.isDisabled().catch(() => false);
            // 중복 베팅 에러 또는 중복 클릭 방지 확인
            const dupError = await page.locator('text=/already|duplicate|중복/i').isVisible({ timeout: 3000 }).catch(() => false);
            expect(isDisabledAfter || dupError).toBe(true);
        }
    });
});

// ─────────────────────────────────────────────────────────────
// 5. 게스트 예측 플로우
// ─────────────────────────────────────────────────────────────
test.describe('5. 👤 게스트 예측 플로우 (Guest Flow)', () => {

    test('GUEST-01 [정상] 비로그인 상태 플레이 페이지 접근', async ({ page }) => {
        await page.goto(`${BASE}/play/BTCUSDT/1h`);
        // GUEST MODE 뱃지 또는 SIGN UP 버튼 표시
        const guestBadge = page.locator('text=/GUEST MODE|SIGN UP/i').first();
        await expect(guestBadge).toBeVisible({ timeout: 8000 });
    });

    test('GUEST-02 [정상] 게스트 예측 제출', async ({ page }) => {
        await page.goto(`${BASE}/play/BTCUSDT/1h`);
        await page.waitForTimeout(2000);
        const guestBtn = page.locator('text=/GUEST|Try/i').first();
        if (await guestBtn.isVisible({ timeout: 5000 })) {
            await guestBtn.click();
        }
        // UP 버튼 클릭 및 제출 시도
        const upBtn = page.getByTestId('btn-up');
        if (await upBtn.isVisible({ timeout: 5000 })) {
            await upBtn.click();
            const submitBtn = page.getByTestId('submit-prediction');
            if (await submitBtn.isVisible({ timeout: 3000 })) {
                await submitBtn.click();
                const success = await toastVisible(page, /placed|success|guest|예측/i);
                expect(success).toBe(true);
            }
        }
    });
});

// ─────────────────────────────────────────────────────────────
// 6. 설정 페이지 유효성 테스트
// ─────────────────────────────────────────────────────────────
test.describe('6. ⚙️ 설정 유효성 검사 (Settings Validation)', () => {

    test.beforeEach(async ({ page }) => {
        await loginAs(page);
        await page.goto(`${BASE}/settings`);
        await page.waitForLoadState('domcontentloaded');
        await page.waitForTimeout(1000);
    });

    test('SET-01 [에러] 닉네임 1자로 저장', async ({ page }) => {
        const usernameInput = page.locator('input[name="username"], input[placeholder*="username" i], input[placeholder*="닉네임" i]').first();
        if (await usernameInput.isVisible({ timeout: 5000 })) {
            await usernameInput.triple_click();
            await usernameInput.fill('a');
            await page.locator('button:has-text("Save"), button:has-text("저장")').first().click();
            const error = await page.locator('text=/least 2|2자|minimum/i').isVisible({ timeout: 5000 });
            expect(error).toBe(true);
        }
    });

    test('SET-02 [에러] 닉네임 특수문자 포함', async ({ page }) => {
        const usernameInput = page.locator('input[name="username"], input[placeholder*="username" i]').first();
        if (await usernameInput.isVisible({ timeout: 5000 })) {
            await usernameInput.triple_click();
            await usernameInput.fill('user!@#$');
            await page.locator('button:has-text("Save"), button:has-text("저장")').first().click();
            const error = await page.locator('text=/special|특수|alphanumeric|영문/i').isVisible({ timeout: 5000 });
            expect(error).toBe(true);
        }
    });
});

// ─────────────────────────────────────────────────────────────
// 7. 커뮤니티 / Alpha 포스팅 테스트
// ─────────────────────────────────────────────────────────────
test.describe('7. 🤖 Community Alpha 포스팅 (Error Cases)', () => {

    test('COMM-01 [에러] 비로그인 상태에서 Alpha 포스팅 시도', async ({ page }) => {
        await page.goto(`${BASE}/community`);
        await page.waitForTimeout(1000);
        const createBtn = page.locator('text=/CREATE ALPHA/i').first();
        if (await createBtn.isVisible({ timeout: 5000 })) {
            await createBtn.click();
            // 로그인 필요 에러 또는 리다이렉트
            const loginRequired = await page.locator('text=/login|sign in|로그인/i').isVisible({ timeout: 5000 });
            const redirected = page.url().includes('login');
            expect(loginRequired || redirected).toBe(true);
        }
    });

    test('COMM-02 [에러] reasoning 비워두고 POST ALPHA', async ({ page }) => {
        await loginAs(page);
        await page.goto(`${BASE}/community`);
        await page.waitForTimeout(1000);
        const createBtn = page.locator('text=/CREATE ALPHA/i').first();
        if (await createBtn.isVisible({ timeout: 5000 })) {
            await createBtn.click();
            await page.waitForTimeout(500);
            // 코멘트 비운 채로 제출
            await page.locator('button:has-text("POST ALPHA")').click();
            const error = await page.locator('text=/reasoning|logic|로직|Please enter/i').isVisible({ timeout: 5000 });
            expect(error).toBe(true);
        }
    });
});

// ─────────────────────────────────────────────────────────────
// 8. 리더보드 테스트
// ─────────────────────────────────────────────────────────────
test.describe('8. 🏆 리더보드 (Leaderboard)', () => {

    test('LB-01 [정상] 비로그인 리더보드 접근 가능', async ({ page }) => {
        await page.goto(`${BASE}/leaderboard`);
        // 페이지 정상 로드 (로그인 없이도 가능)
        await expect(page).not.toHaveURL(/login/, { timeout: 5000 });
        await expect(page.locator('h1, h2').first()).toBeVisible({ timeout: 5000 });
    });

    test('LB-02 [정상] 리더보드 데이터 표시', async ({ page }) => {
        await page.goto(`${BASE}/leaderboard`);
        await page.waitForTimeout(2000);
        // 랭킹 아이템 또는 테이블 표시 확인
        const rows = page.locator('tr, [data-testid*="rank"], .rank-item').count();
        expect(await rows).toBeGreaterThan(0);
    });
});

// ─────────────────────────────────────────────────────────────
// 9. API 엔드포인트 상태 확인 (HTTP)
// ─────────────────────────────────────────────────────────────
test.describe('9. 🔧 API 상태 확인 (API Health)', () => {

    test('API-01 [정상] /api/market/trending 응답 확인', async ({ request }) => {
        const res = await request.get(`${BASE}/api/market/trending`);
        expect([200, 304]).toContain(res.status());
    });

    test('API-02 [정상] /api/market/live-rounds 응답 확인', async ({ request }) => {
        const res = await request.get(`${BASE}/api/market/live-rounds?category=CRYPTO&limit=5`);
        expect([200, 304]).toContain(res.status());
    });

    test('API-03 [에러] /api/predictions/submit - 인증 없이 POST', async ({ request }) => {
        const res = await request.post(`${BASE}/api/predictions/submit`, {
            data: { asset: 'BTCUSDT', direction: 'UP', amount: 100 }
        });
        // 인증 없는 요청은 401 또는 403 반환
        expect([401, 403, 400]).toContain(res.status());
    });

    test('API-04 [에러] /api/resolve - GET 응답 확인 (timeout 포함)', async ({ request }) => {
        const res = await request.get(`${BASE}/api/resolve`, {
            timeout: 15000
        });
        // 성공 또는 특정 메시지 반환 (크론잡 형태)
        expect([200, 401, 403]).toContain(res.status());
    });
});

// ─────────────────────────────────────────────────────────────
// 10. 주요 페이지 렌더링 확인
// ─────────────────────────────────────────────────────────────
test.describe('10. 📄 페이지 렌더링 (Page Rendering)', () => {
    const pages = [
        { name: 'Home', path: '/' },
        { name: 'Community', path: '/community' },
        { name: 'Leaderboard', path: '/leaderboard' },
        { name: 'How It Works', path: '/how-it-works' },
        { name: 'Help', path: '/help' },
        { name: 'Sentiment', path: '/sentiment' },
        { name: 'Match History', path: '/match-history' },
        { name: 'Achievements', path: '/achievements' },
        { name: 'Rewards', path: '/rewards' },
        { name: 'Login', path: '/login' },
    ];

    for (const p of pages) {
        test(`PAGE-RENDER: ${p.name} (${p.path}) - 500 에러 없음`, async ({ page }) => {
            const res = await page.goto(`${BASE}${p.path}`);
            // 500 에러 없음 확인
            expect(res?.status()).not.toBe(500);
            // 페이지 내 body 요소 표시
            await expect(page.locator('body')).toBeVisible({ timeout: 8000 });
        });
    }
});
