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
            -- CRYPTO (10)
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
            -- COMMODITIES (10)
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
    latest_ai_round_times AS (
        -- Find the latest round timestamp per asset/timeframe
        SELECT DISTINCT ON (p.asset_symbol, p.timeframe)
            p.asset_symbol,
            p.timeframe,
            date_trunc('minute', p.created_at) as round_time
        FROM predictions p
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.channel = 'analyst_hub'
          AND p.is_opinion = TRUE
          AND prof.is_bot = true
        ORDER BY p.asset_symbol, p.timeframe, p.created_at DESC
    ),
    ai_predictions AS (
        -- Group insights by that latest round time
        SELECT
            p.asset_symbol,
            p.timeframe,
            COUNT(DISTINCT p.user_id) as ai_count,
            COALESCE(SUM(p.bet_amount), 0) as ai_volume,
            MODE() WITHIN GROUP (ORDER BY p.direction) as ai_direction,
            ROUND(AVG(p.target_percent)) as ai_confidence
        FROM predictions p
        INNER JOIN latest_ai_round_times lart ON 
            p.asset_symbol = lart.asset_symbol AND 
            p.timeframe = lart.timeframe AND 
            date_trunc('minute', p.created_at) = lart.round_time
        INNER JOIN profiles prof ON p.user_id = prof.id
        WHERE p.is_opinion = TRUE
          AND prof.is_bot = true
        GROUP BY p.asset_symbol, p.timeframe
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
    LEFT JOIN ai_predictions ai ON apr.asset_symbol = ai.asset_symbol AND apr.timeframe = ai.timeframe
    LEFT JOIN user_predictions up ON apr.asset_symbol = up.asset_symbol AND apr.timeframe = up.timeframe
    WHERE ai.ai_count > 0 OR up.user_count > 0
    ORDER BY
        (COALESCE(up.user_volume, 0) + COALESCE(ai.ai_volume, 0)) DESC,
        (COALESCE(up.user_count, 0) + COALESCE(ai.ai_count, 0)) DESC
    LIMIT 3;
END;
$$ LANGUAGE plpgsql STABLE;
