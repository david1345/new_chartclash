#!/usr/bin/env bash
# ============================================================
#  ChartClash - 전체 QA + 부하 테스트 마스터 실행 스크립트
#  결과 파일: simulator/result/qa_YYYYMMDD_HHMMSS.res
#             simulator/result/load_YYYYMMDD_HHMMSS.res
#  사용법:
#    ./run-tests.sh              (QA + 부하 테스트 전체)
#    ./run-tests.sh --qa-only    (QA 테스트만)
#    ./run-tests.sh --load-only  (부하 테스트만)
#    ./run-tests.sh --headed     (브라우저 보이면서 실행)
#    LOAD_USERS=20 ./run-tests.sh (동시 사용자 20명)
# ============================================================

# ─── 색상 설정 ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── 기본 설정 ───────────────────────────────────────────────
BASE_URL="${BASE_URL:-http://localhost:3000}"
LOAD_USERS="${LOAD_USERS:-10}"
TEST_EMAIL="${TEST_EMAIL:-test1@mail.com}"
TEST_PASSWORD="${TEST_PASSWORD:-123456}"
RUN_MODE="${1:-all}"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
SIMULATOR_DIR="$PROJECT_ROOT/simulator"
RESULT_DIR="$SIMULATOR_DIR/result"
DATESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$RESULT_DIR"

# .res 파일 경로
QA_RES="$RESULT_DIR/qa_${DATESTAMP}.res"
LOAD_RES="$RESULT_DIR/load_${DATESTAMP}.res"

echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     ChartClash QA + 부하 테스트 실행 스크립트      ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 설정:${NC}"
echo -e "   Base URL    : ${BASE_URL}"
echo -e "   동시 사용자  : ${LOAD_USERS}명"
echo -e "   실행 모드    : ${RUN_MODE}"
echo -e "   결과 저장    : ${RESULT_DIR}/"
echo ""

# ─── 서버 상태 확인 ──────────────────────────────────────────
echo -e "${YELLOW}🔍 서버 상태 확인 중...${NC}"
DEV_PID=""

if curl -s --max-time 3 "${BASE_URL}" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 서버가 이미 실행 중: ${BASE_URL}${NC}"
else
    echo -e "${YELLOW}⚠️  서버 없음 → 개발 서버 자동 시작...${NC}"
    cd "$PROJECT_ROOT"
    npm run dev > /tmp/chartclash-dev.log 2>&1 &
    DEV_PID=$!

    MAX_WAIT=60
    COUNT=0
    until curl -s --max-time 2 "${BASE_URL}" > /dev/null 2>&1; do
        COUNT=$((COUNT + 1))
        if [ $COUNT -ge $MAX_WAIT ]; then
            echo -e "${RED}❌ 서버 시작 실패 (60초 초과). 종료합니다.${NC}"
            kill $DEV_PID 2>/dev/null
            exit 1
        fi
        echo -ne "   대기 중... ${COUNT}/${MAX_WAIT}초\r"
        sleep 1
    done
    echo -e "\n${GREEN}✅ 개발 서버 시작 완료 (${COUNT}초 소요)${NC}"
fi

# ─── .res 파일 헤더 작성 함수 ────────────────────────────────
write_res_header() {
    local FILE="$1"
    local TYPE="$2"  # qa | load
    cat > "$FILE" << EOF
========================================================
ChartClash 테스트 결과 파일
종류    : ${TYPE}
날짜    : $(date +"%Y-%m-%d %H:%M:%S")
대상URL : ${BASE_URL}
사용자수: ${LOAD_USERS}명 (부하 테스트 시)
========================================================

EOF
}

# ─── QA 테스트 실행 ──────────────────────────────────────────
run_qa_tests() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  1단계: 전체 QA 테스트 (정상 + 에러 케이스)${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📝 결과 파일: $(basename "$QA_RES")${NC}"

    write_res_header "$QA_RES" "QA (정상+에러 케이스)"

    QA_EXTRA_FLAGS=""
    [ "$RUN_MODE" = "--headed" ] && QA_EXTRA_FLAGS="--headed"

    cd "$SIMULATOR_DIR"

    # 테스트 실행 + 출력을 화면과 .res 파일 동시 기록
    {
        BASE_URL="$BASE_URL" \
        TEST_EMAIL="$TEST_EMAIL" \
        TEST_PASSWORD="$TEST_PASSWORD" \
        npx playwright test e2e/qa-full.test.ts \
            --reporter=list \
            $QA_EXTRA_FLAGS 2>&1
    } | tee -a "$QA_RES"
    QA_EXIT=${PIPESTATUS[0]}

    # 결과 판정
    if [ $QA_EXIT -eq 0 ]; then
        QA_VERDICT="PASSED"
    else
        QA_VERDICT="FAILED"
    fi

    # 결과 요약을 .res 파일 하단에 추가
    {
        echo ""
        echo "========================================================"
        echo "최종 판정 : ${QA_VERDICT}"
        echo "완료 시각 : $(date +"%Y-%m-%d %H:%M:%S")"
        echo "========================================================"
    } >> "$QA_RES"

    if [ "$QA_VERDICT" = "PASSED" ]; then
        echo -e "${GREEN}✅ QA 테스트 PASSED → $(basename "$QA_RES")${NC}"
    else
        echo -e "${RED}❌ QA 테스트 FAILED → $(basename "$QA_RES")${NC}"
    fi
}

# ─── 부하 테스트 실행 ────────────────────────────────────────
run_load_tests() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  2단계: 부하 테스트 (동시 ${LOAD_USERS}명 시뮬레이션)${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📝 결과 파일: $(basename "$LOAD_RES")${NC}"

    write_res_header "$LOAD_RES" "LOAD (부하/스트레스/벤치마크)"

    cd "$SIMULATOR_DIR"

    {
        BASE_URL="$BASE_URL" \
        LOAD_USERS="$LOAD_USERS" \
        npx playwright test e2e/load.test.ts \
            --reporter=list \
            --workers=4 2>&1
    } | tee -a "$LOAD_RES"
    LOAD_EXIT=${PIPESTATUS[0]}

    if [ $LOAD_EXIT -eq 0 ]; then
        LOAD_VERDICT="PASSED"
    else
        LOAD_VERDICT="FAILED"
    fi

    {
        echo ""
        echo "========================================================"
        echo "최종 판정 : ${LOAD_VERDICT}"
        echo "동시 사용자: ${LOAD_USERS}명"
        echo "완료 시각 : $(date +"%Y-%m-%d %H:%M:%S")"
        echo "========================================================"
    } >> "$LOAD_RES"

    if [ "$LOAD_VERDICT" = "PASSED" ]; then
        echo -e "${GREEN}✅ 부하 테스트 PASSED → $(basename "$LOAD_RES")${NC}"
    else
        echo -e "${RED}❌ 부하 테스트 FAILED → $(basename "$LOAD_RES")${NC}"
    fi
}

# ─── 모드별 실행 ─────────────────────────────────────────────
case "$RUN_MODE" in
    "--qa-only")
        run_qa_tests
        ;;
    "--load-only")
        run_load_tests
        ;;
    *)
        run_qa_tests
        run_load_tests
        ;;
esac

# ─── 최종 요약 출력 ──────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                  ✅ 결과 파일 저장 완료             ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

[ -f "$QA_RES" ]   && echo -e "  📄 QA 결과    : ${QA_RES}"
[ -f "$LOAD_RES" ] && echo -e "  📄 부하 결과  : ${LOAD_RES}"
echo ""
echo -e "${YELLOW}💡 결과 파일 열기 예시:${NC}"
[ -f "$QA_RES" ]   && echo -e "   cat $(basename "$QA_RES")"
[ -f "$LOAD_RES" ] && echo -e "   cat $(basename "$LOAD_RES")"
echo ""
echo -e "${YELLOW}💡 전체 결과 목록 보기:${NC}"
echo -e "   ls -lh ${RESULT_DIR}/*.res"
echo ""

# ─── 개발 서버 정리 ──────────────────────────────────────────
if [ -n "$DEV_PID" ]; then
    echo -e "${YELLOW}🛑 개발 서버 종료 중 (PID: ${DEV_PID})...${NC}"
    kill $DEV_PID 2>/dev/null || true
fi
