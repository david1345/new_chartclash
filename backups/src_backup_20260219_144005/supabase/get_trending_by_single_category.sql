-- Get top 3 trending assets for a specific category
CREATE OR REPLACE FUNCTION get_trending_by_single_category(
    p_category TEXT DEFAULT 'CRYPTO'
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
        WHERE asset.type = p_category
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
    )
    SELECT
        apr.asset_symbol,
        apr.timeframe,
        apr.asset_name,
        apr.asset_type,
        COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0) as participant_count,
        COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0) as total_volume,
        ai.ai_direction,
        ai.ai_confidence
    FROM all_possible_rounds apr
    LEFT JOIN user_predictions up ON apr.asset_symbol = up.asset_symbol AND apr.timeframe = up.timeframe
    LEFT JOIN ai_predictions ai ON apr.asset_symbol = ai.asset_symbol AND apr.timeframe = ai.timeframe
    WHERE ai.ai_count > 0 OR up.user_count > 0
    ORDER BY
        (COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0)) DESC,
        (COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0)) DESC
    LIMIT 3;
END;
$$ LANGUAGE plpgsql;
