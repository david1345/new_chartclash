# AI Analyst Scheduler 관리 가이드

## 🔒 프로세스 중복 실행 방지

### 문제
- 스케줄러가 여러 번 실행되면 중복 API 호출로 비용 폭증
- 오늘 사례: 8개 프로세스 중복 실행 → 3시간에 $5 소진

### 해결
**PID Lock 시스템** 구현:
- `.analyst-scheduler.lock` - 실행 중임을 표시
- `.analyst-scheduler.pid` - 프로세스 ID 저장
- 이미 실행 중이면 새 인스턴스 차단

## 📊 일일 API 호출 제한

### 설정
```typescript
const MAX_DAILY_CALLS = 3000; // 일일 최대 3,000회
```

### 비용 계산
- **현재 설정**: gpt-4o-mini
- **예상 비용**: ~$3/일
- **실제 호출**:
  - 15m: 96회/일
  - 30m, 1h, 4h, 1d: 31회/일
  - 총 127회/일 × 23개 자산 = 2,921회/일

### 추적
- `.analyst-api-calls.json` - 일별 호출 횟수 저장
- 자정에 자동 리셋
- 100회마다 진행률 로그

## 🛠️ 관리 명령어

### 기본 사용
```bash
# 스케줄러 시작
./scripts/manage-scheduler.sh start

# 스케줄러 중지
./scripts/manage-scheduler.sh stop

# 스케줄러 재시작
./scripts/manage-scheduler.sh restart

# 상태 확인
./scripts/manage-scheduler.sh status

# API 사용량 확인
./scripts/manage-scheduler.sh usage

# 오래된 Lock 파일 제거
./scripts/manage-scheduler.sh clean

# 일일 제한 리셋 (긴급 상황)
./scripts/manage-scheduler.sh reset-limit
```

### 수동 관리
```bash
# 모든 스케줄러 프로세스 찾기
ps aux | grep analyst_scheduler

# 특정 PID 종료
kill <PID>

# 모든 스케줄러 강제 종료
pkill -f analyst_scheduler_improved

# Lock 파일 수동 제거
rm -f .analyst-scheduler.lock .analyst-scheduler.pid
```

## 📈 모니터링

### 실시간 로그
```bash
tail -f logs/analyst-scheduler.log
```

### 중요 로그 메시지
- `🔒 Lock acquired: PID XXXXX` - 정상 시작
- `❌ ERROR: Scheduler already running` - 중복 실행 차단
- `📊 Daily API Calls: X/3000` - 사용량 업데이트
- `❌ DAILY LIMIT REACHED` - 제한 도달, 내일까지 대기

## 🚨 긴급 상황 대응

### 여러 프로세스가 실행 중인 경우
```bash
# 1. 모든 스케줄러 종료
pkill -f analyst_scheduler_improved

# 2. Lock 파일 정리
./scripts/manage-scheduler.sh clean

# 3. 상태 확인
./scripts/manage-scheduler.sh status

# 4. 재시작
./scripts/manage-scheduler.sh start
```

### API 제한 초과 시
```bash
# 1. 현재 사용량 확인
./scripts/manage-scheduler.sh usage

# 2. 긴급히 더 호출해야 한다면
./scripts/manage-scheduler.sh reset-limit

# 3. 스케줄러 재시작
./scripts/manage-scheduler.sh restart
```

## 🔧 설정 조정

### 일일 제한 변경
`scripts/analyst_scheduler_improved.ts`:
```typescript
const MAX_DAILY_CALLS = 5000; // 원하는 값으로 변경
```

### 모델 변경 (비용 절감)
```typescript
model: "gpt-4o-mini", // 현재 (저렴)
// model: "gpt-4o",   // 더 정확하지만 비쌈
```

### 자산 수 조정
```typescript
const ALL_ASSETS = [
    // 필요한 자산만 선택
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT',
    // ...
];
```

## 📝 PM2 사용 (권장)

```bash
# PM2 설치
npm install -g pm2

# 스케줄러 시작
pm2 start scripts/analyst_scheduler_improved.ts --interpreter tsx --name analyst-scheduler

# 상태 확인
pm2 status

# 로그 보기
pm2 logs analyst-scheduler

# 재시작
pm2 restart analyst-scheduler

# 중지
pm2 stop analyst-scheduler

# 제거
pm2 delete analyst-scheduler

# 시스템 재부팅 시 자동 시작
pm2 startup
pm2 save
```

## ⚠️ 주의사항

1. **절대 여러 터미널에서 동시 실행 금지**
2. **PM2 사용 시 직접 실행 금지** (둘 중 하나만)
3. **일일 제한 도달 시 다음날까지 자동 대기**
4. **Lock 파일 수동 삭제는 정말 필요할 때만**

## 📊 비용 최적화 팁

1. **필수 자산만 활성화** - 20개 대신 10개로 줄이면 절반
2. **시간프레임 조정** - 15m 대신 30m 시작으로 절반
3. **모델 선택** - gpt-4o-mini 유지 (gpt-4o는 10배 비쌈)
4. **개장 시간만 실행** - 주식은 미국 개장 시간만
