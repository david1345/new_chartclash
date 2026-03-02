-- Force enable public read on predictions to ensure stats are global
DROP POLICY IF EXISTS "Predictions are viewable by everyone." ON public.predictions;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.predictions;

CREATE POLICY "Enable read access for all users" ON public.predictions
FOR SELECT
USING (true);

-- Verify count
SELECT count(*) FROM predictions WHERE asset_symbol = 'BTCUSDT' AND timeframe = '30m';
