# AI Analyst Scheduler 배포 가이드

## 1. 마이그레이션 실행

```bash
# Supabase에 마이그레이션 적용
cd ~/.gemini/antigravity/scratch/vibe-forecast
npx supabase db push

# 또는 SQL 파일 직접 실행
psql $DATABASE_URL -f supabase/migrations/20260220_ai_analyst_scheduler_settings.sql
```

## 2. Vercel Cron 설정 확인

`vercel.json` 파일에 다음이 설정되어 있는지 확인:

```json
{
  "crons": [
    {
      "path": "/api/cron/analyst-scheduler",
      "schedule": "*/15 * * * *"
    }
  ]
}
```

## 3. 환경 변수 확인

다음 환경 변수가 설정되어 있는지 확인:
- `CRON_SECRET`
- `NEXT_PUBLIC_SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`

## 4. Admin 페이지 접속

1. `/hq-v3-terminal-912` 접속
2. Admin 비밀번호로 로그인
3. "AI Analyst Scheduler" 섹션에서 ON/OFF 제어
4. 원하는 타임프레임 선택

## 5. 테스트

```bash
# Cron 수동 트리거 (로컬 테스트)
curl -X GET http://localhost:3000/api/cron/analyst-scheduler \
  -H "Authorization: Bearer $CRON_SECRET"

# Admin API 테스트
curl http://localhost:3000/api/admin/scheduler-settings

# 설정 업데이트 테스트
curl -X POST http://localhost:3000/api/admin/scheduler-settings \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "timeframes": ["15m", "1h"]}'
```

## 6. 모니터링

- Vercel 로그에서 cron 실행 확인
- Admin 대시보드에서 AI Analyst 데이터 확인
- `/api/market/trending` - AI fallback 데이터 표시 확인
- Community 페이지 AI Analyst Hub 섹션 확인

## 주의사항

- **첫 실행 전 반드시 OFF 상태로 시작**: Admin 페이지에서 수동으로 켜기
- **일일 API 제한**: 3000 calls/day (OpenAI)
- **거래시간 자동 필터링**: 주식/원자재는 시장 닫힘 시 자동 스킵
- **타임프레임별 실행 시간**:
  - 15m: 매 15분 (00, 15, 30, 45)
  - 30m: 매 30분 (00, 30)
  - 1h: 매 시간 (00)
  - 4h: 4시간마다 (00:00, 04:00, 08:00, 12:00, 16:00, 20:00)
  - 1d: 매일 09:00

## 문제 해결

### Cron이 실행되지 않음
- Vercel Cron 설정 확인
- `CRON_SECRET` 환경 변수 확인
- Vercel 로그 확인

### AI 분석이 생성되지 않음
- Admin 페이지에서 Scheduler가 ON인지 확인
- Supabase에서 `scheduler_settings` 테이블 확인
- OpenAI API 키 확인
- 일일 API 제한 확인 (`api_usage_tracking` 테이블)

### 주식/원자재 분석이 없음
- 거래시간 확인 (`isMarketOpen()` 함수)
- 주식: 월-금 09:30-16:00 (EST)
- 원자재: 거래시간 설정 확인
