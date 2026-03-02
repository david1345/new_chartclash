/**
 * AI 분석가 데이터 이관 스크립트
 * DEV → PROD
 *
 * 실행: npx tsx scripts/migrate_analyst_data.ts
 *
 * DEV DB:  .env.local (NEXT_PUBLIC_SUPABASE_URL)
 * PROD DB: .env       (NEXT_PUBLIC_SUPABASE_URL from vercel env pull)
 */
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

// ─── DEV 연결 (.env) - 분석가 데이터 있는 개발 DB ──────────
const devEnv = dotenv.parse(fs.readFileSync('.env', 'utf8'));
const devSupabase = createClient(
    devEnv.NEXT_PUBLIC_SUPABASE_URL,
    devEnv.SUPABASE_SERVICE_ROLE_KEY
);

// ─── PROD 연결 (.env.local) - vercel env pull로 업데이트된 운영 DB
const prodEnv = dotenv.parse(fs.readFileSync('.env.local', 'utf8'));
const prodSupabase = createClient(
    prodEnv.NEXT_PUBLIC_SUPABASE_URL,
    prodEnv.SUPABASE_SERVICE_ROLE_KEY
);

const ANALYST_NAMES = [
    'Analyst_Momentum', 'Analyst_RSI', 'Analyst_Reversal',
    'Analyst_Trend', 'Analyst_Breakout', 'Analyst_Volatility',
    'Analyst_Volume', 'Analyst_Levels', 'Analyst_Regime', 'Analyst_Correlation'
];

const BATCH_SIZE = 200;
const DRY_RUN = process.argv.includes('--dry-run');

// candle_close_at 계산: created_at + timeframe → 다음 캔들 마감 시각
function candleCloseAt(createdAt: string, timeframe: string): string {
    const d = new Date(createdAt);
    const ms = d.getTime();

    const tfMap: Record<string, number> = {
        '1m': 1 * 60 * 1000,
        '5m': 5 * 60 * 1000,
        '15m': 15 * 60 * 1000,
        '30m': 30 * 60 * 1000,
        '1h': 60 * 60 * 1000,
        '4h': 4 * 60 * 60 * 1000,
        '1d': 24 * 60 * 60 * 1000,
    };
    const interval = tfMap[timeframe] ?? tfMap['1h'];
    const closeMs = Math.ceil(ms / interval) * interval;
    return new Date(closeMs).toISOString();
}

console.log(`\n${'='.repeat(60)}`);
console.log('AI 분석가 데이터 이관: DEV → PROD');
console.log(`DEV:  ${devEnv.NEXT_PUBLIC_SUPABASE_URL}`);
console.log(`PROD: ${prodEnv.NEXT_PUBLIC_SUPABASE_URL}`);
console.log(`모드: ${DRY_RUN ? '🔍 DRY RUN (실제 저장 안 함)' : '🚀 실제 이관'}`);
console.log('='.repeat(60));

async function migrate() {
    // ─── 1. DEV에서 분석가 프로필 조회 ──────────────────────
    console.log('\n[1/4] DEV에서 분석가 프로필 조회 중...');
    const { data: devProfiles, error: profErr } = await devSupabase
        .from('profiles')
        .select('id, username, tier, total_wins, total_games, points')
        .in('username', ANALYST_NAMES);

    if (profErr || !devProfiles?.length) {
        console.error('❌ 프로필 조회 실패:', profErr?.message);
        // username LIKE로 재시도
        const { data: likeProfiles } = await devSupabase
            .from('profiles')
            .select('id, username, tier, total_wins, total_games, points')
            .ilike('username', 'Analyst_%');
        if (!likeProfiles?.length) {
            console.error('❌ Analyst_ 패턴 프로필도 없음. 종료.');
            process.exit(1);
        }
        devProfiles?.push(...(likeProfiles || []));
    }

    console.log(`  ✅ ${devProfiles!.length}개 분석가 프로필 발견`);
    devProfiles!.forEach(p => console.log(`     - ${p.username} (${p.id})`));

    // ─── 2. PROD에서 분석가 프로필 생성/확인 ─────────────────
    console.log('\n[2/4] PROD에 분석가 프로필 생성 중...');

    // DEV 프로필 ID → PROD 새 프로필 ID 맵핑
    const idMap: Record<string, string> = {};

    for (const devProfile of devProfiles!) {
        // PROD에 같은 username 있는지 확인
        const { data: existing } = await prodSupabase
            .from('profiles')
            .select('id')
            .eq('username', devProfile.username)
            .single();

        if (existing) {
            idMap[devProfile.id] = existing.id;
            console.log(`  ⏭️  ${devProfile.username} → 이미 존재 (${existing.id})`);
            continue;
        }

        if (DRY_RUN) {
            console.log(`  🔍 [DRY] ${devProfile.username} → 생성 예정`);
            idMap[devProfile.id] = `dry-run-${devProfile.id}`;
            continue;
        }

        // auth.users에 봇 계정 생성 (service_role 필요)
        const botEmail = `${devProfile.username.toLowerCase()}@chartclash.bot`;
        const { data: authUser, error: authErr } = await prodSupabase.auth.admin.createUser({
            email: botEmail,
            password: `Bot${Math.random().toString(36).slice(2)}!`,
            email_confirm: true,
            user_metadata: { username: devProfile.username, is_bot: true }
        });

        if (authErr || !authUser.user) {
            console.error(`  ❌ ${devProfile.username} auth 생성 실패:`, authErr?.message);
            continue;
        }

        // profiles 테이블에 삽입
        const { error: profileErr } = await prodSupabase
            .from('profiles')
            .upsert({
                id: authUser.user.id,
                username: devProfile.username,
                tier: devProfile.tier || 'DIAMOND',
                total_wins: devProfile.total_wins || 0,
                total_games: devProfile.total_games || 0,
                points: devProfile.points || 1000,
                is_bot: true,
                bot_persona: devProfile.username.replace('Analyst_', '')
            });

        if (profileErr) {
            console.error(`  ❌ ${devProfile.username} profile 생성 실패:`, profileErr.message);
            continue;
        }

        idMap[devProfile.id] = authUser.user.id;
        console.log(`  ✅ ${devProfile.username} → ${authUser.user.id}`);
    }

    // ─── 3. DEV에서 예측 데이터 조회 ─────────────────────────
    console.log('\n[3/4] DEV에서 예측 데이터 조회 중...');
    const devUserIds = devProfiles!.map(p => p.id);

    // 최근 7일치만 이관 (너무 오래된 데이터 제외)
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    let allPredictions: any[] = [];
    let offset = 0;
    while (true) {
        const { data: batch, error } = await devSupabase
            .from('predictions')
            .select('asset_symbol, timeframe, direction, target_percent, entry_price, status, profit, comment, created_at, resolved_at, is_opinion, likes_count, user_id, bet_amount')
            .in('user_id', devUserIds)
            .gte('created_at', sevenDaysAgo)
            .range(offset, offset + BATCH_SIZE - 1)
            .order('created_at', { ascending: false });

        if (error) { console.error('조회 에러:', error.message); break; }
        if (!batch?.length) break;

        allPredictions.push(...batch);
        offset += BATCH_SIZE;
        process.stdout.write(`\r  조회 중... ${allPredictions.length}개`);
    }
    console.log(`\n  ✅ 총 ${allPredictions.length}개 예측 조회 완료`);

    if (DRY_RUN) {
        console.log('\n🔍 DRY RUN 완료. --dry-run 없이 재실행하면 실제 이관됩니다.');
        return;
    }

    // ─── 4. PROD에 삽입 ──────────────────────────────────────
    console.log('\n[4/4] PROD에 예측 데이터 삽입 중...');

    // user_id를 PROD ID로 변환
    const prodPredictions = allPredictions
        .filter(p => idMap[p.user_id]) // 맵핑된 것만
        .map(p => ({
            user_id: idMap[p.user_id],
            asset_symbol: p.asset_symbol,
            timeframe: p.timeframe,
            direction: p.direction,
            target_percent: p.target_percent,
            entry_price: p.entry_price,
            status: p.status,
            profit: p.profit,
            comment: p.comment ? p.comment.trim().slice(0, 500) || null : null,
            created_at: p.created_at,
            resolved_at: p.resolved_at,
            bet_amount: p.bet_amount ?? 100,
            candle_close_at: candleCloseAt(p.created_at, p.timeframe),
            is_opinion: true,
            channel: 'analyst_hub',
            likes_count: p.likes_count || 0
        }));

    console.log(`  삽입 대상: ${prodPredictions.length}개`);

    let inserted = 0;
    let failed = 0;
    for (let i = 0; i < prodPredictions.length; i += BATCH_SIZE) {
        const chunk = prodPredictions.slice(i, i + BATCH_SIZE);
        const { error } = await prodSupabase
            .from('predictions')
            .insert(chunk);

        if (error) {
            console.error(`  ❌ 배치 ${i}-${i + BATCH_SIZE} 실패:`, error.message);
            failed += chunk.length;
        } else {
            inserted += chunk.length;
        }
        process.stdout.write(`\r  삽입 중... ${inserted}/${prodPredictions.length}개 ✅`);
    }

    console.log(`\n\n${'='.repeat(60)}`);
    console.log(`✅ 이관 완료!`);
    console.log(`   성공: ${inserted}개`);
    console.log(`   실패: ${failed}개`);
    console.log('='.repeat(60));
}

migrate().catch(e => {
    console.error('치명적 오류:', e);
    process.exit(1);
});
