# Vibe Forecast - 구현 기능 목록

> 프로젝트 분석 날짜: 2026-02-06

## 목차
1. [UI/UX 구조](#1-uiux-구조)
2. [사용자 기능](#2-사용자-기능)
3. [시스템 레벨 기능](#3-시스템-레벨-기능)
4. [데이터베이스 스키마](#4-데이터베이스-스키마)
5. [API 엔드포인트](#5-api-엔드포인트)

---

## 1. UI/UX 구조

### 주요 페이지

#### 인증 페이지
- **로그인 (`/login`)**: 이메일/비밀번호 + OAuth 지원
- **게스트 모드 (Guest Mode)**: 가입 없이 로컬 스토리지(`localStorage`) 기반으로 1,000pt 가상 자금을 이용해 예측을 체험하고, 추후 정식 가입 시 데이터 마이그레이션 지원.

#### 메인 대시보드
- **홈 (`/`)**: 예측 인터페이스, 실시간 차트, 예측 히스토리, 소셜 피드

#### 사용자 프로필 & 통계
- **내 통계 (`/my-stats`)**: 총 예측 수, 승률, 순수익, 방향 편향성 표시
- **매치 히스토리 (`/match-history`)**: 예측 상세 내역 (진입가, 종료가, 실제 변동, 손익)
- **업적 (`/achievements`)**: 뱃지 시스템 (First Blood, Sniper, Vibe Check, BTC Whale, Diamond Hands, Bear Slayer, Bull Rider, Millionaire)
- **설정 (`/settings`)**: 사용자 환경설정

#### 글로벌 기능
- **리더보드 (`/leaderboard`)**: 상위 3명 포디움, 랭킹 테이블, 현재 유저 위치 표시
- **감성 분석 (`/sentiment`)**: 자산별/시간대별 군중 예측 분석
- **보상 (`/rewards`)**: 시즌 보상 정보, 티어 예상, 랭크 보상표
- **커뮤니티 (`/community`)**: 커뮤니티 기능

#### 정보 페이지
- **작동 원리 (`/how-it-works`)**: 게임 메커니즘, 리스크/보상, 예측 라운드, 정산 설명
- **도움말 (`/help`)**: 지원 문서

#### 관리자
- **관리자 대시보드 (`/admin`)**: 시스템 통계, 최근 예측, 상위 유저 모니터링

#### 법적 문서
- **법적 페이지 (`/legal/*`)**: 개인정보보호, 이용약관, 페어플레이, 악용방지, 쿠키, 지원 정책

### UI 컴포넌트 시스템
- **Radix UI 기반**: Button, Card, Dialog, Dropdown, Tabs, Badge, Avatar, ScrollArea
- **Tailwind CSS**: 커스텀 투자/트레이딩 테마 (다크 모드, 그라데이션 액센트)
- **애니메이션**: Framer Motion 활용
- **실시간 데이터 표시**: 라이브 업데이트 UI

---

## 2. 사용자 기능

### 핵심 예측 시스템

#### 자산 선택 (총 30개)
1. **암호화폐 (10개)**: BTC, ETH, SOL, XRP, DOGE, ADA, AVAX, DOT, LINK, MATIC
2. **주식 (10개)**: AAPL, NVDA, TSLA, MSFT, AMZN, GOOGL, META, NFLX, AMD, INTC
3. **원자재 (10개)**: Gold, Silver, Oil, Gas, Corn, Soy, Wheat, Copper, Platinum, Palladium

#### 시간대 선택 (6개)
- `1m`, `5m`, `15m`, `30m`, `1h`, `4h`, `1d`
- 각 시간대별 보상 배율 차등 적용

#### 방향 선택
- **UP** (상승) 또는 **DOWN** (하락)

#### 목표 변동률 선택 (4개)
- `0.5%`, `1.0%`, `1.5%`, `2.0%`
- 높은 목표일수록 높은 리스크/보상

#### 베팅 금액
- **최소**: 10 포인트
- **최대**: 보유 포인트의 20%
- 실시간 잔액 검증

### 보상 구조

#### 기본 보상 계산식
```
방향 승리 보상 = 베팅액 × 0.8 × 시간대 배율
목표 보너스 = 고정 포인트 (20-120pt)
연속 승리 배율 = 최대 2.5배 (5연승 이상)
하우스 엣지 = 0.95 (순수익의 5% 소각)
패배 = 전액 몰수
```

#### 시간대 배율
- `1m`/`5m`/`15m`: 1.0x
- `30m`: 1.1x
- `1h`: 1.2x
- `4h`: 1.5x
- `1d`: 1.8x

#### 목표 보너스
- `0.5%`: 20pt
- `1.0%`: 40pt
- `1.5%`: 70pt
- `2.0%`: 120pt

### 예측 잠금 시스템
- 캔들 경과 시간의 ~13% 이후 진입 = **80% 보상** (지연 페널티)
- 조기 예측 = **100% 보상**
- 자산/시간대별 캔들당 1회 예측 제한

### 소셜 기능
- **라이브 피드**: 선택한 자산의 다른 플레이어 예측 실시간 표시
- **코멘트**: 예측 시 최대 140자 알파 인사이트 추가 가능
- **실시간 감성**: 군중 예측 동향 표시

### 연속 승리 (Streak) 시스템
- **완벽한 연속 승리**: 방향 + 목표 모두 달성해야 카운트
- 방향만 맞추고 목표 실패 시 → 연속 승리 초기화
- 최대 2.5배 보상 배율

### 업적 시스템
- **뱃지**: Novice, Skilled, Pro Trader, Market Master, Vibe Legend
- **특수 업적**: First Blood, Sniper, Vibe Check, BTC Whale, Diamond Hands, Bear Slayer, Bull Rider, Millionaire
- 진행도 추적

---

## 3. 시스템 레벨 기능

### 인증 & 보안
- **Supabase Auth**: 이메일/비밀번호 + OAuth
- **Row-Level Security (RLS)**: 데이터베이스 레벨 권한 관리
- **자동 프로필 생성**: 회원가입 시 1000 포인트 지급

### 예측 관리
- **트랜잭션 제출**: `submit_prediction()` RPC를 통한 원자적 처리
  - 포인트 검증
  - 베팅 한도 검증
  - 캔들 종료 시간 계산
  - 예측 레코드 생성
  - 포인트 차감
- **캔들 기반 그룹화**: 정산 효율화
- **상태 추적**: `pending` → `WIN`/`LOSS`/`ND`/`REFUND`

### 정산 시스템
- **Cron Job**: 1분마다 실행되어 완료된 캔들 자동 정산 (`/api/cron/resolve`)
- **다중 가격 API 우선순위**:
  - **암호화폐**: CryptoCompare → CoinGecko → Binance/MEXC/Bybit → 시뮬레이션
  - **주식/원자재**: Yahoo Finance → 시뮬레이션
- **군중 배율 계산**: `1.0 + (0.5 - 내편비율)` (역행 플레이 보상)
- **고급 정산**: 시가/종가 기반 공정성 보장
- **분산 트리거 (Heartbeat)**: 탭을 켜둔 유저들이 60초 간격 + 0~30초 Jitter(랜덤 지연)를 통해 비동기적으로 정산을 트리거하여 서버리스 한계 (Timeout 및 Thundering Herd 병목) 방지.

### 실시간 시스템
- **Realtime Notifications**: Supabase Realtime 활용
- **라이브 리더보드**: 실시간 순위 업데이트
- **사용자 통계 구독**: 포인트/승률 라이브 업데이트
- **감성 피드 구독**: 군중 동향 실시간 모니터링
- **알림 벨**: 읽지 않은 알림 카운트

### 리더보드 시스템
- **글로벌 랭킹**: 포인트 기준 정렬
- **Top 100 캐시뷰**: RPC 폴백 지원
- **사용자 순위 계산**: `get_user_rank()` RPC
- **연속 승리 & 승률 통계**
- **티어 시스템**: Bronze, Silver, Gold, Platinum

### 통계 & 히스토리
- **총 예측 수**: 누적 게임 수
- **승률**: (총 승리 / 총 게임) × 100
- **순수익**: 누적 수익 - 누적 손실
- **방향 편향**: UP/DOWN 선호도 분석
- **자산별 성과**: 각 자산의 승률 추적

### 관리자 시스템
- **보호된 대시보드**: 비밀번호 인증
- **시스템 통계**: 총 유저, 총 예측, 대기 중 예측, 포인트 유통량
- **실시간 상태 모니터링**: 시스템 헬스 체크
- **최근 예측 검사**: 정산 상태 확인

### 시장 시간 검증
- **암호화폐**: 24/7 거래
- **주식**: 월-금 09:30-16:00 ET (미국 동부시간)
- **원자재**: 커스텀 거래 시간

### 공정성 메커니즘
- **표준화된 라운드 시간**: 결정론적 캔들 경계
- **시가/종가 추적**: 투명한 정산
- **서버 타임스탬프 검증**: 클라이언트 조작 방지
- **다중 소스 가격 검증**: 조작 방지
- **군중 배율**: 합의 편향 방지

---

## 4. 데이터베이스 스키마

### 테이블 구조

#### `profiles` (사용자)
```sql
- id: UUID (PK, auth.users FK)
- email: TEXT
- username: TEXT
- points: INTEGER (기본값 1000)
- tier: TEXT (bronze, silver, gold, platinum)
- avatar_url: TEXT
- created_at: TIMESTAMP
- total_games: INTEGER
- total_wins: INTEGER
- total_earnings: NUMERIC
- streak: INTEGER (현재 연속 승리)
- streak_count: INTEGER (대체 필드)
```

#### `predictions` (예측/거래)
```sql
- id: BIGINT (PK)
- user_id: UUID (FK → profiles)
- asset_symbol: TEXT
- timeframe: TEXT
- direction: TEXT (UP/DOWN)
- target_percent: NUMERIC (0.5, 1.0, 1.5, 2.0)
- entry_price: NUMERIC
- bet_amount: INTEGER
- status: TEXT (pending, WIN, LOSS, ND, REFUND)
- close_price: NUMERIC
- actual_price: NUMERIC
- actual_change_percent: NUMERIC
- is_target_hit: BOOLEAN
- profit_loss: INTEGER
- profit: INTEGER
- created_at: TIMESTAMP
- candle_close_at: TIMESTAMP
- resolved_at: TIMESTAMP
- comment: TEXT (최대 140자)
```

#### `notifications` (알림)
```sql
- id: BIGINT (PK)
- user_id: UUID (FK → profiles)
- type: TEXT
- message: TEXT
- prediction_id: BIGINT (FK → predictions)
- created_at: TIMESTAMP
- read: BOOLEAN
```

#### 기타 테이블
- **feed**: 사용자 상호작용 기록
- **interactions**: 좋아요, 댓글 등
- **posts**: 소셜 포스트/댓글 저장

### 인덱스
```sql
idx_predictions_status ON predictions(status)
idx_predictions_user ON predictions(user_id)
idx_predictions_candle ON predictions(asset_symbol, timeframe, candle_close_at)
idx_predictions_created ON predictions(created_at DESC)
idx_notifications_user ON notifications(user_id, created_at DESC)
```

---

## 5. API 엔드포인트

### REST API

#### 예측 관리
**POST** `/api/market/entry-price`
- 현재 캔들 시가 및 경과 시간 조회
- 응답: `openPrice`, `currentPrice`, `candleElapsedSeconds`, `serverTime`
- 암호화폐 및 주식 지원
- 다중 제공자 폴백

#### 정산
**GET** `/api/cron/resolve`
- 메인 Cron Job (30초마다 실행)
- 캔들별로 예측 그룹화
- 다중 API에서 종가 조회
- 각 예측에 대해 `resolve_prediction_advanced()` RPC 호출
- 정산된 예측 수 및 에러 상세 반환

**GET** `/api/resolve`
- 레거시 클라이언트 하트비트 (정산 트리거)

#### 디버그
**GET** `/api/debug/status`
- 시스템 상태 엔드포인트

### Supabase RPC 함수

#### `submit_prediction()`
```typescript
// 입력: user_id, asset_symbol, timeframe, direction, target_percent, entry_price, bet_amount, comment
// 처리:
// 1. 사용자 포인트 검증
// 2. 베팅 한도 검증 (10pt 이상, 보유액의 20% 이하)
// 3. 캔들 종료 시간 계산
// 4. 예측 레코드 생성
// 5. 포인트 차감
// 출력: { success: true, new_points: number }
```

#### `resolve_prediction_advanced()`
```typescript
// 입력: prediction_id, close_price
// 처리:
// 1. 진입가 vs 종가로 WIN/LOSS/ND 판정
// 2. 목표 달성 시 보너스 적용
// 3. 연속 승리 배율 계산
// 4. 하우스 엣지 적용 (0.95x)
// 5. 사용자 포인트 및 연속 승리 업데이트
// 6. 알림 생성
// 출력: { success: true, payout: number }
```

#### `get_user_rank()`
```typescript
// 입력: user_id
// 출력: 포인트 기준 사용자 순위
// 용도: Top 100 외 리더보드 표시
```

#### `get_market_sentiment()`
```typescript
// 입력: asset_symbol, timeframe
// 출력: 시간대 내 자산별 UP/DOWN 카운트
// 그룹화: 목표 퍼센트별
// 용도: 감성 분석 페이지
```

---

## 6. 주요 기술 스택

### 프론트엔드
- **Next.js 16** (App Router)
- **React 19**
- **TypeScript**
- **Tailwind CSS 4**
- **Radix UI** (컴포넌트)
- **Framer Motion** (애니메이션)
- **Recharts + Lightweight Charts** (차트)

### 백엔드
- **Supabase**
  - PostgreSQL (데이터베이스)
  - Auth (인증)
  - Realtime (실시간 구독)
  - RPC (서버 함수)

### 테스팅
- **Vitest** (단위 테스트)
- **Playwright** (E2E 테스트)
- **Custom Simulator** (시뮬레이션 테스트)

### 배포
- **Vercel** (호스팅)
- **Cron Jobs** (정산 자동화)

---

## 7. 핵심 특징 요약

### 공정성
- 캔들 종가 기반 정산 (실시간 진입가 아님)
- 다중 가격 소스 검증
- 서버 타임스탬프 검증
- 투명한 정산 로직

### 스킬 기반 게임플레이
- 완벽한 연속 승리 요구사항 (방향 + 목표 모두 달성)
- 늦은 진입 페널티 (조기 예측 인센티브)
- 군중 역행 보상 (군중 심리 역행 시 더 큰 보상)

### 게임화 요소
- 티어 시스템
- 업적 뱃지
- 시즌 보상
- 글로벌 리더보드

### 실시간 경험
- 라이브 피드
- 실시간 순위
- 즉각적인 알림
- 소셜 프루프 (다른 트레이더의 예측 표시)

### 회복력
- **RPC 재시도 로직 (지수 백오프)**: DB 트랜잭션 충돌 시 자동 재시도
- **폴백 가격 API (3단계 우선순위)**: API 한도 초과 시 즉각 우회
- **시뮬레이션 모드 (최종 폴백)**: 외부 데이터 단절 시에도 자체 시뮬레이터 가동
- **무한 리로드 방지 (Cache Buster)**: `layout.tsx`에서 네트워크 지연이 페이지 강제 새로고침(루프)으로 이어지지 않도록 예외 처리.
- 30초 정산 딜레이 (데이터 전파 버퍼)

---

## 결론

**Vibe Forecast**는 금융 시장 UI/UX와 게임화를 결합한 정교한 **스킬 기반 예측 트레이딩 게임**입니다. 실시간 기능, 공정성 메커니즘, 소셜 요소를 갖춘 완전한 플랫폼입니다.
