# USDT-only Supabase Runbook

이 폴더의 기준 파일은 [`20260329_usdt_only_canonical.sql`](/Users/kimdonghyouk/project3/new_chartclash/supabase/usdt_only/20260329_usdt_only_canonical.sql) 입니다.

## 목적

- `points / streak` 기반 레거시 구조 제거
- 현재 `new_chartclash` 런타임이 기대하는 테이블/컬럼/RPC/트리거를 하나의 기준 SQL로 통합
- Supabase를 `인증 + 앱 데이터 + 온체인 미러` 레이어로 고정

## 실행 방법

### 1. 기존 DB를 유지하면서 구조만 맞출 때

Supabase SQL Editor에서 아래 파일 전체를 그대로 실행합니다.

- [`20260329_usdt_only_canonical.sql`](/Users/kimdonghyouk/project3/new_chartclash/supabase/usdt_only/20260329_usdt_only_canonical.sql)

이 파일은 idempotent하게 작성되어 있어서, 같은 프로젝트에 다시 실행해도 안전한 편입니다.

### 2. 완전 초기화 후 새 구조로 갈 때

먼저 별도로 아래를 실행해 `public` 스키마를 비운 뒤,

```sql
drop schema public cascade;
create schema public;
grant all on schema public to postgres, anon, authenticated, service_role;
```

그 다음 [`20260329_usdt_only_canonical.sql`](/Users/kimdonghyouk/project3/new_chartclash/supabase/usdt_only/20260329_usdt_only_canonical.sql) 을 실행하세요.

## 이 파일이 정리하는 것

- `profiles.points`, `streak`, `streak_count` 제거
- `predictions`를 USDT mirror 중심 컬럼으로 정리
- `rounds`, `notifications`, `feedbacks`, `activity_logs`, `scheduler_settings`, `api_usage`, `scheduler_locks` 생성/정리
- `get_live_rounds_with_stats`, `get_trending_by_single_category`, `get_trending_assets`, `get_top_leaders`, `get_market_sentiment`, `get_analyst_rounds` 추가
- 스케줄러 RPC 추가
- `resolve_prediction_pari_mutuel` 호환 함수 추가
- 레거시 `submit_prediction`, `resolve_prediction_advanced` 제거
- `predictions -> profiles` 성과 동기화 트리거 추가
- 예측 정산 시 `notifications`, `activity_logs` 생성 트리거 추가

## 주의

- 기존의 [`full_reset_fresh_start.sql`](/Users/kimdonghyouk/project3/new_chartclash/supabase/full_reset_fresh_start.sql) 은 더 이상 canonical 파일이 아닙니다.
- 이 runbook 적용 후에는 `points` 기반 SQL을 다시 실행하면 안 됩니다.
- `feedbacks` 읽기 정책은 현재 관리자 페이지가 브라우저에서 직접 조회하는 구조를 살리기 위해 완화되어 있습니다. 보안 하드닝은 이후 admin API 서버화와 함께 다시 조이는 게 좋습니다.
