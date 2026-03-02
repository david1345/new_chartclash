# 🎯 테스트 명령어 빠른 참조

## 가장 많이 사용하는 명령어

```bash
# ⭐ 전체 테스트 실행 (가장 많이 사용!)
npm test

# 🎨 UI 모드 (시각적으로 확인)
npm run test:ui

# 🔍 개별 테스트 스위트
npm run test:auth          # 인증 테스트만
npm run test:prediction    # 예측 제출 테스트만
npm run test:navigation    # 네비게이션 테스트만
```

---

## 전체 명령어 목록

### 기본 테스트
```bash
npm test                    # 모든 테스트 실행 (헤드리스)
npm run test:ui             # UI 모드로 실행 ⭐ 추천!
npm run test:headed         # 브라우저 보면서 실행
npm run test:debug          # 디버그 모드
npm run test:ci             # CI/CD용 (HTML 리포트 생성)
```

### 개별 스위트
```bash
npm run test:auth           # 인증 (3개)
npm run test:prediction     # 예측 제출 (6개)
npm run test:assets         # 자산 선택 (6개)
npm run test:navigation     # 네비게이션 (11개)
npm run test:stats          # 통계 (5개)
npm run test:leaderboard    # 리더보드 (5개)
npm run test:edge           # 엣지 케이스 (11개)
```

### 고급 사용법
```bash
# 특정 테스트만
npx playwright test -g "TC-AUTH-01"

# 특정 파일만
npx playwright test auth.test.ts prediction.test.ts

# 특정 브라우저로
npx playwright test --project=chromium

# 느린 모드 (디버깅)
npx playwright test --headed --slow-mo=1000

# 병렬 실행 비활성화
npx playwright test --workers=1

# 실패 시 즉시 중단
npx playwright test --max-failures=1

# HTML 리포트 보기
npx playwright show-report
```

---

## 개발 워크플로우

### 시나리오 1: 빠른 검증
```bash
# 코드 수정 → 관련 테스트만
npm run test:prediction

# 성공 → 전체 테스트
npm test
```

### 시나리오 2: 디버깅
```bash
# UI 모드로 문제 확인
npm run test:ui

# 또는 브라우저 보면서
npm run test:headed
```

### 시나리오 3: PR 전
```bash
# 전체 테스트 + 리포트
npm run test:ci
npx playwright show-report
```

---

## 빠른 팁

- ⚡ **가장 빠름**: `npm run test:prediction` (20초)
- 🎨 **가장 편리**: `npm run test:ui` (시각적)
- 📊 **가장 상세**: `npm run test:ci` → `show-report`
- 🐛 **디버깅**: `npm run test:debug`

---

## 문제 해결

### 로그인 실패
```bash
# 테스트 계정 확인: test1@mail.com / 123456
# Supabase에 계정 존재하는지 확인
```

### 타임아웃
```bash
# 개별 테스트 실행 시간 늘리기
npx playwright test --timeout=60000
```

### 포트 충돌
```bash
# 개발 서버가 이미 실행 중인지 확인
# 3000 포트 사용 중이면 자동으로 3001 사용
```

---

이 파일을 북마크하고 필요할 때 빠르게 참조하세요! 📌
