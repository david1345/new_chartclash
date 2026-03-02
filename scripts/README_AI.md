# 🤖 AI 시뮬레이션 시스템 실행 가이드

본 가이드는 커뮤티니 활성화를 위해 준비된 100명의 AI 유저를 가동하는 절차를 설명합니다.

## 1. 사전 준비 (Prerequisites)
먼저 운영 DB의 스키마를 확장해야 합니다. (사용자 직접 실행 권장)
- **SQL 실행**: [20260216_ai_schema_init.sql](file:///Users/kimdonghyouk/.gemini/antigravity/scratch/vibe-forecast/supabase/migrations/20260216_ai_schema_init.sql)
  - `profiles` 테이블에 `is_bot`, `bot_persona` 컬럼을 추가합니다.

## 2. AI 봇 계정 생성 및 배포 (Deployment)
준비된 100명의 페르소나를 실제 서비스 계정으로 생성합니다.
- **실행 명령**:
  ```bash
  npx tsx scripts/deploy_ai_bots.ts
  ```
  - `auth.users`에 100개의 계정을 자동 생성하고 `profiles`를 봇 정보로 업데이트합니다.

## 3. 시뮬레이션 엔진 가동 (Simulation)
AI 봇들이 실제로 시장을 분석하고 베팅을 수행하게 합니다.
- **실행 명령**:
  ```bash
  npx tsx scripts/ai_simulation_engine.ts
  ```
  - 실행 시 3~5명의 봇이 무작위로 선택되어 현재 시장 가격 기준 UP/DOWN 분석글을 남기고 실제 베팅을 수행합니다.
  - 이 스크립트를 주기적(예: 10분마다)으로 실행하면 서비스가 24시간 살아있는 상태를 유지할 수 있습니다.

## 📁 주요 구성 파일
- **데이터셋**: [ai_bots_data.json](file:///Users/kimdonghyouk/.gemini/antigravity/scratch/vibe-forecast/scripts/ai_bots_data.json) (100인 프로필)
- **코멘트 템플릿**: [ai_comment_templates.json](file:///Users/kimdonghyouk/.gemini/antigravity/scratch/vibe-forecast/scripts/ai_comment_templates.json) (지표 기반 문장 조합기)
- **핵심 엔진**: [ai_simulation_engine.ts](file:///Users/kimdonghyouk/.gemini/antigravity/scratch/vibe-forecast/scripts/ai_simulation_engine.ts)

---
**보고 준비가 완료되었습니다. 사용자님의 승인 후 첫 번째 시뮬레이션 사이클을 시작할 수 있습니다.**
