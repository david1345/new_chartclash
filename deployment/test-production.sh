#!/bin/bash
# Production Testing Script
# Runs all tests against production environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}🚀 Production Environment Testing${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check required environment variables
if [ -z "$PROD_URL" ]; then
    echo -e "${RED}❌ Error: PROD_URL not set${NC}"
    echo "Usage: PROD_URL=https://your-app.vercel.app ./deployment/test-production.sh"
    exit 1
fi

if [ -z "$TEST_EMAIL" ]; then
    echo -e "${YELLOW}⚠️  Warning: TEST_EMAIL not set, using default${NC}"
    export TEST_EMAIL="test@example.com"
fi

if [ -z "$TEST_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Warning: TEST_PASSWORD not set, using default${NC}"
    export TEST_PASSWORD="TestPassword123!"
fi

echo -e "Target: ${GREEN}$PROD_URL${NC}"
echo -e "Email:  ${GREEN}$TEST_EMAIL${NC}"
echo ""

# Set test base URL
export TEST_BASE_URL=$PROD_URL

# Create results directory
mkdir -p simulator/e2e/results

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Step 1: Health Check${NC}"
echo -e "${GREEN}================================================${NC}"

# Simple health check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $PROD_URL)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Production is reachable (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}❌ Production returned HTTP $HTTP_CODE${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Step 2: QA Test Suite${NC}"
echo -e "${GREEN}================================================${NC}"
npm run test:qa
QA_EXIT=$?
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Step 3: Load Test Suite${NC}"
echo -e "${GREEN}================================================${NC}"
npm run test:load
LOAD_EXIT=$?
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Step 4: Critical Flow Test${NC}"
echo -e "${GREEN}================================================${NC}"
npm run test -- simulator/e2e/critical-flow.test.ts
CRITICAL_EXIT=$?
echo ""

# Summary
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}📊 Test Summary${NC}"
echo -e "${GREEN}================================================${NC}"

if [ $QA_EXIT -eq 0 ]; then
    echo -e "QA Tests:       ${GREEN}✅ PASSED${NC}"
else
    echo -e "QA Tests:       ${RED}❌ FAILED${NC}"
fi

if [ $LOAD_EXIT -eq 0 ]; then
    echo -e "Load Tests:     ${GREEN}✅ PASSED${NC}"
else
    echo -e "Load Tests:     ${RED}❌ FAILED${NC}"
fi

if [ $CRITICAL_EXIT -eq 0 ]; then
    echo -e "Critical Flow:  ${GREEN}✅ PASSED${NC}"
else
    echo -e "Critical Flow:  ${RED}❌ FAILED${NC}"
fi

echo ""
echo -e "Results saved in: ${GREEN}simulator/e2e/results/${NC}"
echo ""

# Exit with error if any test failed
if [ $QA_EXIT -ne 0 ] || [ $LOAD_EXIT -ne 0 ] || [ $CRITICAL_EXIT -ne 0 ]; then
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
fi
