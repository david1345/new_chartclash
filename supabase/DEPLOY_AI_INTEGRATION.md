# AI Analyst Hub - Supabase 배포 가이드

## 실행 순서

### 1. market_discovery_with_ai_rounds.sql
**기능**: AI 분석 기반 라운드 생성
- 유저 참여 없어도 AI 분석 10개 있으면 라운드 표시
- participant_count = 실제 유저 + AI 10명
- total_volume = 실제 볼륨 + AI 100pts

**포함 함수**:
- `get_live_rounds_with_stats(p_category, p_limit)` - 업데이트
- `get_trending_by_category()` - 업데이트

### 2. get_trending_by_single_category.sql
**기능**: 특정 카테고리의 top 3 자산 반환
- CRYPTO/STOCKS/COMMODITIES 중 하나 선택
- 해당 카테고리에서 볼륨 상위 3개 라운드 반환
- AI 예측 데이터 포함

**포함 함수**:
- `get_trending_by_single_category(p_category)` - 신규

## 변경사항 요약

### 데이터베이스
✅ comment 길이 제한: 140자 → 2000자
✅ AI 분석 기반 라운드 자동 생성
✅ 카테고리별 필터링 지원

### 프론트엔드
✅ 디폴트 카테고리: CRYPTO
✅ ALL 카테고리 제거
✅ AI 배지를 클릭 가능한 버튼으로 변경
✅ 버튼 클릭 시 `/community?tab=analyst-hub&asset={symbol}&timeframe={tf}` 이동
✅ Market Discovery 최대 50개 제한
✅ Trending 선택 카테고리의 top 3 표시

### AI Scheduler
✅ 30개 자산 × 5개 시간프레임 = 150개 라운드 지원
✅ 각 분석 5-7문장 + UP/DOWN + 확률(50-95%)
✅ 10pts 디폴트 베팅

## 테스트

SQL 실행 후:
```bash
# 1. AI 분석 생성 테스트
npx tsx scripts/analyst_scheduler_improved.ts --now BTCUSDT 15m

# 2. 개발 서버 재시작
npm run dev

# 3. localhost:3000 확인
# - CRYPTO 카테고리가 디폴트로 선택됨
# - AI 배지 표시 (우측 상단)
# - AI 배지 클릭 시 Community로 이동
```

## 실시간 스케줄러 실행

```bash
# 백그라운드 실행
npx tsx scripts/analyst_scheduler_improved.ts &

# 또는 PM2 사용
pm2 start scripts/analyst_scheduler_improved.ts --interpreter tsx --name analyst-scheduler
```

매 15분/30분/1시간/4시간/1일 정각에 자동으로 150개 라운드 분석 생성됩니다.
