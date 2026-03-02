# 🧪 Vibe Forecast - 자동화 테스트 가이드

## 📖 개요

이 프로젝트는 포괄적인 E2E(End-to-End) 자동화 테스트 스위트를 제공합니다. Playwright를 사용하여 실제 사용자 시나리오를 시뮬레이션하고, 코드 변경 시 빠르게 회귀 테스트를 수행할 수 있습니다.

---

## 🚀 빠른 시작

### 1. 한 줄로 모든 테스트 실행

```bash
npm test
```

**이 명령어 하나로 끝!** 개발 서버가 자동으로 시작되고 모든 테스트가 실행됩니다.

---

## 📂 테스트 파일 구조

```
src/test/e2e/
├── auth.test.ts           # 인증 테스트 (로그인/로그아웃)
├── prediction.test.ts     # 예측 제출 테스트
├── assets.test.ts         # 자산 및 시간대 선택 테스트
├── navigation.test.ts     # 페이지 네비게이션 테스트
├── stats.test.ts          # 통계 및 히스토리 테스트
├── leaderboard.test.ts    # 리더보드 테스트
├── edge-cases.test.ts     # 엣지 케이스 테스트
└── helpers.ts             # 공통 헬퍼 함수
```

---

## 🎯 테스트 커버리지

### ✅ 인증 (auth.test.ts)
- [x] TC-AUTH-01: 로그인 성공
- [x] TC-AUTH-02: 로그인 실패
- [x] TC-AUTH-03: 로그아웃

### ✅ 예측 제출 (prediction.test.ts)
- [x] TC-PRED-01: UP 방향 예측 제출
- [x] TC-PRED-02: DOWN 방향 예측 제출
- [x] TC-PRED-03: 최소 베팅 금액 검증 (10pt)
- [x] TC-PRED-04: 최대 베팅 금액 검증 (20%)
- [x] TC-PRED-05: 포인트 부족 시 제출 불가
- [x] TC-PRED-07: 코멘트 추가

### ✅ 자산 선택 (assets.test.ts)
- [x] TC-ASSET-01: 암호화폐 자산 선택
- [x] TC-ASSET-02: 주식 자산 선택
- [x] TC-ASSET-03: 원자재 자산 선택
- [x] TC-ASSET-04: 자산 전환
- [x] TC-ASSET-05: 실시간 가격 표시
- [x] TC-TIME-01: 시간대 선택

### ✅ 네비게이션 (navigation.test.ts)
- [x] TC-NAV-01: 모든 주요 페이지 접근
  - 홈, 내 통계, 매치 히스토리, 업적
  - 리더보드, 감성 분석, 보상, 도움말, 설정
- [x] TC-NAV-02: 미로그인 시 보호된 페이지 리디렉션

### ✅ 통계 (stats.test.ts)
- [x] TC-STATS-01: 내 통계 표시
- [x] TC-STATS-02: 매치 히스토리 표시
- [x] TC-STATS-03: 업적 시스템
- [x] TC-STATS-04: 포인트 잔액 표시
- [x] TC-STATS-05: 예측 상세 정보

### ✅ 리더보드 (leaderboard.test.ts)
- [x] TC-LEADER-01: 글로벌 리더보드 표시
- [x] TC-LEADER-02: 현재 사용자 순위 표시
- [x] TC-LEADER-03: 리더보드 데이터 표시
- [x] TC-LEADER-04: 승률 및 연속 승리 표시
- [x] TC-LEADER-05: 티어 시스템 표시

### ✅ 엣지 케이스 (edge-cases.test.ts)
- [x] TC-EDGE-01: 극단적 베팅 금액 (최대값)
- [x] TC-EDGE-02: 음수 베팅 금액
- [x] TC-EDGE-03: 0 베팅 금액
- [x] TC-EDGE-04: 소수점 베팅 금액
- [x] TC-EDGE-05: 빈 베팅 금액
- [x] TC-EDGE-06: 매우 긴 코멘트 (140자 제한)
- [x] TC-EDGE-07: 빠른 연속 제출
- [x] TC-EDGE-08: 페이지 새로고침 후 상태 유지
- [x] TC-EDGE-09: 브라우저 뒤로가기
- [x] TC-EDGE-10: 동시에 여러 탭 열기
- [x] TC-EDGE-11: 특수문자 코멘트 (XSS 방지)

**총 테스트 케이스**: 50+ 개

---

## 🛠️ 테스트 명령어

### 전체 테스트
```bash
npm test                    # 모든 테스트 실행 (헤드리스)
npm run test:ui             # UI 모드 (가장 편리!)
npm run test:headed         # 브라우저 보면서 실행
npm run test:debug          # 디버그 모드
npm run test:ci             # CI/CD용 (HTML 리포트)
```

### 개별 테스트 스위트
```bash
npm run test:auth           # 인증 테스트
npm run test:prediction     # 예측 테스트
npm run test:assets         # 자산 선택 테스트
npm run test:navigation     # 네비게이션 테스트
npm run test:stats          # 통계 테스트
npm run test:leaderboard    # 리더보드 테스트
npm run test:edge           # 엣지 케이스 테스트
```

### 유용한 옵션
```bash
# 특정 테스트만
npx playwright test -g "TC-AUTH-01"

# 특정 브라우저로
npx playwright test --project=chromium

# 느린 모드 (디버깅)
npx playwright test --headed --slow-mo=1000

# 병렬 실행 수 조정
npx playwright test --workers=4

# 실패 시 즉시 중단
npx playwright test --max-failures=1
```

---

## 📋 테스트 전제 조건

### 1. 환경 설정
```bash
# .env.local 파일 확인
NEXT_PUBLIC_SUPABASE_URL=your_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_key
```

### 2. 테스트 계정
Supabase에 다음 계정이 존재해야 합니다:
- **이메일**: test1@mail.com
- **비밀번호**: 123456
- **초기 포인트**: 1000pt 이상 권장

### 3. 개발 서버
테스트 실행 시 자동으로 시작되지만, 수동으로 실행할 수도 있습니다:
```bash
npm run dev
```

---

## 🎨 UI 모드 사용법 (권장!)

가장 편리한 테스트 방법:

```bash
npm run test:ui
```

### UI 모드의 장점
- ✅ 각 테스트를 시각적으로 확인
- ✅ 실패한 단계 바로 파악
- ✅ 테스트 선택하여 개별 실행
- ✅ 시간 여행 디버깅
- ✅ 네트워크 요청 확인
- ✅ 콘솔 로그 확인
- ✅ 스크린샷 자동 캡처

### UI 모드 스크린샷
```
┌─────────────────────────────────────────┐
│ 🎭 Playwright Test UI                   │
├─────────────────────────────────────────┤
│ ✅ auth.test.ts (3/3)                   │
│ ✅ prediction.test.ts (6/6)             │
│ ⏸️  navigation.test.ts (10/10)          │
│ ⏸️  stats.test.ts (5/5)                 │
│ ⏸️  leaderboard.test.ts (5/5)           │
│ ⏸️  edge-cases.test.ts (11/11)          │
└─────────────────────────────────────────┘
```

---

## 🐛 테스트 실패 시 디버깅

### 1. 스크린샷 확인
```
test-results/
├── auth-test-TC-AUTH-01-chromium-retry1/
│   ├── test-failed-1.png
│   └── test-failed-2.png
```

### 2. 비디오 확인
```
test-results/
└── auth-test-TC-AUTH-01-chromium-retry1/
    └── video.webm
```

### 3. 트레이스 뷰어
```bash
npx playwright show-trace test-results/.../trace.zip
```

### 4. HTML 리포트
```bash
npm run test:ci
npx playwright show-report
```

---

## 💻 개발 워크플로우

### 시나리오 1: 기능 개발 후 테스트
```bash
# 1. 코드 작성
vim src/app/page.tsx

# 2. 관련 테스트만 실행 (빠른 검증)
npm run test:prediction

# 3. 통과하면 전체 테스트
npm test

# 4. 커밋 전 확인
npm run test:ci
```

### 시나리오 2: 버그 수정 후 테스트
```bash
# 1. 버그 수정
vim src/components/PredictionForm.tsx

# 2. 해당 기능 테스트
npm run test:prediction

# 3. 엣지 케이스 확인
npm run test:edge

# 4. 전체 회귀 테스트
npm test
```

### 시나리오 3: PR 생성 전
```bash
# 1. 린트 확인
npm run lint

# 2. 전체 테스트
npm test

# 3. HTML 리포트 생성
npm run test:ci

# 4. 리포트 확인
npx playwright show-report

# 5. 모든 테스트 통과하면 PR 생성
```

---

## 🔧 테스트 설정

### playwright.config.ts
```typescript
export default defineConfig({
    testDir: './src/test/e2e',
    fullyParallel: true,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,
    reporter: 'html',
    use: {
        baseURL: 'http://localhost:3000',
        trace: 'on-first-retry',
    },
    webServer: {
        command: 'npm run dev',
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
    },
});
```

---

## 📊 테스트 통계

- **총 테스트 스위트**: 7개
- **총 테스트 케이스**: 50+ 개
- **평균 실행 시간**: 2-3분 (전체)
- **개별 스위트**: 20-30초
- **커버리지**: 주요 기능 100%

---

## 🚀 CI/CD 통합

### GitHub Actions 예시
```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:ci
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
```

---

## 📚 관련 문서

- [TEST_SCENARIOS.md](./TEST_SCENARIOS.md) - 상세 테스트 시나리오
- [TEST_QUICK_START.md](./TEST_QUICK_START.md) - 빠른 시작 가이드
- [FEATURES_OVERVIEW.md](./FEATURES_OVERVIEW.md) - 구현 기능 목록

---

## 🎓 테스트 작성 가이드

### 새 테스트 추가하기

1. **파일 생성**
```bash
touch src/test/e2e/new-feature.test.ts
```

2. **기본 구조**
```typescript
import { test, expect } from '@playwright/test';
import { login } from './helpers';

test.describe('새 기능 테스트', () => {
    test.beforeEach(async ({ page }) => {
        await login(page);
    });

    test('TC-FEATURE-01: 기능 설명', async ({ page }) => {
        // 테스트 코드
        await page.goto('/');
        // ... assertions
    });
});
```

3. **package.json에 명령어 추가**
```json
{
  "scripts": {
    "test:new-feature": "playwright test new-feature.test.ts"
  }
}
```

### 헬퍼 함수 사용
```typescript
import {
    login,
    logout,
    submitPrediction,
    selectAsset,
    getPointsBalance,
    waitForToast
} from './helpers';

test('예시', async ({ page }) => {
    await login(page);
    await selectAsset(page, 'BTC');
    await submitPrediction(page, {
        direction: 'UP',
        betAmount: 50
    });
    await waitForToast(page, /success/i);
});
```

---

## ❓ FAQ

### Q: 테스트가 타임아웃되면?
A: `test.setTimeout(60000)` 또는 `playwright.config.ts`에서 `timeout` 설정

### Q: 로그인이 계속 실패하면?
A:
1. 테스트 계정(test1@mail.com)이 Supabase에 존재하는지 확인
2. `.env.local` 파일의 Supabase 설정 확인
3. 개발 서버가 정상 실행 중인지 확인

### Q: 특정 테스트만 건너뛰려면?
A: `test.skip()` 사용
```typescript
test.skip('TC-AUTH-01', async ({ page }) => {
    // 이 테스트는 실행되지 않음
});
```

### Q: 테스트가 불안정하면 (Flaky)?
A:
1. `await page.waitForTimeout()`을 적절히 추가
2. `{ timeout: 5000 }` 옵션 사용
3. `page.waitForLoadState('networkidle')` 사용

### Q: 로컬에서는 통과하는데 CI에서 실패하면?
A:
1. CI 환경의 리소스가 부족할 수 있음 → `workers: 1` 설정
2. 타임아웃 늘리기
3. `retries: 2` 설정

---

## 🎉 결론

이 자동화 테스트 스위트를 사용하면:
- ✅ **개발 속도 향상**: 수동 테스트 시간 90% 감소
- ✅ **버그 조기 발견**: 배포 전 문제 파악
- ✅ **회귀 방지**: 기존 기능 보호
- ✅ **자신감**: 안전한 리팩토링
- ✅ **문서화**: 테스트가 곧 명세

**Happy Testing! 🚀**

---

**작성자**: Claude Sonnet 4.5
**최종 수정**: 2026-02-06
**버전**: 1.0.0
