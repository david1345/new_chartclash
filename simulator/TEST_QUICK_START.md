# 테스트 빠른 시작 가이드

## 🚀 한 명령어로 모든 테스트 실행

```bash
npm test
```

이 명령어 하나로 모든 E2E 테스트가 자동으로 실행됩니다!

---

## 📋 주요 테스트 명령어

### 전체 테스트
```bash
npm test                # 모든 테스트 실행 (헤드리스 모드)
```

### UI 모드 (시각적으로 테스트 확인)
```bash
npm run test:ui         # 브라우저 UI로 테스트 실행
```

### 헤드드 모드 (브라우저 보면서 실행)
```bash
npm run test:headed     # 실제 브라우저 창으로 테스트 확인
```

### 디버그 모드
```bash
npm run test:debug      # 단계별 디버깅 모드
```

---

## 🎯 개별 테스트 스위트 실행

코드 수정 후 특정 기능만 빠르게 테스트하고 싶을 때:

```bash
# 인증 테스트만
npm run test:auth

# 예측 제출 테스트만
npm run test:prediction

# 네비게이션 테스트만
npm run test:navigation

# 통계 테스트만
npm run test:stats

# 리더보드 테스트만
npm run test:leaderboard

# 자산 선택 테스트만
npm run test:assets
```

---

## 🔧 테스트 환경 설정

### 1. 개발 서버 실행 (필수)

테스트 실행 전에 개발 서버가 실행 중이어야 합니다:

```bash
npm run dev
```

또는 자동으로 개발 서버를 시작하려면:

```bash
# playwright.config.ts의 webServer 설정이 자동으로 서버 시작
npm test
```

### 2. 테스트 계정 확인

테스트에서 사용하는 기본 계정:
- **이메일**: test1@mail.com
- **비밀번호**: 123456

이 계정이 Supabase에 존재하는지 확인하세요.

---

## 📊 테스트 결과 확인

### HTML 리포트 (권장)
```bash
npm run test:ci         # HTML 리포트 생성
npx playwright show-report  # 리포트 열기
```

### 터미널 출력
```bash
npm test                # 기본 콘솔 출력
```

---

## 🐛 테스트 실패 시 대처 방법

### 1. 스크린샷 확인
테스트 실패 시 자동으로 스크린샷이 저장됩니다:
```
test-results/
└── auth-test-TC-AUTH-01-retry1/
    └── test-failed-1.png
```

### 2. 비디오 확인
실패한 테스트의 비디오 녹화본:
```
test-results/
└── auth-test-TC-AUTH-01-retry1/
    └── video.webm
```

### 3. 트레이스 뷰어
상세한 실행 과정 확인:
```bash
npx playwright show-trace test-results/.../trace.zip
```

---

## 💡 개발 워크플로우 예시

### 시나리오 1: 새 기능 개발 후
```bash
# 1. 개발 서버 실행
npm run dev

# 2. 관련 테스트만 실행하여 빠른 검증
npm run test:prediction

# 3. 전체 테스트로 회귀 검증
npm test
```

### 시나리오 2: 버그 수정 후
```bash
# 1. 해당 기능 테스트 실행
npm run test:auth

# 2. 성공하면 전체 테스트
npm test
```

### 시나리오 3: 코드 리뷰 전
```bash
# 모든 테스트 통과 확인
npm test

# HTML 리포트로 결과 확인
npm run test:ci
npx playwright show-report
```

---

## 🎨 UI 모드 사용법 (추천!)

가장 편리한 방법:

```bash
npm run test:ui
```

UI 모드의 장점:
- ✅ 각 테스트를 시각적으로 확인
- ✅ 실패한 단계 바로 확인
- ✅ 테스트 선택하여 개별 실행
- ✅ 시간 여행 디버깅 (각 단계로 이동)
- ✅ 네트워크 요청 확인
- ✅ 콘솔 로그 확인

---

## 📈 테스트 커버리지

현재 테스트 스위트가 커버하는 주요 기능:

### ✅ 완전히 커버됨 (High Priority)
- 로그인/로그아웃
- 예측 제출 (UP/DOWN)
- 베팅 금액 검증 (최소/최대)
- 포인트 부족 처리
- 모든 페이지 네비게이션
- 통계 표시
- 리더보드 표시

### 🟡 부분적으로 커버됨 (Medium Priority)
- 자산 선택 (암호화폐, 주식, 원자재)
- 시간대 선택
- 업적 시스템
- 코멘트 추가

### 🔵 추가 필요 (Low Priority)
- 실시간 업데이트 (Realtime)
- 감성 분석 상세
- 보상 계산 검증
- 연속 승리 시스템

---

## 🚦 CI/CD 통합

GitHub Actions나 다른 CI/CD 파이프라인에 통합:

```yaml
# .github/workflows/test.yml 예시
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

## 🔍 테스트 디버깅 팁

### 특정 테스트만 실행
```bash
npx playwright test -g "TC-AUTH-01"
```

### 느린 모드로 실행
```bash
npx playwright test --headed --slow-mo=1000
```

### 특정 브라우저로 실행
```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
```

### 병렬 실행 비활성화 (디버깅용)
```bash
npx playwright test --workers=1
```

---

## 📝 테스트 작성 가이드

새 테스트 추가 시:

1. **파일 생성**: `src/test/e2e/your-feature.test.ts`
2. **헬퍼 사용**: `src/test/e2e/helpers.ts` 활용
3. **네이밍**: `TC-FEATURE-01: 설명` 형식
4. **package.json**: 새 명령어 추가

예시:
```typescript
import { test, expect } from '@playwright/test';
import { login } from './helpers';

test.describe('새 기능 테스트', () => {
    test.beforeEach(async ({ page }) => {
        await login(page);
    });

    test('TC-FEATURE-01: 기능 설명', async ({ page }) => {
        // 테스트 코드
    });
});
```

---

## 🎯 성능 최적화

테스트 실행 시간 단축:

```bash
# 병렬 실행 워커 수 증가
npx playwright test --workers=4

# 실패 시 즉시 중단
npx playwright test --max-failures=1

# 특정 파일만 실행
npx playwright test auth.test.ts prediction.test.ts
```

---

## ❓ 자주 묻는 질문 (FAQ)

### Q: 테스트가 타임아웃되면?
A: `playwright.config.ts`에서 `timeout` 설정을 늘리거나, 개별 테스트에서 `test.setTimeout()` 사용

### Q: 로그인이 실패하면?
A: 테스트 계정(test1@mail.com)이 Supabase에 존재하는지 확인

### Q: 개발 서버가 자동으로 시작 안되면?
A: `playwright.config.ts`의 `webServer.command` 확인

### Q: 특정 테스트만 건너뛰려면?
A: `test.skip()` 사용:
```typescript
test.skip('TC-FEATURE-01', async ({ page }) => {
    // 테스트 코드
});
```

---

## 📚 추가 리소스

- [Playwright 공식 문서](https://playwright.dev/)
- [TEST_SCENARIOS.md](./TEST_SCENARIOS.md) - 전체 테스트 시나리오
- [FEATURES_OVERVIEW.md](./FEATURES_OVERVIEW.md) - 구현 기능 목록

---

**Happy Testing! 🎉**

문제가 있으면 테스트 실행 결과와 함께 이슈를 제기해주세요.
