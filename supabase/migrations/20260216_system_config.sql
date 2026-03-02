-- Create system_settings table for dynamic parameter management
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value NUMERIC NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert initial parameters
INSERT INTO public.system_settings (key, value, description)
VALUES 
    ('fee_rate', 0.1, 'Default platform fee rate (10%)'),
    ('streak_bonus_threshold', 3, 'Games required for streak bonus'),
    ('decay_factor', 0.8, 'Reward decay multiplier for late entries'),
    ('min_bet_default', 10, 'Default minimum bet amount')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

COMMENT ON TABLE public.system_settings IS 'Global system parameters managed by admin';
