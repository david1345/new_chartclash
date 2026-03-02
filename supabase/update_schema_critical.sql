-- CRITICAL SCHEMA UPDATE & FIX
-- Based on: schema_review_critical.md
-- Run this script in Supabase SQL Editor to fix the schema and logic.

-- 1. PREDICTIONS TABLE UPDATES (Safe Alter)
-- We use ALTER TABLE to preserve existing data (if any).

-- Add 'timeframe'
DO $$ BEGIN
    ALTER TABLE public.predictions ADD COLUMN timeframe TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add 'bet_amount'
DO $$ BEGIN
    ALTER TABLE public.predictions ADD COLUMN bet_amount INTEGER;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add 'comment'
DO $$ BEGIN
    ALTER TABLE public.predictions ADD COLUMN comment TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add 'candle_close_at'
DO $$ BEGIN
    ALTER TABLE public.predictions ADD COLUMN candle_close_at TIMESTAMP WITH TIME ZONE;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add 'actual_price'
DO $$ BEGIN
    ALTER TABLE public.predictions ADD COLUMN actual_price NUMERIC;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add 'profit'
DO $$ BEGIN
    ALTER TABLE public.predictions ADD COLUMN profit INTEGER DEFAULT 0;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add Constraints (Optional but recommended, using safe approach)
DO $$ BEGIN
    ALTER TABLE public.predictions ADD CONSTRAINT check_direction CHECK (direction IN ('UP', 'DOWN'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. INDICES (Performance)
CREATE INDEX IF NOT EXISTS idx_predictions_status ON public.predictions(status);
CREATE INDEX IF NOT EXISTS idx_predictions_user ON public.predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_candle ON public.predictions(asset_symbol, timeframe, candle_close_at);
CREATE INDEX IF NOT EXISTS idx_predictions_created ON public.predictions(created_at DESC);


-- 3. RESOLVE FUNCTION (Robust Implementation)
-- This replaces any existing function with the robust logic from the review.

-- FIX: Drop function first because return type changed (JSONB -> JSON)
DROP FUNCTION IF EXISTS public.resolve_prediction_advanced(BIGINT, NUMERIC);

CREATE OR REPLACE FUNCTION public.resolve_prediction_advanced(
    p_id BIGINT,
    p_close_price NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prediction RECORD;
    v_price_change NUMERIC;
    v_price_change_percent NUMERIC;
    v_status TEXT;
    v_payout INTEGER := 0;
    v_result JSON;
BEGIN
    -- A. Fetch Prediction (Locking for safety)
    SELECT * INTO v_prediction
    FROM predictions
    WHERE id = p_id AND status = 'pending'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Prediction not found or already resolved'
        );
    END IF;

    -- Safety Check for missing data (handled by defaults or null checks if needed)
    -- If bet_amount is NULL, treat as 0
    IF v_prediction.bet_amount IS NULL THEN
        v_prediction.bet_amount := 0;
    END IF;
    
    -- B. Calculate Price Change
    v_price_change := p_close_price - v_prediction.entry_price;
    v_price_change_percent := ABS(v_price_change / v_prediction.entry_price * 100);
    
    -- C. Determine Outcome (UP/DOWN)
    IF v_prediction.direction = 'UP' THEN
        -- WIN Logic: Moved in right direction AND hit the target %
        IF v_price_change > 0 AND v_price_change_percent >= v_prediction.target_percent THEN
            v_status := 'WIN';
            -- Payout Formula: Bet * (Target% * 2 + 1) -> Higher Target = Higher Reward
            -- e.g. 1.0% Target -> 100 * (1.0 * 2 + 1) = 300 (3x)
            v_payout := FLOOR(v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1));
        ELSIF v_price_change < 0 THEN
            v_status := 'LOSS';
            v_payout := 0;
        ELSE
            -- Direction right but didn't hit target? Or exactly 0 change?
            -- Review Logic: "Else (Target not hit) -> ND (No Decision - Refund)"
            -- Actually, if prices goes UP but not enough (e.g. +0.1% vs +1.0% target), 
            -- Strict gambling usually counts as LOSS, but Review Logic suggested ND loop.
            -- "상승했지만 목표 미달 -> ND (무승부, 베팅액 반환)"
            v_status := 'ND'; 
            v_payout := v_prediction.bet_amount;
        END IF;
        
    ELSIF v_prediction.direction = 'DOWN' THEN
        IF v_price_change < 0 AND v_price_change_percent >= v_prediction.target_percent THEN
            v_status := 'WIN';
            v_payout := FLOOR(v_prediction.bet_amount * (v_prediction.target_percent * 2 + 1));
        ELSIF v_price_change > 0 THEN
            v_status := 'LOSS';
            v_payout := 0;
        ELSE
            -- Down but not enough
            v_status := 'ND';
            v_payout := v_prediction.bet_amount;
        END IF;
    END IF;

    -- D. Update Prediction
    UPDATE predictions
    SET 
        status = v_status,
        actual_price = p_close_price,
        profit = v_payout - v_prediction.bet_amount,
        resolved_at = NOW()
    WHERE id = p_id;
    
    -- E. Update User Points (Atomic)
    IF v_payout > 0 THEN
        UPDATE profiles
        SET points = points + v_payout
        WHERE id = v_prediction.user_id;
    END IF;
    
    -- F. Return Result
    RETURN json_build_object(
        'success', true,
        'status', v_status,
        'payout', v_payout,
        'profit', v_payout - v_prediction.bet_amount,
        'actual_price', p_close_price,
        'price_change_percent', v_price_change_percent
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;
