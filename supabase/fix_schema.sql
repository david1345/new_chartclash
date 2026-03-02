-- Comprehensive fix for predictions table columns
DO $$ 
BEGIN 
    -- 1. asset_symbol
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'asset_symbol') THEN
        ALTER TABLE predictions ADD COLUMN asset_symbol TEXT NOT NULL DEFAULT 'BTCUSDT';
    END IF;

    -- 2. entry_price
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'entry_price') THEN
        ALTER TABLE predictions ADD COLUMN entry_price NUMERIC NOT NULL DEFAULT 0;
    END IF;

    -- 3. target_percent (Just in case)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'target_percent') THEN
        ALTER TABLE predictions ADD COLUMN target_percent NUMERIC NOT NULL DEFAULT 0.5;
    END IF;

    -- 4. direction (Just in case)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'direction') THEN
        ALTER TABLE predictions ADD COLUMN direction TEXT NOT NULL DEFAULT 'UP';
    END IF;

     -- 5. status (Just in case)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'status') THEN
        ALTER TABLE predictions ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;

    -- 6. Refresh Schema Cache (Not possible via SQL directly, but good to comment)
    -- Supabase client might need refresh or re-instantiation if this persists, but usually column add helps.
END $$;
