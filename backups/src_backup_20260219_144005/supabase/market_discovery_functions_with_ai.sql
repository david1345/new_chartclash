-- Market Discovery Functions with AI Integration

-- 1. Get live rounds with statistics INCLUDING AI predictions
CREATE OR REPLACE FUNCTION get_live_rounds_with_stats(
    p_category TEXT DEFAULT 'ALL',
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
    WITH live_rounds AS (
        SELECT
            p.asset_symbol,
            p.timeframe,
            COALESCE(
                CASE
                    -- CRYPTO (11)
                    WHEN p.asset_symbol = 'BTCUSDT' THEN 'Bitcoin'
                    WHEN p.asset_symbol = 'ETHUSDT' THEN 'Ethereum'
                    WHEN p.asset_symbol = 'SOLUSDT' THEN 'Solana'
                    WHEN p.asset_symbol = 'XRPUSDT' THEN 'XRP'
                    WHEN p.asset_symbol = 'DOGEUSDT' THEN 'Dogecoin'
                    WHEN p.asset_symbol = 'ADAUSDT' THEN 'Cardano'
                    WHEN p.asset_symbol = 'AVAXUSDT' THEN 'Avalanche'
                    WHEN p.asset_symbol = 'DOTUSDT' THEN 'Polkadot'
                    WHEN p.asset_symbol = 'LINKUSDT' THEN 'Chainlink'
                    WHEN p.asset_symbol = 'MATICUSDT' THEN 'Polygon'
                    WHEN p.asset_symbol = 'UNIUSDT' THEN 'Uniswap'
                    -- STOCKS (10)
                    WHEN p.asset_symbol = 'AAPL' THEN 'Apple'
                    WHEN p.asset_symbol = 'NVDA' THEN 'NVIDIA'
                    WHEN p.asset_symbol = 'TSLA' THEN 'Tesla'
                    WHEN p.asset_symbol = 'MSFT' THEN 'Microsoft'
                    WHEN p.asset_symbol = 'AMZN' THEN 'Amazon'
                    WHEN p.asset_symbol = 'GOOGL' THEN 'Google'
                    WHEN p.asset_symbol = 'META' THEN 'Meta'
                    WHEN p.asset_symbol = 'NFLX' THEN 'Netflix'
                    WHEN p.asset_symbol = 'AMD' THEN 'AMD'
                    WHEN p.asset_symbol = 'INTC' THEN 'Intel'
                    -- COMMODITIES (9)
                    WHEN p.asset_symbol = 'XAUUSD' THEN 'Gold'
                    WHEN p.asset_symbol = 'XAGUSD' THEN 'Silver'
                    WHEN p.asset_symbol = 'WTI' THEN 'Oil (WTI)'
                    WHEN p.asset_symbol = 'NG' THEN 'Natural Gas'
                    WHEN p.asset_symbol = 'CORN' THEN 'Corn'
                    WHEN p.asset_symbol = 'SOY' THEN 'Soybeans'
                    WHEN p.asset_symbol = 'WHEAT' THEN 'Wheat'
                    WHEN p.asset_symbol = 'HG' THEN 'Copper'
                    WHEN p.asset_symbol = 'PL' THEN 'Platinum'
                    WHEN p.asset_symbol = 'PA' THEN 'Palladium'
                    ELSE p.asset_symbol
                END, p.asset_symbol
            ) as asset_name,
            CASE
                WHEN p.asset_symbol LIKE '%USDT' THEN 'CRYPTO'
                WHEN p.asset_symbol IN ('AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC') THEN 'STOCKS'
                ELSE 'COMMODITIES'
            END as asset_type,
            COUNT(DISTINCT p.user_id) as participant_count,
            COALESCE(SUM(p.bet_amount), 0) as total_volume
        FROM predictions p
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND (
                p_category = 'ALL' OR
                (p_category = 'CRYPTO' AND p.asset_symbol LIKE '%USDT') OR
                (p_category = 'STOCKS' AND p.asset_symbol IN ('AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC')) OR
                (p_category = 'COMMODITIES' AND p.asset_symbol NOT LIKE '%USDT' AND p.asset_symbol NOT IN ('AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC'))
            )
        GROUP BY p.asset_symbol, p.timeframe
    ),
    ai_predictions AS (
        -- Get the most common AI prediction for each round (majority vote)
        SELECT DISTINCT ON (p.asset_symbol, p.timeframe)
            p.asset_symbol,
            p.timeframe,
            p.direction as ai_direction,
            ROUND(AVG(p.target_percent) OVER (PARTITION BY p.asset_symbol, p.timeframe)) as ai_confidence
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND prof.is_bot = true
            AND prof.username LIKE 'Analyst_%'
        ORDER BY p.asset_symbol, p.timeframe, COUNT(*) OVER (PARTITION BY p.asset_symbol, p.timeframe, p.direction) DESC
    )
    SELECT
        lr.asset_symbol,
        lr.timeframe,
        lr.asset_name,
        lr.asset_type,
        lr.participant_count,
        lr.total_volume,
        COALESCE(ai.ai_direction, NULL::TEXT) as ai_direction,
        COALESCE(ai.ai_confidence, NULL::NUMERIC) as ai_confidence
    FROM live_rounds lr
    LEFT JOIN ai_predictions ai ON lr.asset_symbol = ai.asset_symbol AND lr.timeframe = ai.timeframe
    ORDER BY lr.total_volume DESC, lr.participant_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 2. Get trending assets by category (top 1 per category) - with AI
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
    WITH ranked_assets AS (
        SELECT
            p.asset_symbol,
            p.timeframe,
            COALESCE(
                CASE
                    -- CRYPTO (11)
                    WHEN p.asset_symbol = 'BTCUSDT' THEN 'Bitcoin'
                    WHEN p.asset_symbol = 'ETHUSDT' THEN 'Ethereum'
                    WHEN p.asset_symbol = 'SOLUSDT' THEN 'Solana'
                    WHEN p.asset_symbol = 'XRPUSDT' THEN 'XRP'
                    WHEN p.asset_symbol = 'DOGEUSDT' THEN 'Dogecoin'
                    WHEN p.asset_symbol = 'ADAUSDT' THEN 'Cardano'
                    WHEN p.asset_symbol = 'AVAXUSDT' THEN 'Avalanche'
                    WHEN p.asset_symbol = 'DOTUSDT' THEN 'Polkadot'
                    WHEN p.asset_symbol = 'LINKUSDT' THEN 'Chainlink'
                    WHEN p.asset_symbol = 'MATICUSDT' THEN 'Polygon'
                    WHEN p.asset_symbol = 'UNIUSDT' THEN 'Uniswap'
                    -- STOCKS (10)
                    WHEN p.asset_symbol = 'AAPL' THEN 'Apple'
                    WHEN p.asset_symbol = 'NVDA' THEN 'NVIDIA'
                    WHEN p.asset_symbol = 'TSLA' THEN 'Tesla'
                    WHEN p.asset_symbol = 'MSFT' THEN 'Microsoft'
                    WHEN p.asset_symbol = 'AMZN' THEN 'Amazon'
                    WHEN p.asset_symbol = 'GOOGL' THEN 'Google'
                    WHEN p.asset_symbol = 'META' THEN 'Meta'
                    WHEN p.asset_symbol = 'NFLX' THEN 'Netflix'
                    WHEN p.asset_symbol = 'AMD' THEN 'AMD'
                    WHEN p.asset_symbol = 'INTC' THEN 'Intel'
                    -- COMMODITIES (9)
                    WHEN p.asset_symbol = 'XAUUSD' THEN 'Gold'
                    WHEN p.asset_symbol = 'XAGUSD' THEN 'Silver'
                    WHEN p.asset_symbol = 'WTI' THEN 'Oil (WTI)'
                    WHEN p.asset_symbol = 'NG' THEN 'Natural Gas'
                    WHEN p.asset_symbol = 'CORN' THEN 'Corn'
                    WHEN p.asset_symbol = 'SOY' THEN 'Soybeans'
                    WHEN p.asset_symbol = 'WHEAT' THEN 'Wheat'
                    WHEN p.asset_symbol = 'HG' THEN 'Copper'
                    WHEN p.asset_symbol = 'PL' THEN 'Platinum'
                    WHEN p.asset_symbol = 'PA' THEN 'Palladium'
                    ELSE p.asset_symbol
                END, p.asset_symbol
            ) as asset_name,
            CASE
                WHEN p.asset_symbol LIKE '%USDT' THEN 'CRYPTO'
                WHEN p.asset_symbol IN ('AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC') THEN 'STOCKS'
                ELSE 'COMMODITIES'
            END as asset_type,
            COUNT(DISTINCT p.user_id) as participant_count,
            COALESCE(SUM(p.bet_amount), 0) as total_volume,
            ROW_NUMBER() OVER (
                PARTITION BY CASE
                    WHEN p.asset_symbol LIKE '%USDT' THEN 'CRYPTO'
                    WHEN p.asset_symbol IN ('AAPL', 'NVDA', 'TSLA', 'MSFT', 'AMZN', 'GOOGL', 'META', 'NFLX', 'AMD', 'INTC') THEN 'STOCKS'
                    ELSE 'COMMODITIES'
                END
                ORDER BY COALESCE(SUM(p.bet_amount), 0) DESC, COUNT(DISTINCT p.user_id) DESC
            ) as rank
        FROM predictions p
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
        GROUP BY p.asset_symbol, p.timeframe
    ),
    ai_predictions AS (
        SELECT DISTINCT ON (p.asset_symbol, p.timeframe)
            p.asset_symbol,
            p.timeframe,
            p.direction as ai_direction,
            ROUND(AVG(p.target_percent) OVER (PARTITION BY p.asset_symbol, p.timeframe)) as ai_confidence
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.status = 'pending'
            AND p.candle_close_at > NOW()
            AND prof.is_bot = true
            AND prof.username LIKE 'Analyst_%'
        ORDER BY p.asset_symbol, p.timeframe, COUNT(*) OVER (PARTITION BY p.asset_symbol, p.timeframe, p.direction) DESC
    )
    SELECT
        r.asset_symbol,
        r.timeframe,
        r.asset_name,
        r.asset_type,
        r.participant_count,
        r.total_volume,
        COALESCE(ai.ai_direction, NULL::TEXT) as ai_direction,
        COALESCE(ai.ai_confidence, NULL::NUMERIC) as ai_confidence
    FROM ranked_assets r
    LEFT JOIN ai_predictions ai ON r.asset_symbol = ai.asset_symbol AND r.timeframe = ai.timeframe
    WHERE r.rank = 1
    ORDER BY r.total_volume DESC;
END;
$$ LANGUAGE plpgsql;
