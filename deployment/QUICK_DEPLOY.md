# ⚡ Quick Deploy Commands

배포를 위한 빠른 커맨드 모음입니다.

## 🔥 1분 만에 배포하기

```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast

# 1. DB 마이그레이션 (Supabase SQL Editor에서)
# → deployment/01-production-migration.sql 복사/실행

# 2. Vercel 배포
vercel --prod

# 3. Render.com 설정
# → render.com에서 Cron Job 생성
# → deployment/render.yaml 참고

# 4. 테스트
PROD_URL=https://your-app.vercel.app \
TEST_EMAIL=test@example.com \
TEST_PASSWORD=TestPassword123! \
./deployment/test-production.sh
```

---

## 📝 Step-by-Step Commands

### Step 1: DB 마이그레이션

**Supabase Dashboard → SQL Editor**

```sql
-- 파일 내용 붙여넣기:
-- deployment/01-production-migration.sql
```

**검증:**
```sql
SELECT * FROM scheduler_settings;
SELECT get_scheduler_settings('ai_analyst');
```

---

### Step 2: Render.com Cron Job

**Render Dashboard → New → Cron Job**

```yaml
Name: ai-analyst-scheduler
Build Command: echo 'No build needed'
Start Command: node deployment/render-cron-scheduler.js
Schedule: */15 * * * *
```

**Environment Variables:**
```bash
NODE_ENV=production
PRODUCTION_URL=https://your-app.vercel.app
CRON_SECRET=<same-as-vercel>
TZ=UTC
```

---

### Step 3: Vercel 환경 변수 확인

```bash
vercel env ls

# 필수 변수 확인:
# - NEXT_PUBLIC_SUPABASE_URL
# - SUPABASE_SERVICE_ROLE_KEY
# - OPENAI_API_KEY
# - CRON_SECRET
```

**없으면 추가:**
```bash
vercel env add CRON_SECRET
# 입력: <generate-random-32-chars>
# Environment: Production
```

---

### Step 4: 배포

```bash
# Production 배포
vercel --prod

# 배포 URL 확인
vercel ls

# 도메인 확인
vercel domains ls
```

---

### Step 5: 상용 테스트

```bash
# 환경 변수 설정
export PROD_URL=https://your-app.vercel.app
export TEST_EMAIL=test@example.com
export TEST_PASSWORD=TestPassword123!

# 전체 테스트
./deployment/test-production.sh

# 또는 개별 테스트
export TEST_BASE_URL=$PROD_URL
npm run test:qa
npm run test:load
```

---

### Step 6: Admin 확인

```bash
# 브라우저에서 접속
open https://your-app.vercel.app/hq-v3-terminal-912

# 또는 curl 테스트
curl https://your-app.vercel.app/api/admin/scheduler-settings
```

---

### Step 7: AI Scheduler 활성화

**Admin 페이지에서:**
1. Login
2. "AI Analyst Scheduler" 섹션 찾기
3. **ON** 버튼 클릭
4. 원하는 타임프레임 선택

**15분 후 확인:**
```bash
# Render.com 로그 확인
# Render Dashboard → ai-analyst-scheduler → Logs

# Supabase 데이터 확인
# SQL Editor:
SELECT COUNT(*) FROM predictions
WHERE channel = 'analyst_hub'
  AND created_at > NOW() - INTERVAL '30 minutes';
```

---

## 🚨 긴급 롤백

### Vercel 롤백

```bash
# 이전 배포로 롤백
vercel rollback
```

### DB 롤백

```sql
-- Supabase SQL Editor
DROP TABLE IF EXISTS scheduler_settings;
CREATE TABLE scheduler_settings AS
SELECT * FROM scheduler_settings_backup_20260220;
```

### Scheduler 긴급 중지

```bash
# Option 1: Admin 페이지에서 OFF
# Option 2: Render.com에서 Cron Job 일시중지
# Option 3: Supabase SQL
UPDATE scheduler_settings
SET enabled = false
WHERE service_name = 'ai_analyst';
```

---

## ✅ 배포 체크리스트 (인쇄용)

```
[ ] DB 백업 완료
[ ] 마이그레이션 실행
[ ] scheduler_settings 테이블 확인
[ ] get_scheduler_settings() 함수 작동
[ ] update_scheduler_settings() 함수 작동

[ ] Render.com Cron Job 생성
[ ] Render 환경 변수 설정
[ ] Render 첫 실행 성공

[ ] Vercel 환경 변수 확인
[ ] vercel --prod 배포
[ ] Admin 페이지 접근 가능
[ ] Scheduler 토글 작동

[ ] QA 테스트 통과
[ ] Load 테스트 통과
[ ] Critical Flow 테스트 통과

[ ] AI 분석 생성 확인 (15분 대기)
[ ] Trending fallback 작동
[ ] Market Discovery fallback 작동

[ ] 모니터링 설정
[ ] 알림 설정
[ ] 문서 업데이트
```

---

## 📞 문제 해결 Quick Fix

### "Function not found" 에러

```sql
-- Supabase SQL Editor
CREATE OR REPLACE FUNCTION get_scheduler_settings(p_service_name TEXT)
RETURNS TABLE (enabled BOOLEAN, timeframes TEXT[])
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY SELECT s.enabled, s.timeframes
    FROM scheduler_settings s WHERE s.service_name = p_service_name;
END; $$;
```

### Render Cron 실행 안됨

```bash
# Render Dashboard → Manual Deploy
# 로그 확인 후 환경 변수 재확인
```

### Admin 토글 안됨

```bash
# 브라우저 콘솔 확인
# Network 탭에서 API 응답 확인
# Supabase 직접 확인:
SELECT * FROM scheduler_settings;
```

---

## 🎯 One-Liner Deploy

```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast && \
vercel --prod && \
echo "✅ Deployed! Now:" && \
echo "1. Run deployment/01-production-migration.sql in Supabase" && \
echo "2. Create Render.com Cron Job" && \
echo "3. Run: PROD_URL=<url> ./deployment/test-production.sh"
```
