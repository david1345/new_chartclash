import { execSync } from 'child_process';
import chalk from 'chalk'; // I'll assume chalk is available or I'll just use escape characters

const colors = {
    reset: "\x1b[0m",
    green: "\x1b[32m",
    red: "\x1b[31m",
    yellow: "\x1b[33m",
    cyan: "\x1b[36m",
    bold: "\x1b[1m"
};

function runCommand(name: string, command: string) {
    console.log(`${colors.cyan}${colors.bold}>>> Running ${name}...${colors.reset}`);
    try {
        const output = execSync(command, { stdio: 'inherit', env: { ...process.env, PATH: `${process.env.PATH}:/opt/homebrew/bin:/usr/local/bin` } });
        console.log(`${colors.green}✅ ${name} Passed!${colors.reset}\n`);
        return true;
    } catch (error) {
        console.error(`${colors.red}❌ ${name} Failed!${colors.reset}\n`);
        return false;
    }
}

async function main() {
    console.log(`${colors.bold}==========================================`);
    console.log(`🚀 VATS: ChartClash Automated Test Suite`);
    console.log(`==========================================${colors.reset}\n`);

    const startTime = Date.now();

    // 1. Logic & Integration Tests
    const integrationSuccess = runCommand('Integration Tests (Fairness Logic)', 'npx vitest run --config vitest.config.ts src/test/integration');

    // 2. UI & E2E Tests
    const e2eSuccess = runCommand('E2E Browser Tests (UI/UX)', 'npx playwright test --config playwright.config.ts src/test/e2e');

    const duration = ((Date.now() - startTime) / 1000).toFixed(1);

    console.log(`${colors.bold}==========================================`);
    console.log(`📊 FINAL TEST REPORT`);
    console.log(`==========================================`);
    console.log(`Integration: ${integrationSuccess ? colors.green + 'PASSED ✅' : colors.red + 'FAILED ❌'}${colors.reset}`);
    console.log(`E2E Browser: ${e2eSuccess ? colors.green + 'PASSED ✅' : colors.red + 'FAILED ❌'}${colors.reset}`);
    console.log(`------------------------------------------`);
    console.log(`Total Duration: ${duration}s`);
    console.log(`==========================================${colors.reset}\n`);

    if (!integrationSuccess || !e2eSuccess) {
        process.exit(1);
    }
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
