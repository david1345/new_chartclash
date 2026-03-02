-- Market Discovery Functions for Main Page

-- 1. Get live rounds with statistics
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
    SELECT
        p.asset_symbol,
        p.timeframe,
        COALESCE(
            CASE
                WHEN p.asset_symbol = 'BTCUSDT' THEN 'Bitcoin'
                WHEN p.asset_symbol = 'ETHUSDT' THEN 'Ethereum'
                WHEN p.asset_symbol = 'AAPL' THEN 'Apple'
                WHEN p.asset_symbol = 'XAUUSD' THEN 'Gold'
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
        NULL::TEXT as ai_direction,
        NULL::NUMERIC as ai_confidence
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
    ORDER BY total_volume DESC, participant_count DESC
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
    total_volume BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH ranked_assets AS (
        SELECT
            p.asset_symbol,
            p.timeframe,
            COALESCE(
                CASE
                    WHEN p.asset_symbol = 'BTCUSDT' THEN 'Bitcoin'
                    WHEN p.asset_symbol = 'ETHUSDT' THEN 'Ethereum'
                    WHEN p.asset_symbol = 'AAPL' THEN 'Apple'
                    WHEN p.asset_symbol = 'XAUUSD' THEN 'Gold'
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
    )
    SELECT
        r.asset_symbol,
        r.timeframe,
        r.asset_name,
        r.asset_type,
        r.participant_count,
        r.total_volume
    FROM ranked_assets r
    WHERE r.rank = 1
    ORDER BY r.total_volume DESC;
END;
$$ LANGUAGE plpgsql;

-- 3. Get asset rounds by symbol (all timeframes for a specific asset)
CREATE OR REPLACE FUNCTION get_asset_rounds(
    p_asset_symbol TEXT
)
RETURNS TABLE (
    asset_symbol TEXT,
    timeframe TEXT,
    participant_count BIGINT,
    total_volume BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.asset_symbol,
        p.timeframe,
        COUNT(DISTINCT p.user_id) as participant_count,
        COALESCE(SUM(p.bet_amount), 0) as total_volume
    FROM predictions p
    WHERE p.status = 'pending'
        AND p.candle_close_at > NOW()
        AND p.asset_symbol = p_asset_symbol
    GROUP BY p.asset_symbol, p.timeframe
    ORDER BY
        CASE p.timeframe
            WHEN '15m' THEN 1
            WHEN '30m' THEN 2
            WHEN '1h' THEN 3
            WHEN '4h' THEN 4
            WHEN '1d' THEN 5
        END;
END;
$$ LANGUAGE plpgsql;
