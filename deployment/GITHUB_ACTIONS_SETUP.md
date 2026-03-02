# 🎯 GitHub Actions 설정 가이드

**추천 방법:** Render.com 대신 GitHub Actions 사용 (더 간단!)

---

## ✅ 왜 GitHub Actions?

| 항목 | GitHub Actions | Render.com |
|------|---------------|------------|
| 가입 | 불필요 (이미 GitHub 사용 중) | ✅ 필요 |
| 설정 | YAML 파일 (코드로 관리) | Dashboard 수동 설정 |
| 무료 티어 | 2000분/월 | 제한적 |
| 로그 확인 | GitHub에서 바로 | 별도 사이트 |
| 배포 | Git push로 자동 | 수동 설정 |

**결론: GitHub Actions가 훨씬 쉽고 편리합니다!** ✨

---

## 🚀 5분 만에 설정하기

### 1. GitHub Secrets 설정

**GitHub Repository → Settings → Secrets and variables → Actions**

두 개의 Secret 추가:

#### `PRODUCTION_URL`
```
Value: https://your-app.vercel.app
```

#### `CRON_SECRET`
```
Value: <Vercel의 CRON_SECRET과 동일한 값>
```

**⚠️ 중요:** `CRON_SECRET`은 Vercel 환경 변수와 동일해야 합니다!

---

### 2. Workflow 파일 확인

이미 생성되어 있습니다:
```
.github/workflows/ai-analyst-scheduler.yml
```

Git에 푸시하면 자동으로 활성화됩니다!

---

### 3. 배포

```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast

# Workflow 파일 확인
git status

# 커밋 & 푸시
git add .github/workflows/ai-analyst-scheduler.yml
git commit -m "Add GitHub Actions cron for AI Analyst Scheduler"
git push origin main
```

**끝!** 🎉 15분마다 자동으로 실행됩니다.

---

## 📊 모니터링

### GitHub Actions 로그 확인

1. **GitHub Repository 접속**
2. **Actions 탭 클릭**
3. **"AI Analyst Scheduler" workflow 선택**
4. **최근 실행 기록 확인**

### 수동 실행 (테스트)

1. **Actions 탭**
2. **"AI Analyst Scheduler" 선택**
3. **"Run workflow" 버튼 클릭**
4. **즉시 실행됨 (15분 기다릴 필요 없음)**

---

## ⚙️ 작동 방식

```yaml
schedule:
  - cron: '*/15 * * * *'  # 15분마다
```

**실행 시간:**
- 00:00, 00:15, 00:30, 00:45
- 01:00, 01:15, 01:30, 01:45
- ... (하루 96번)

**실행 내용:**
1. GitHub Actions가 시작됨
2. Vercel API (`/api/cron/analyst-scheduler`) 호출
3. AI 분석 생성
4. 로그 저장
5. 성공/실패 결과 표시

---

## 🔒 보안

### CRON_SECRET 생성

```bash
# 안전한 랜덤 문자열 생성
openssl rand -base64 32

# 또는
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

이 값을:
1. Vercel → Environment Variables → `CRON_SECRET`
2. GitHub → Secrets → `CRON_SECRET`

**동일하게 설정!**

---

## 🧪 테스트

### 1. 수동 실행으로 즉시 테스트

**GitHub → Actions → AI Analyst Scheduler → Run workflow**

### 2. 로그 확인

```
✅ Scheduler executed successfully
   - Status Code: 200
   - Response: { "success": true, "processed": 10, ... }
```

### 3. Supabase 데이터 확인

```sql
SELECT COUNT(*) FROM predictions
WHERE channel = 'analyst_hub'
  AND created_at > NOW() - INTERVAL '30 minutes';
```

---

## 📝 전체 배포 순서 (업데이트)

### ~~2. Render.com 설정~~ (불필요!)

### ✅ 2. GitHub Actions 설정 (새로운 방법)

```bash
# 1. DB 마이그레이션 (Supabase)
deployment/01-production-migration.sql

# 2. GitHub Secrets 설정
# Repository → Settings → Secrets
# - PRODUCTION_URL
# - CRON_SECRET

# 3. Workflow 파일 푸시
git add .github/workflows/ai-analyst-scheduler.yml
git push

# 4. Vercel 배포
vercel --prod

# 5. 테스트
# GitHub → Actions → Run workflow
```

---

## 💰 비용

### GitHub Actions 무료 티어
- **Public Repo:** 무제한
- **Private Repo:** 2000분/월

**계산:**
- 1회 실행: ~1-2분
- 15분마다 실행: 96회/일
- 월 사용량: 96 × 30 × 2분 = 5760분

**⚠️ Private Repo는 무료 한도 초과!**

**해결책:**
1. **Repository를 Public으로 변경** (무제한 무료)
2. **GitHub Pro 구독** ($4/월, 3000분)
3. **Self-hosted Runner 사용** (무료, 자체 서버)

**추천:** Repository를 Public으로 (오픈소스)

---

## 🔄 Vercel Cron과 비교

### Vercel Cron (기존)
```json
// vercel.json
{
  "crons": [{
    "path": "/api/cron/analyst-scheduler",
    "schedule": "*/15 * * * *"
  }]
}
```

### GitHub Actions (새로운)
```yaml
# .github/workflows/ai-analyst-scheduler.yml
schedule:
  - cron: '*/15 * * * *'
```

**차이점:**
- Vercel Cron: Vercel이 직접 실행 (내부)
- GitHub Actions: 외부에서 API 호출

**이중화:**
- 둘 다 활성화 가능!
- Lock 메커니즘으로 중복 방지
- 한 쪽 실패 시 다른 쪽이 커버

---

## 🚨 문제 해결

### Workflow가 실행되지 않음

**확인 사항:**
1. GitHub Secrets 설정 확인
2. Workflow 파일이 `main` 브랜치에 있는지 확인
3. Repository의 Actions 탭 활성화 확인

### "401 Unauthorized" 오류

```bash
# CRON_SECRET이 일치하지 않음
# Vercel과 GitHub Secrets 값 확인
```

### "Scheduler is disabled" (skipped)

```bash
# Admin 페이지에서 ON으로 변경
# 또는 Supabase에서:
UPDATE scheduler_settings SET enabled = true;
```

---

## ✅ 최종 체크리스트

```
[ ] GitHub Secrets 설정 (PRODUCTION_URL, CRON_SECRET)
[ ] Workflow 파일 푸시
[ ] Vercel 환경 변수 확인 (CRON_SECRET)
[ ] Vercel 배포
[ ] DB 마이그레이션
[ ] GitHub Actions에서 수동 실행 테스트
[ ] 15분 대기 후 자동 실행 확인
[ ] Supabase에서 AI 데이터 확인
[ ] Admin 페이지에서 ON으로 변경
```

---

## 🎉 완료!

이제 GitHub Actions가 15분마다 자동으로 AI 분석을 생성합니다!

**모니터링:**
- GitHub → Actions 탭
- Vercel → Logs
- Supabase → predictions 테이블

**제어:**
- Admin 페이지 → AI Analyst Scheduler → ON/OFF

---

## 📞 추가 설정 (선택사항)

### Slack/Discord 알림

```yaml
- name: Send Slack notification
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "⚠️ AI Analyst Scheduler failed!"
      }
```

### 이메일 알림

GitHub Actions는 기본적으로 실패 시 이메일 발송 (Repository Watch 설정)

---

**GitHub Actions 방식이 훨씬 더 간단합니다!** ✨
