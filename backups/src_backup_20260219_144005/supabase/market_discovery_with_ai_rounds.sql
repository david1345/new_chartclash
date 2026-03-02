-- Market Discovery Functions - AI 분석 기반 라운드 생성
-- AI 분석이 있으면 유저 참여 없어도 라운드 표시 (기본 10명/100pts)

-- 1. Get live rounds with AI-based creation
CREATE OR REPLACE FUNCTION get_live_rounds_with_stats(
    p_category TEXT DEFAULT 'CRYPTO',
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    asset_symbol TEXT,
    timeframe TEXT,
    asset_name TEXT,
    asset_type TEXT,
    participant_count BIGINT,
    total_volume BIGINT,
    ai_direction TEXT,
    ai_confidence NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH all_possible_rounds AS (
        -- 30 assets × 5 timeframes = 150 possible rounds
        SELECT
            asset.symbol as asset_symbol,
            tf.timeframe,
            asset.name as asset_name,
            asset.type as asset_type
        FROM (VALUES
            -- CRYPTO (11)
            ('BTCUSDT', 'Bitcoin', 'CRYPTO'),
            ('ETHUSDT', 'Ethereum', 'CRYPTO'),
            ('SOLUSDT', 'Solana', 'CRYPTO'),
            ('XRPUSDT', 'XRP', 'CRYPTO'),
            ('DOGEUSDT', 'Dogecoin', 'CRYPTO'),
            ('ADAUSDT', 'Cardano', 'CRYPTO'),
            ('AVAXUSDT', 'Avalanche', 'CRYPTO'),
            ('DOTUSDT', 'Polkadot', 'CRYPTO'),
            ('LINKUSDT', 'Chainlink', 'CRYPTO'),
            ('MATICUSDT', 'Polygon', 'CRYPTO'),
            ('UNIUSDT', 'Uniswap', 'CRYPTO'),
            -- STOCKS (10)
            ('AAPL', 'Apple', 'STOCKS'),
            ('NVDA', 'NVIDIA', 'STOCKS'),
            ('TSLA', 'Tesla', 'STOCKS'),
            ('MSFT', 'Microsoft', 'STOCKS'),
            ('AMZN', 'Amazon', 'STOCKS'),
            ('GOOGL', 'Google', 'STOCKS'),
            ('META', 'Meta', 'STOCKS'),
            ('NFLX', 'Netflix', 'STOCKS'),
            ('AMD', 'AMD', 'STOCKS'),
            ('INTC', 'Intel', 'STOCKS'),
            -- COMMODITIES (9)
            ('XAUUSD', 'Gold', 'COMMODITIES'),
            ('XAGUSD', 'Silver', 'COMMODITIES'),
            ('WTI', 'Oil (WTI)', 'COMMODITIES'),
            ('NG', 'Natural Gas', 'COMMODITIES'),
            ('CORN', 'Corn', 'COMMODITIES'),
            ('SOY', 'Soybeans', 'COMMODITIES'),
            ('WHEAT', 'Wheat', 'COMMODITIES'),
            ('HG', 'Copper', 'COMMODITIES'),
            ('PL', 'Platinum', 'COMMODITIES'),
            ('PA', 'Palladium', 'COMMODITIES')
        ) AS asset(symbol, name, type)
        CROSS JOIN (VALUES ('15m'), ('30m'), ('1h'), ('4h'), ('1d')) AS tf(timeframe)
        WHERE p_category = 'ALL' OR asset.type = p_category
    ),
    user_predictions AS (
        -- 실제 유저 예측 집계
        SELECT
            p.asset_symbol,
            p.timeframe,
            COUNT(DISTINCT p.user_id) as user_count,
            COALESCE(SUM(p.bet_amount), 0) as user_volume
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND (prof.is_bot = false OR prof.is_bot IS NULL)
        GROUP BY p.asset_symbol, p.timeframe
    ),
    ai_predictions AS (
        -- AI 분석 집계 (다수결 방향 + 평균 확률)
        SELECT
            p.asset_symbol,
            p.timeframe,
            COUNT(DISTINCT p.user_id) as ai_count,
            COALESCE(SUM(p.bet_amount), 0) as ai_volume,
            MODE() WITHIN GROUP (ORDER BY p.direction) as ai_direction,
            ROUND(AVG(p.target_percent)) as ai_confidence
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND prof.is_bot = true
            AND prof.username LIKE 'Analyst_%'
        GROUP BY p.asset_symbol, p.timeframe
    )
    SELECT
        apr.asset_symbol,
        apr.timeframe,
        apr.asset_name,
        apr.asset_type,
        -- 유저 수 + AI 수 (AI가 있으면 최소 10)
        COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0) as participant_count,
        -- 유저 볼륨 + AI 볼륨
        COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0) as total_volume,
        ai.ai_direction,
        ai.ai_confidence
    FROM all_possible_rounds apr
    LEFT JOIN user_predictions up ON apr.asset_symbol = up.asset_symbol AND apr.timeframe = up.timeframe
    LEFT JOIN ai_predictions ai ON apr.asset_symbol = ai.asset_symbol AND apr.timeframe = ai.timeframe
    -- AI 분석이 있거나 유저 참여가 있으면 표시
    WHERE ai.ai_count > 0 OR up.user_count > 0
    ORDER BY
        -- AI + 유저 볼륨 합계로 정렬
        (COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0)) DESC,
        (COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0)) DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 2. Get trending assets by category (top 1 per category)
CREATE OR REPLACE FUNCTION get_trending_by_category()
RETURNS TABLE (
    asset_symbol TEXT,
    timeframe TEXT,
    asset_name TEXT,
    asset_type TEXT,
    participant_count BIGINT,
    total_volume BIGINT,
    ai_direction TEXT,
    ai_confidence NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH all_possible_rounds AS (
        SELECT
            asset.symbol as asset_symbol,
            tf.timeframe,
            asset.name as asset_name,
            asset.type as asset_type
        FROM (VALUES
            -- CRYPTO (11)
            ('BTCUSDT', 'Bitcoin', 'CRYPTO'),
            ('ETHUSDT', 'Ethereum', 'CRYPTO'),
            ('SOLUSDT', 'Solana', 'CRYPTO'),
            ('XRPUSDT', 'XRP', 'CRYPTO'),
            ('DOGEUSDT', 'Dogecoin', 'CRYPTO'),
            ('ADAUSDT', 'Cardano', 'CRYPTO'),
            ('AVAXUSDT', 'Avalanche', 'CRYPTO'),
            ('DOTUSDT', 'Polkadot', 'CRYPTO'),
            ('LINKUSDT', 'Chainlink', 'CRYPTO'),
            ('MATICUSDT', 'Polygon', 'CRYPTO'),
            ('UNIUSDT', 'Uniswap', 'CRYPTO'),
            -- STOCKS (10)
            ('AAPL', 'Apple', 'STOCKS'),
            ('NVDA', 'NVIDIA', 'STOCKS'),
            ('TSLA', 'Tesla', 'STOCKS'),
            ('MSFT', 'Microsoft', 'STOCKS'),
            ('AMZN', 'Amazon', 'STOCKS'),
            ('GOOGL', 'Google', 'STOCKS'),
            ('META', 'Meta', 'STOCKS'),
            ('NFLX', 'Netflix', 'STOCKS'),
            ('AMD', 'AMD', 'STOCKS'),
            ('INTC', 'Intel', 'STOCKS'),
            -- COMMODITIES (9)
            ('XAUUSD', 'Gold', 'COMMODITIES'),
            ('XAGUSD', 'Silver', 'COMMODITIES'),
            ('WTI', 'Oil (WTI)', 'COMMODITIES'),
            ('NG', 'Natural Gas', 'COMMODITIES'),
            ('CORN', 'Corn', 'COMMODITIES'),
            ('SOY', 'Soybeans', 'COMMODITIES'),
            ('WHEAT', 'Wheat', 'COMMODITIES'),
            ('HG', 'Copper', 'COMMODITIES'),
            ('PL', 'Platinum', 'COMMODITIES'),
            ('PA', 'Palladium', 'COMMODITIES')
        ) AS asset(symbol, name, type)
        CROSS JOIN (VALUES ('15m'), ('30m'), ('1h'), ('4h'), ('1d')) AS tf(timeframe)
    ),
    user_predictions AS (
        SELECT
            p.asset_symbol,
            p.timeframe,
            COUNT(DISTINCT p.user_id) as user_count,
            COALESCE(SUM(p.bet_amount), 0) as user_volume
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND (prof.is_bot = false OR prof.is_bot IS NULL)
        GROUP BY p.asset_symbol, p.timeframe
    ),
    ai_predictions AS (
        SELECT
            p.asset_symbol,
            p.timeframe,
            COUNT(DISTINCT p.user_id) as ai_count,
            COALESCE(SUM(p.bet_amount), 0) as ai_volume,
            MODE() WITHIN GROUP (ORDER BY p.direction) as ai_direction,
            ROUND(AVG(p.target_percent)) as ai_confidence
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND prof.is_bot = true
            AND prof.username LIKE 'Analyst_%'
        GROUP BY p.asset_symbol, p.timeframe
    ),
    ranked_rounds AS (
        SELECT
            apr.asset_symbol,
            apr.timeframe,
            apr.asset_name,
            apr.asset_type,
            COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0) as participant_count,
            COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0) as total_volume,
            ai.ai_direction,
            ai.ai_confidence,
            ROW_NUMBER() OVER (
                PARTITION BY apr.asset_type
                ORDER BY
                    (COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0)) DESC,
                    (COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0)) DESC
            ) as rank
        FROM all_possible_rounds apr
        LEFT JOIN user_predictions up ON apr.asset_symbol = up.asset_symbol AND apr.timeframe = up.timeframe
        LEFT JOIN ai_predictions ai ON apr.asset_symbol = ai.asset_symbol AND apr.timeframe = ai.timeframe
        WHERE ai.ai_count > 0 OR up.user_count > 0
    )
    SELECT
        rr.asset_symbol,
        rr.timeframe,
        rr.asset_name,
        rr.asset_type,
        rr.participant_count,
        rr.total_volume,
        rr.ai_direction,
        rr.ai_confidence
    FROM ranked_rounds rr
    WHERE rr.rank = 1
    ORDER BY rr.total_volume DESC;
END;
$$ LANGUAGE plpgsql;
