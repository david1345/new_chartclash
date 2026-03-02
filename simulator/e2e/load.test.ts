/**
 * ============================================================
 * ChartClash - 부하 테스트 (Load Test)
 * 실행: npm run test:load
 *
 * 목적: 다수 동시 사용자 시뮬레이션 및 API 응답 시간 측정
 * ============================================================
 */
import { test, expect } from '@playwright/test';

const BASE = process.env.BASE_URL || 'http://localhost:3000';
const CONCURRENT_USERS = parseInt(process.env.LOAD_USERS || '10');
const LOAD_TIMEOUT = parseInt(process.env.LOAD_TIMEOUT || '15000'); // 15s per request

// ─── 응답 시간 결과 저장 ─────────────────────────────────────
interface TimingResult {
    label: string;
    durationMs: number;
    status: number | 'error';
    ok: boolean;
}
const results: TimingResult[] = [];

function measureTime(label: string, durationMs: number, status: number | 'error') {
    const ok = status !== 'error' && (status as number) < 400;
    results.push({ label, durationMs, status, ok });
    const icon = ok ? '✅' : '❌';
    console.log(`${icon} [LOAD] ${label} | ${durationMs}ms | HTTP ${status}`);
}

// ─────────────────────────────────────────────────────────────
// 1. API 동시 부하 테스트
// ─────────────────────────────────────────────────────────────
test.describe('🔥 부하 테스트 - API 동시 요청', () => {

    test(`LOAD-01: /api/market/trending - ${CONCURRENT_USERS}개 동시 요청`, async ({ request }) => {
        const start = Date.now();
        const requests = Array.from({ length: CONCURRENT_USERS }, () =>
            request.get(`${BASE}/api/market/trending`, { timeout: LOAD_TIMEOUT })
                .then(r => r.status())
                .catch(() => 'error' as const)
        );
        const statuses = await Promise.all(requests);
        const elapsed = Date.now() - start;

        const successCount = statuses.filter(s => s === 200 || s === 304).length;
        const errorCount = statuses.filter(s => s === 'error' || (typeof s === 'number' && s >= 500)).length;

        measureTime(`trending x${CONCURRENT_USERS}`, elapsed, statuses[0] as any);
        console.log(`   ✅ Success: ${successCount} | ❌ Errors: ${errorCount} | ⏱️  Total: ${elapsed}ms`);

        // 80% 이상 성공해야 함
        expect(successCount / CONCURRENT_USERS).toBeGreaterThanOrEqual(0.8);
    });

    test(`LOAD-02: /api/market/live-rounds - ${CONCURRENT_USERS}개 동시 요청`, async ({ request }) => {
        const start = Date.now();
        const requests = Array.from({ length: CONCURRENT_USERS }, (_, i) => {
            const categories = ['CRYPTO', 'STOCKS', 'COMMODITIES'];
            const cat = categories[i % 3];
            return request.get(`${BASE}/api/market/live-rounds?category=${cat}&limit=10`, { timeout: LOAD_TIMEOUT })
                .then(r => r.status())
                .catch(() => 'error' as const);
        });
        const statuses = await Promise.all(requests);
        const elapsed = Date.now() - start;

        const successCount = statuses.filter(s => s === 200 || s === 304).length;
        measureTime(`live-rounds x${CONCURRENT_USERS}`, elapsed, statuses[0] as any);
        console.log(`   ✅ Success: ${successCount}/${CONCURRENT_USERS} | ⏱️  ${elapsed}ms`);

        expect(successCount / CONCURRENT_USERS).toBeGreaterThanOrEqual(0.8);
    });

    test(`LOAD-03: 홈 페이지 - ${CONCURRENT_USERS}개 동시 페이지 로드 응답시간`, async ({ request }) => {
        const start = Date.now();
        const requests = Array.from({ length: CONCURRENT_USERS }, () =>
            request.get(`${BASE}/`, { timeout: LOAD_TIMEOUT })
                .then(r => ({ status: r.status(), size: r.headers()['content-length'] }))
                .catch(() => ({ status: 'error' as const, size: '0' }))
        );
        const responses = await Promise.all(requests);
        const elapsed = Date.now() - start;

        const successCount = responses.filter(r => r.status === 200 || r.status === 304).length;
        measureTime(`home-page x${CONCURRENT_USERS}`, elapsed, responses[0].status as any);
        console.log(`   ✅ Success: ${successCount}/${CONCURRENT_USERS} | ⏱️  ${elapsed}ms avg: ${Math.round(elapsed / CONCURRENT_USERS)}ms`);

        // 평균 응답 5초 미만
        expect(elapsed / CONCURRENT_USERS).toBeLessThan(5000);
    });
});

// ─────────────────────────────────────────────────────────────
// 2. 연속 요청 응답 시간 측정
// ─────────────────────────────────────────────────────────────
test.describe('⏱️  응답 시간 벤치마크', () => {

    const endpoints = [
        { name: '홈 (/)', path: '/' },
        { name: '커뮤니티 (/community)', path: '/community' },
        { name: '리더보드 (/leaderboard)', path: '/leaderboard' },
        { name: '플레이 (/play/BTCUSDT/1h)', path: '/play/BTCUSDT/1h' },
        { name: 'Sentiment', path: '/sentiment' },
        { name: 'API: trending', path: '/api/market/trending' },
        { name: 'API: live-rounds', path: '/api/market/live-rounds?category=CRYPTO&limit=5' },
    ];

    for (const ep of endpoints) {
        test(`BENCH: ${ep.name} - 3초 미만 응답`, async ({ request }) => {
            const start = Date.now();
            const res = await request.get(`${BASE}${ep.path}`, { timeout: 10000 });
            const elapsed = Date.now() - start;

            measureTime(ep.name, elapsed, res.status());
            console.log(`   📊 ${ep.name}: ${elapsed}ms (HTTP ${res.status()})`);

            // 성공 응답
            expect(res.status()).toBeLessThan(500);
            // 3초 이내 응답
            expect(elapsed).toBeLessThan(3000);
        });
    }
});

// ─────────────────────────────────────────────────────────────
// 3. 반복 예측 제출 스트레스 테스트 (시뮬레이션)
// ─────────────────────────────────────────────────────────────
test.describe('💥 스트레스 테스트 - 반복 제출', () => {

    test('STRESS-01: /api/market/entry-price 연속 10회 호출', async ({ request }) => {
        const REPEAT = 10;
        const timings: number[] = [];

        for (let i = 0; i < REPEAT; i++) {
            const start = Date.now();
            const res = await request.post(`${BASE}/api/market/entry-price`, {
                data: { symbol: 'BTCUSDT', timeframe: '1h', type: 'CRYPTO' },
                timeout: 10000
            });
            const elapsed = Date.now() - start;
            timings.push(elapsed);
            // 500 내부 오류나 타임아웃 없이 응답해야 함
            expect(res.status()).toBeLessThan(500);
        }

        const avg = Math.round(timings.reduce((a, b) => a + b, 0) / timings.length);
        const max = Math.max(...timings);
        const min = Math.min(...timings);
        console.log(`   📊 entry-price x${REPEAT}: avg=${avg}ms, min=${min}ms, max=${max}ms`);

        // 평균 3초 이하
        expect(avg).toBeLessThan(3000);
    });

    test('STRESS-02: 페이지 빠른 전환 (4개 페이지 순차)', async ({ page }) => {
        const paths = ['/', '/leaderboard', '/community', '/sentiment'];
        const timings: number[] = [];

        for (const path of paths) {
            const start = Date.now();
            await page.goto(`${BASE}${path}`, { timeout: 10000 });
            await page.waitForLoadState('domcontentloaded');
            const elapsed = Date.now() - start;
            timings.push(elapsed);
            console.log(`   🔄 ${path}: ${elapsed}ms`);
        }

        const avg = Math.round(timings.reduce((a, b) => a + b, 0) / timings.length);
        console.log(`   📊 평균 페이지 이동 시간: ${avg}ms`);
        expect(avg).toBeLessThan(4000);
    });
});

// ─────────────────────────────────────────────────────────────
// 4. 테스트 결과 요약
// ─────────────────────────────────────────────────────────────
test.afterAll(async () => {
    if (results.length === 0) return;

    console.log('\n========== 📊 부하 테스트 결과 요약 ==========');
    const success = results.filter(r => r.ok).length;
    const failed = results.filter(r => !r.ok).length;
    const avgDuration = Math.round(results.reduce((s, r) => s + r.durationMs, 0) / results.length);
    const maxDuration = Math.max(...results.map(r => r.durationMs));

    console.log(`✅ 성공: ${success} | ❌ 실패: ${failed}`);
    console.log(`⏱️  평균 응답: ${avgDuration}ms | 최대: ${maxDuration}ms`);
    console.log('==============================================\n');
});
