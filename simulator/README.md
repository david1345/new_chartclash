# 🧪 Simulator & E2E Test Suite

이 디렉토리에는 Vibe Forecast의 시뮬레이터와 자동화 E2E 테스트가 포함되어 있습니다.

## 📂 디렉토리 구조

```
simulator/
├── 📄 README.md                    ← 이 파일
├── 📄 TEST_SCENARIOS.md            ← 상세 테스트 시나리오
├── 📄 TEST_QUICK_START.md          ← 빠른 시작 가이드
├── 📄 TEST_COMMANDS.md             ← 명령어 빠른 참조
├── 📄 README_TESTING.md            ← 종합 테스트 문서
│
├── ⚙️ playwright.config.ts         ← Playwright 설정
├── 🔧 test.ts                       ← 기존 시뮬레이터
├── 📝 .env                          ← 환경 변수
├── 📝 .env.production               ← 프로덕션 환경 변수
│
├── e2e/                             ← E2E 테스트 파일
│   ├── auth.test.ts                 ← 인증 테스트
│   ├── prediction.test.ts           ← 예측 제출 테스트
│   ├── assets.test.ts               ← 자산 선택 테스트
│   ├── navigation.test.ts           ← 네비게이션 테스트
│   ├── stats.test.ts                ← 통계 테스트
│   ├── leaderboard.test.ts          ← 리더보드 테스트
│   ├── edge-cases.test.ts           ← 엣지 케이스 테스트
│   └── helpers.ts                   ← 공통 헬퍼 함수
│
└── result/                          ← 테스트 결과 (날짜별)
    ├── .gitkeep
    ├── 2026-02-06_14-30/            ← 예시: 2026년 2월 6일 14:30
    │   ├── test-artifacts/          ← 테스트 아티팩트
    │   ├── html-report/             ← HTML 리포트
    │   ├── videos/                  ← 비디오 녹화
    │   └── test-results.json        ← JSON 결과
    └── 2026-02-06_15-45/            ← 다음 테스트 실행
        └── ...
```

---

## 🚀 사용법

### 기본 명령어 (프로젝트 루트에서 실행)

```bash
# 전체 테스트 실행
npm test

# UI 모드 (시각적 확인)
npm run test:ui

# 개별 테스트
npm run test:auth
npm run test:prediction

# 최신 결과 리포트 보기
npm run test:report
```

### 직접 실행 (simulator 디렉토리에서)

```bash
cd simulator

# 전체 테스트
npx playwright test

# UI 모드
npx playwright test --ui

# 특정 테스트
npx playwright test auth.test.ts
```

---

## 📊 테스트 결과 확인

### 자동 저장
모든 테스트 결과는 `result/` 디렉토리에 **날짜별로 자동 저장**됩니다:

```
result/
└── 2026-02-06_14-30/
    ├── html-report/          ← 브라우저로 열어서 확인
    ├── test-results.json     ← JSON 형식 결과
    ├── test-artifacts/       ← 스크린샷, 트레이스
    └── videos/               ← 실패한 테스트 비디오
```

### HTML 리포트 보기

```bash
# 프로젝트 루트에서
npm run test:report

# 또는 직접
cd simulator
npx playwright show-report result/2026-02-06_14-30/html-report
```

### 특정 날짜 결과 보기

```bash
cd simulator
ls result/  # 날짜별 디렉토리 확인

# 원하는 날짜의 리포트 열기
npx playwright show-report result/2026-02-06_14-30/html-report
```

---

## 🔧 설정

### 결과 저장 위치
`playwright.config.ts`에서 자동으로 날짜별 디렉토리 생성:

```typescript
const getResultDir = () => {
    const now = new Date();
    // 2026-02-06_14-30 형식으로 생성
    return `./result/${year}-${month}-${day}_${hour}-${minute}`;
};
```

### Git 관리
- `result/` 디렉토리의 모든 테스트 결과는 `.gitignore`에 의해 **자동으로 제외**됩니다
- 빈 `.gitkeep` 파일만 커밋되어 디렉토리 구조 유지

---

## 📋 테스트 스위트

### 포함된 테스트 (50+ 케이스)

| 스위트 | 파일 | 케이스 수 | 설명 |
|--------|------|-----------|------|
| 🔐 인증 | auth.test.ts | 3개 | 로그인/로그아웃 |
| 📊 예측 | prediction.test.ts | 6개 | 예측 제출 & 검증 |
| 💰 자산 | assets.test.ts | 6개 | 자산 선택 & 시간대 |
| 🧭 네비게이션 | navigation.test.ts | 11개 | 페이지 이동 |
| 📈 통계 | stats.test.ts | 5개 | 통계 & 히스토리 |
| 🏆 리더보드 | leaderboard.test.ts | 5개 | 순위 & 랭킹 |
| 🛡️ 엣지케이스 | edge-cases.test.ts | 11개 | 보안 & 예외처리 |

---

## 🎯 빠른 참조

### 가장 많이 사용하는 명령어

```bash
# ⭐ 전체 테스트 (프로젝트 루트에서)
npm test

# 🎨 UI 모드 (가장 편리!)
npm run test:ui

# 📊 최신 결과 보기
npm run test:report
```

### 개발 워크플로우

```bash
# 1. 코드 수정 후 관련 테스트
npm run test:prediction

# 2. 성공하면 전체 테스트
npm test

# 3. 결과 확인
npm run test:report
```

---

## 📚 문서

- **TEST_COMMANDS.md** - 명령어 빠른 참조
- **TEST_QUICK_START.md** - 빠른 시작 가이드
- **TEST_SCENARIOS.md** - 상세 테스트 시나리오
- **README_TESTING.md** - 종합 가이드 & FAQ

---

## 🔍 결과 분석

### 통과/실패 확인
```bash
# JSON 결과 보기
cat result/2026-02-06_14-30/test-results.json | jq '.suites[].specs[].tests[].results[].status'

# 실패한 테스트만
cat result/2026-02-06_14-30/test-results.json | jq '.suites[].specs[] | select(.tests[].results[].status == "failed")'
```

### 비디오 확인
```bash
# 실패한 테스트의 비디오는 자동으로 저장됨
open result/2026-02-06_14-30/videos/
```

---

## 🧹 결과 정리

### 오래된 결과 삭제
```bash
cd simulator/result

# 7일 이상 된 결과 삭제
find . -type d -name "20*" -mtime +7 -exec rm -rf {} \;

# 최근 5개만 남기고 삭제
ls -t | tail -n +6 | xargs rm -rf
```

### 디스크 용량 확인
```bash
du -sh result/*
```

---

## ⚙️ 고급 설정

### 결과 저장 경로 변경
`playwright.config.ts` 수정:

```typescript
const resultDir = './custom-path';
```

### 비디오 녹화 설정
```typescript
use: {
    video: 'on',  // 모든 테스트 녹화
    // video: 'retain-on-failure',  // 실패시만 (기본값)
}
```

### 스크린샷 설정
```typescript
use: {
    screenshot: 'on',  // 모든 단계
    // screenshot: 'only-on-failure',  // 실패시만 (기본값)
}
```

---

## 🎉 정리

이제 모든 테스트는 `simulator/` 디렉토리에서만 실행되며, 결과는 날짜별로 깔끔하게 정리됩니다!

```bash
# 프로젝트 루트에서
npm test              # 테스트 실행
npm run test:report   # 결과 확인
```

**Happy Testing! 🚀**
