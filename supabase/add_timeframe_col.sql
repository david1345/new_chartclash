DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'predictions' AND column_name = 'timeframe') THEN
        ALTER TABLE predictions ADD COLUMN timeframe TEXT NOT NULL DEFAULT '1h';
    END IF;
END $$;
