import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

// 환경변수 로드 (.env.local 우선)
dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing environment variables in .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

interface TestScenario {
  name: string;
  symbol: string;
  direction: 'UP' | 'DOWN';
  amount: number;
  timeframe: string;
  targetPercent: number;
}

interface SimulationResult {
  timestamp: string;
  user: string;
  scenario: string;
  success: boolean;
  predictionId?: string;
  remainingPoints?: number;
  error?: string;
}

const testUsers = [
  { email: 'test1@mail.com', password: '123456', name: 'Test1' },
  { email: 'test2@mail.com', password: '123456', name: 'Test2' },
  { email: 'test3@mail.com', password: '123456', name: 'Test3' },
  { email: 'test4@mail.com', password: '123456', name: 'Test4' },
  { email: 'test5@mail.com', password: '123456', name: 'Test5' },
];

const testScenarios: TestScenario[] = [
  { name: 'BTC 1m UP 0.5%', symbol: 'BTC', direction: 'UP', amount: 50, timeframe: '1m', targetPercent: 0.5 },
  { name: 'ETH 1m DOWN 1.0%', symbol: 'ETH', direction: 'DOWN', amount: 100, timeframe: '1m', targetPercent: 1.0 },
  { name: 'BTC 5m UP 1.5%', symbol: 'BTC', direction: 'UP', amount: 200, timeframe: '5m', targetPercent: 1.5 },
];

async function runSimulation(user: any, scenario: TestScenario): Promise<SimulationResult> {
  console.log(`👤 [${user.name}] Attempting: ${scenario.name}...`);

  try {
    // 1. 로그인
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: user.email,
      password: user.password,
    });

    if (authError || !authData.session) {
      throw new Error(`Login failed: ${authError?.message}`);
    }

    const { user: supabaseUser } = authData.session;

    // 2. 시세 조회 (예시용 고정가)
    const entryPrice = scenario.symbol === 'BTC' ? 65432.1 : 3210.5;

    // 3. submit_prediction RPC 호출
    const { data: rpcData, error: rpcError } = await supabase.rpc('submit_prediction', {
      p_user_id: supabaseUser.id,
      p_asset_symbol: scenario.symbol,
      p_timeframe: scenario.timeframe,
      p_direction: scenario.direction,
      p_target_percent: scenario.targetPercent,
      p_entry_price: entryPrice,
      p_bet_amount: scenario.amount
    });

    if (rpcError) {
      throw new Error(`RPC Failed: ${rpcError.message}`);
    }

    if (rpcData && rpcData.success) {
      console.log(`   ✅ Success! Prediction ID: ${rpcData.prediction_id}, Remaining: ${rpcData.new_points}pt`);
      return {
        timestamp: new Date().toISOString(),
        user: user.name,
        scenario: scenario.name,
        success: true,
        predictionId: rpcData.prediction_id,
        remainingPoints: rpcData.new_points
      };
    } else {
      throw new Error(rpcData?.error || 'Unknown error');
    }

  } catch (error: any) {
    console.error(`   ❌ Failed: ${error.message}`);
    return {
      timestamp: new Date().toISOString(),
      user: user.name,
      scenario: scenario.name,
      success: false,
      error: error.message
    };
  }
}

function saveResults(results: SimulationResult[], startTime: string, summary: any) {
  const reportDir = path.join(process.cwd(), 'simulator', 'result');
  
  // 디렉토리 생성
  if (!fs.existsSync(reportDir)) {
    fs.mkdirSync(reportDir, { recursive: true });
  }

  const timestamp = startTime.replace(/[:.]/g, '-').replace('T', '_').split('.')[0];
  
  // 1. JSON 파일 저장
  const jsonPath = path.join(reportDir, `simulation_${timestamp}.json`);
  fs.writeFileSync(jsonPath, JSON.stringify({
    startTime,
    endTime: new Date().toISOString(),
    summary,
    details: results
  }, null, 2));
  console.log(`\n💾 JSON saved: ${jsonPath}`);

  // 2. CSV 파일 저장
  const csvPath = path.join(reportDir, `simulation_${timestamp}.csv`);
  const csvHeader = 'Timestamp,User,Scenario,Success,Prediction ID,Remaining Points,Error\n';
  const csvRows = results.map(r => 
    `${r.timestamp},${r.user},"${r.scenario}",${r.success},${r.predictionId || ''},${r.remainingPoints || ''},${r.error || ''}`
  ).join('\n');
  fs.writeFileSync(csvPath, csvHeader + csvRows);
  console.log(`💾 CSV saved: ${csvPath}`);

  // 3. HTML 리포트 생성
  const htmlPath = path.join(reportDir, `simulation_${timestamp}.html`);
  const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Simulation Report - ${timestamp}</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
    .summary { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 20px 0; }
    .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; }
    .stat-card.success { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); }
    .stat-card.fail { background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%); }
    .stat-card h3 { margin: 0; font-size: 14px; opacity: 0.9; }
    .stat-card .number { font-size: 36px; font-weight: bold; margin: 10px 0; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #4CAF50; color: white; font-weight: bold; }
    tr:hover { background: #f5f5f5; }
    .success-row { color: #4CAF50; }
    .fail-row { color: #f44336; }
    .timestamp { font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎮 Simulation Report</h1>
    <p class="timestamp">Generated: ${new Date().toLocaleString()}</p>
    
    <div class="summary">
      <div class="stat-card">
        <h3>Total Tests</h3>
        <div class="number">${summary.total}</div>
      </div>
      <div class="stat-card success">
        <h3>✅ Success</h3>
        <div class="number">${summary.success}</div>
        <p>${summary.successRate}</p>
      </div>
      <div class="stat-card fail">
        <h3>❌ Failed</h3>
        <div class="number">${summary.fail}</div>
      </div>
    </div>

    <h2>📋 Detailed Results</h2>
    <table>
      <thead>
        <tr>
          <th>Time</th>
          <th>User</th>
          <th>Scenario</th>
          <th>Result</th>
          <th>Remaining Points</th>
          <th>Prediction ID</th>
        </tr>
      </thead>
      <tbody>
        ${results.map(r => `
          <tr class="${r.success ? 'success-row' : 'fail-row'}">
            <td>${new Date(r.timestamp).toLocaleTimeString()}</td>
            <td>${r.user}</td>
            <td>${r.scenario}</td>
            <td>${r.success ? '✅ Success' : '❌ ' + (r.error || 'Failed')}</td>
            <td>${r.remainingPoints || '-'}</td>
            <td style="font-family: monospace; font-size: 10px;">${r.predictionId?.substring(0, 8) || '-'}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  </div>
</body>
</html>
  `;
  fs.writeFileSync(htmlPath, html);
  console.log(`💾 HTML saved: ${htmlPath}\n`);

  return { jsonPath, csvPath, htmlPath };
}

async function main() {
  const startTime = new Date().toISOString();
  console.log('🚀 Starting V3 Simulation (submit_prediction RPC)...');
  console.log(`📅 Started at: ${new Date(startTime).toLocaleString()}\n`);

  const results: SimulationResult[] = [];
  let successCount = 0;
  let failCount = 0;

  for (const user of testUsers) {
    console.log('-'.repeat(60));
    for (const scenario of testScenarios) {
      const result = await runSimulation(user, scenario);
      results.push(result);
      
      if (result.success) successCount++; 
      else failCount++;
      
      // 연속 요청 방지
      await new Promise(r => setTimeout(r, 500));
    }
  }

  const summary = {
    total: successCount + failCount,
    success: successCount,
    fail: failCount,
    successRate: `${(successCount / (successCount + failCount) * 100).toFixed(1)}%`
  };

  console.log('\n' + '='.repeat(60));
  console.log('📊 SIMULATION REPORT');
  console.log(`Total: ${summary.total}, Success: ${summary.success}, Fail: ${summary.fail}`);
  console.log(`Success Rate: ${summary.successRate}`);
  console.log('='.repeat(60));

  // 결과 파일 저장
  const paths = saveResults(results, startTime, summary);

  console.log('💡 Predictions are now in "pending" status.');
  console.log('💡 They will be auto-resolved by Cron or AutoResolver when candles close.\n');
  
  console.log('📁 Results saved to:');
  console.log(`   JSON: ${paths.jsonPath}`);
  console.log(`   CSV:  ${paths.csvPath}`);
  console.log(`   HTML: ${paths.htmlPath}\n`);
}

main().catch(console.error);

