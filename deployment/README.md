# 🚀 AI Analyst Scheduler - Production Deployment Package

이 디렉토리에는 AI Analyst Scheduler 기능의 상용 배포를 위한 모든 파일이 포함되어 있습니다.

## 📦 배포 패키지 구성

```
deployment/
├── README.md                          ← 이 파일
├── DEPLOYMENT_GUIDE.md                ← 📘 전체 배포 가이드 (상세)
├── QUICK_DEPLOY.md                    ← ⚡ 빠른 배포 커맨드
│
├── 01-production-migration.sql        ← 🗄️  DB 마이그레이션 스크립트
├── render-cron-scheduler.js           ← 🔄 Render.com Cron Job 스크립트
├── render.yaml                        ← ⚙️  Render.com 설정 파일
└── test-production.sh                 ← 🧪 상용 테스트 스크립트
```

---

## 🎯 배포 순서 (필수!)

### 1. DB 마이그레이션 먼저! ⚠️

```bash
# Supabase Dashboard → SQL Editor에서 실행
deployment/01-production-migration.sql
```

**중요:** 다른 작업보다 먼저 실행해야 합니다!

### 2. Render.com 설정

- Dashboard → New Cron Job
- `render.yaml` 참고
- 환경 변수 설정 (PRODUCTION_URL, CRON_SECRET)

### 3. Vercel 배포

```bash
vercel --prod
```

### 4. 테스트

```bash
PROD_URL=https://your-app.vercel.app ./deployment/test-production.sh
```

---

## 📚 문서 가이드

### 처음 배포하는 경우
→ **DEPLOYMENT_GUIDE.md** 읽기 (상세 가이드)

### 빠르게 배포하는 경우
→ **QUICK_DEPLOY.md** 참고 (커맨드 모음)

### 문제 발생 시
→ **DEPLOYMENT_GUIDE.md** 8️⃣번 섹션 (문제 해결)

---

## ⚙️ 주요 기능

### 1. AI Analyst 자동 생성
- **대상**: 30개 자산 (코인 10 + 주식 10 + 원자재 10)
- **주기**: 15분/30분/1시간/4시간/1일 캔들 시작 시
- **거래시간 필터링**: 주식/원자재는 거래시간만 분석

### 2. Admin 제어
- `/hq-v3-terminal-912` 페이지
- ON/OFF 토글
- 타임프레임별 활성화/비활성화

### 3. Render.com 배포
- Cron Job으로 15분마다 실행
- Vercel API 호출
- 이중화 지원 (Vercel Cron + Render Cron)

### 4. Fallback 데이터
- Trending 섹션: Live 없으면 AI 데이터 표시
- Market Discovery: Live 없으면 AI 데이터 표시

---

## 🔒 보안 고려사항

### 환경 변수 (반드시 설정)

**Vercel:**
```
NEXT_PUBLIC_SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
OPENAI_API_KEY
CRON_SECRET (32+ chars random string)
```

**Render.com:**
```
PRODUCTION_URL (Vercel URL)
CRON_SECRET (Vercel과 동일)
```

### 초기 설정
- Scheduler는 기본적으로 **OFF**
- Admin이 수동으로 켜야 작동
- 안전한 배포 보장

---

## 🧪 테스트 전략

### 배포 전 (개발 환경)
```bash
npm run test:all
```

### 배포 후 (상용 환경)
```bash
PROD_URL=<url> ./deployment/test-production.sh
```

### 테스트 커버리지
- ✅ 인증 (AUTH-01~06)
- ✅ 네비게이션 (NAV-01~06)
- ✅ 검색 (SEARCH-01~04)
- ✅ 예측 주문 (PRED-01~04)
- ✅ 게스트 플로우 (GUEST-01~02)
- ✅ 설정 (SET-01~02)
- ✅ 커뮤니티 (COMM-01~02)
- ✅ 리더보드 (LB-01~02)
- ✅ API 상태 (API-01~04)
- ✅ 페이지 렌더링 (10 pages)

---

## 📊 모니터링

### Render.com
- Dashboard → ai-analyst-scheduler → Logs
- Dashboard → Metrics

### Vercel
- Dashboard → Analytics
- Dashboard → Logs

### Supabase
```sql
-- API 사용량
SELECT * FROM api_usage_tracking WHERE service = 'openai';

-- Scheduler 실행 로그
SELECT * FROM scheduler_locks ORDER BY locked_at DESC LIMIT 10;

-- AI 분석 데이터
SELECT COUNT(*) FROM predictions
WHERE channel = 'analyst_hub'
  AND created_at > NOW() - INTERVAL '1 hour';
```

---

## 🚨 긴급 대응

### Scheduler 중지 (3가지 방법)

**방법 1: Admin 페이지**
```
/hq-v3-terminal-912 → OFF 버튼
```

**방법 2: Render.com**
```
Dashboard → Pause Cron Job
```

**방법 3: Supabase**
```sql
UPDATE scheduler_settings SET enabled = false;
```

### 롤백

**Vercel:**
```bash
vercel rollback
```

**DB:**
```sql
-- deployment/01-production-migration.sql 하단 ROLLBACK 섹션 참고
```

---

## ✅ 배포 체크리스트

```
준비 단계
[ ] Supabase Production 접근 권한
[ ] Vercel Production 프로젝트
[ ] Render.com 계정
[ ] OpenAI API 키

DB 마이그레이션
[ ] 현재 DB 백업
[ ] 01-production-migration.sql 실행
[ ] scheduler_settings 테이블 확인
[ ] 함수 테스트 (get/update)

Render.com
[ ] Cron Job 생성
[ ] 환경 변수 설정
[ ] 첫 실행 확인

Vercel
[ ] 환경 변수 확인
[ ] Production 배포
[ ] Admin 페이지 접근

테스트
[ ] QA 테스트 통과
[ ] Load 테스트 통과
[ ] Critical Flow 통과

기능 확인
[ ] Admin 토글 작동
[ ] 15분 후 AI 분석 생성
[ ] Trending fallback 작동
[ ] Market Discovery fallback 작동

모니터링
[ ] Render 로그 확인
[ ] Vercel 로그 확인
[ ] Supabase 데이터 확인
```

---

## 📞 지원

### 문제 발생 시
1. **DEPLOYMENT_GUIDE.md** 8️⃣번 "문제 해결" 섹션 확인
2. Render/Vercel/Supabase 로그 확인
3. 롤백 스크립트 준비

### 파일 위치
```
deployment/
├── DEPLOYMENT_GUIDE.md       ← 전체 가이드
├── QUICK_DEPLOY.md           ← 빠른 참조
└── 01-production-migration.sql ← 롤백 스크립트 포함
```

---

## 🎉 배포 완료 후

1. Admin 페이지에서 Scheduler **ON**
2. 15분 대기
3. AI 분석 생성 확인
4. 사용자에게 공지
5. 모니터링 지속

---

**Good luck with your deployment! 🚀**
