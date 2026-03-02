# 🚀 상용 배포 가이드

## 📋 사전 준비

- [ ] Supabase Production 접근 권한
- [ ] Vercel Production 프로젝트
- [ ] Render.com 계정
- [ ] OpenAI API 키
- [ ] 모든 환경 변수 확인

---

## 1️⃣ DB 마이그레이션 (가장 중요!)

### 1.1 백업 먼저!

```bash
# Supabase Dashboard → SQL Editor에서 실행
-- 현재 전체 데이터 백업
pg_dump $DATABASE_URL > backup_before_migration_$(date +%Y%m%d_%H%M%S).sql
```

### 1.2 마이그레이션 실행

1. **Supabase Dashboard 접속**
   - https://supabase.com/dashboard
   - Production 프로젝트 선택

2. **SQL Editor → New Query**

3. **파일 내용 복사 & 실행**
   ```bash
   # 파일 경로
   deployment/01-production-migration.sql
   ```

4. **검증**
   ```sql
   -- 테이블 확인
   SELECT * FROM scheduler_settings;

   -- 함수 테스트
   SELECT get_scheduler_settings('ai_analyst');

   -- 결과: enabled = false (OFF), timeframes = [15m, 30m, 1h, 4h, 1d]
   ```

### 1.3 롤백 계획 (문제 발생 시)

```sql
-- 마이그레이션 파일 하단의 ROLLBACK 섹션 참고
-- scheduler_settings_backup_20260220 테이블에서 복구 가능
```

---

## 2️⃣ Render.com 설정

### 2.1 Render.com Dashboard

1. **New → Cron Job** 선택
2. **GitHub Repository 연결**
3. **Settings:**
   - Name: `ai-analyst-scheduler`
   - Environment: `Node`
   - Build Command: `echo 'No build needed'`
   - Start Command: `node deployment/render-cron-scheduler.js`
   - Schedule: `*/15 * * * *` (every 15 minutes)

### 2.2 환경 변수 설정

Render Dashboard → Environment:

```bash
NODE_ENV=production
PRODUCTION_URL=https://your-app.vercel.app
CRON_SECRET=<동일한 시크릿 사용>
TZ=UTC
```

**⚠️ 중요:** `CRON_SECRET`은 Vercel의 `CRON_SECRET`과 동일해야 합니다!

### 2.3 테스트

```bash
# Render Dashboard → Logs 확인
# 수동 트리거: Manual Deploy → Deploy Latest Commit
```

---

## 3️⃣ Vercel 배포

### 3.1 환경 변수 확인

Vercel Dashboard → Settings → Environment Variables:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=<production URL>
SUPABASE_SERVICE_ROLE_KEY=<production service role key>

# OpenAI
OPENAI_API_KEY=<your key>

# Cron Secret (Render.com과 동일)
CRON_SECRET=<generate secure random string>

# Optional
NODE_ENV=production
```

### 3.2 배포

```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast

# Production 배포
vercel --prod

# 또는 Git push (자동 배포)
git add .
git commit -m "Deploy AI Analyst Scheduler feature"
git push origin main
```

### 3.3 Vercel Cron 비활성화 (Render 사용)

현재 `vercel.json`에 cron 설정이 있지만, Render.com을 사용하므로:

**Option 1: vercel.json에서 cron 제거**
```json
{
    "cleanUrls": true
    // "crons" 섹션 제거
}
```

**Option 2: 그냥 두기**
- Vercel Cron과 Render Cron이 동시에 실행되어도 Lock 메커니즘으로 중복 방지됨
- 한 쪽이 실패해도 다른 쪽이 실행됨 (이중화)

**추천: Option 2 (이중화 유지)**

---

## 4️⃣ Admin 페이지 확인

1. **접속**: `https://your-app.vercel.app/hq-v3-terminal-912`
2. **로그인**: Admin 비밀번호 입력
3. **AI Analyst Scheduler 섹션 확인**
   - 초기 상태: OFF
   - 타임프레임: 15m, 30m, 1h, 4h, 1d (모두 선택됨)

4. **테스트**
   - ON 버튼 클릭 → 성공 메시지 확인
   - 타임프레임 하나 클릭 → 활성화/비활성화 확인
   - OFF 버튼 클릭 → 다시 비활성화

---

## 5️⃣ 기능 테스트

### 5.1 테스트 환경 설정

```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast

# 상용 환경 변수 설정
export TEST_BASE_URL=https://your-app.vercel.app
export TEST_EMAIL=test@example.com
export TEST_PASSWORD=your-test-password
```

### 5.2 QA 테스트 실행

```bash
# 전체 QA + 부하 테스트
npm run test:all

# QA만 실행
npm run test:qa

# 부하 테스트만
npm run test:load

# 특정 기능만
npm run test:auth
npm run test:prediction
```

### 5.3 결과 확인

```bash
# 테스트 결과 파일
ls -la simulator/e2e/results/

# 최신 결과 확인
cat simulator/e2e/results/qa_YYYYMMDD_HHMMSS.res
cat simulator/e2e/results/load_YYYYMMDD_HHMMSS.res
```

---

## 6️⃣ AI Analyst 기능 테스트

### 6.1 Scheduler 활성화

1. Admin 페이지에서 **ON** 클릭
2. 원하는 타임프레임 선택 (기본: 전부)

### 6.2 15분 대기

- Render.com Cron이 15분마다 실행
- 또는 Vercel Cron이 실행 (이중화)

### 6.3 확인

**Render.com 로그:**
```
Render Dashboard → ai-analyst-scheduler → Logs
```

**Supabase 데이터:**
```sql
-- predictions 테이블에 AI 분석 확인
SELECT * FROM predictions
WHERE channel = 'analyst_hub'
  AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;

-- Analyst 별 개수 확인
SELECT user_id, COUNT(*)
FROM predictions
WHERE channel = 'analyst_hub'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id;
```

**프론트엔드 확인:**
- Community 페이지 → AI Analyst Hub 탭
- Trending 섹션 (AI fallback 데이터)
- Market Discovery 섹션 (AI fallback 데이터)

---

## 7️⃣ 모니터링

### 7.1 Render.com

- Dashboard → Logs: Cron 실행 로그
- Dashboard → Metrics: 성공/실패율

### 7.2 Vercel

- Dashboard → Analytics
- Dashboard → Logs

### 7.3 Supabase

```sql
-- API 사용량 확인
SELECT * FROM api_usage_tracking
WHERE service = 'openai'
  AND date = CURRENT_DATE;

-- Scheduler 실행 로그
SELECT * FROM scheduler_locks
ORDER BY locked_at DESC
LIMIT 10;
```

---

## 8️⃣ 문제 해결

### Render Cron이 실행되지 않음

1. Render Dashboard → Logs 확인
2. 환경 변수 확인 (`PRODUCTION_URL`, `CRON_SECRET`)
3. 수동 트리거로 테스트

### AI 분석이 생성되지 않음

1. Admin 페이지에서 Scheduler가 **ON**인지 확인
2. Supabase에서 `scheduler_settings` 확인
3. OpenAI API 키 확인
4. 일일 API 제한 확인 (3000 calls/day)

### 주식/원자재 분석 없음

- 거래시간 확인 (주식: 월-금 09:30-16:00 EST)
- `isMarketOpen()` 함수 로직 확인

---

## 9️⃣ 체크리스트

### DB 마이그레이션
- [ ] 백업 완료
- [ ] 마이그레이션 실행
- [ ] 테이블 생성 확인
- [ ] 함수 테스트 완료
- [ ] Scheduler OFF 상태 확인

### Render.com
- [ ] Cron Job 생성
- [ ] 환경 변수 설정
- [ ] 첫 실행 확인
- [ ] 로그 정상

### Vercel
- [ ] 환경 변수 확인
- [ ] Production 배포
- [ ] Admin 페이지 접근 가능
- [ ] Toggle 작동 확인

### 테스트
- [ ] QA 테스트 통과 (npm run test:qa)
- [ ] 부하 테스트 통과 (npm run test:load)
- [ ] AI 분석 생성 확인
- [ ] Trending/Discovery fallback 확인

---

## 🎉 배포 완료!

모든 체크리스트를 완료하면 배포가 완료됩니다.

### 다음 단계
1. Scheduler를 **ON**으로 설정 (Admin 페이지)
2. 15분 대기 후 AI 분석 확인
3. 상용 사용자에게 공지
4. 모니터링 지속

---

## 📞 Support

문제 발생 시:
1. Render.com 로그 확인
2. Vercel 로그 확인
3. Supabase 데이터 확인
4. 롤백 스크립트 준비 상태 유지
