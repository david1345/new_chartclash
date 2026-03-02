-- ==============================================
-- 🩹 ChartClash Data Healing & Standardization
-- MIGRATION: 20260222_heal_standard_schema.sql
-- ==============================================

DO $$ 
BEGIN
    -- 1. Profiles: total_points -> points
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_points') THEN
        RAISE NOTICE 'Healing profiles.total_points -> points...';
        UPDATE public.profiles SET points = COALESCE(total_points, points) WHERE total_points IS NOT NULL;
        ALTER TABLE public.profiles DROP COLUMN total_points;
    END IF;

    -- 2. Predictions: profit_loss -> profit
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='predictions' AND column_name='profit_loss') THEN
        RAISE NOTICE 'Healing predictions.profit_loss -> profit...';
        UPDATE public.predictions SET profit = COALESCE(profit_loss, profit) WHERE profit_loss IS NOT NULL;
        ALTER TABLE public.predictions DROP COLUMN profit_loss;
    END IF;

    -- 3. Predictions: close_price -> actual_price
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='predictions' AND column_name='close_price') THEN
        RAISE NOTICE 'Healing predictions.close_price -> actual_price...';
        UPDATE public.predictions SET actual_price = COALESCE(close_price, actual_price) WHERE close_price IS NOT NULL;
        ALTER TABLE public.predictions DROP COLUMN close_price;
    END IF;

    -- 4. Status Alignment: Ensure NO REFUND strings, only ND
    UPDATE public.predictions SET status = 'ND' WHERE status = 'REFUND';

    RAISE NOTICE 'Data Healing Complete. All columns synchronized to Base Schema.';
END $$;
