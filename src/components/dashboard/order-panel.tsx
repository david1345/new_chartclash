"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { useGuestPrediction } from "@/hooks/dashboard/use-guest-prediction";

// New Battle Components
import { RoundStatus } from "@/components/battle/round-status";
import { BattleMeter } from "@/components/battle/battle-meter";
import { TimeframeSelector } from "@/components/battle/timeframe-selector";
import { BetInput } from "@/components/battle/bet-input";
import { RewardDisplay } from "@/components/battle/reward-display";
import { ActionButtons } from "@/components/battle/action-buttons";
import { ActivePositionPanel } from "@/components/battle/active-position-panel";

import { calculateReward } from "@/lib/rewards";

// Hardcode selected asset to BTC since mockup is BTC only
const BTC_ASSET = { symbol: "BTCUSDT", name: "Bitcoin", type: "CRYPTO" };

interface OrderPanelProps {
    user: any;
    userPoints: number;
    userStreak: number;
    setUserPoints: (points: number) => void;
    selectedAsset: any;
    setSelectedAsset: (asset: any) => void;
    selectedTimeframe: string;
    setSelectedTimeframe: (tf: string) => void;
    marketStatus: { isOpen: boolean; reason?: string };
    isLocked: boolean;
    isAlreadyBet: boolean;
    refreshPredictions: () => void;
    fetchUserStats: () => void;
    onBetSuccess?: () => void;
    isLoaded: boolean;
    activePrediction?: any;
    roundOpenPrice?: number | null;
    serverTimeOffset: number;
}

export function OrderPanel({
    user,
    userPoints,
    userStreak,
    setUserPoints,
    selectedTimeframe,
    setSelectedTimeframe,
    isLocked,
    isAlreadyBet,
    refreshPredictions,
    fetchUserStats,
    onBetSuccess,
    isLoaded,
    activePrediction,
    roundOpenPrice,
    serverTimeOffset
}: OrderPanelProps) {
    const { submitGuestPrediction, guestPoints } = useGuestPrediction();
    const supabase = createClient();

    // Local State
    const [betAmount, setBetAmount] = useState(10);
    const [selectedDirection, setSelectedDirection] = useState<"UP" | "DOWN" | null>(null);
    const [selectedPercent] = useState<number>(0.5); // Fixed or default target percent for simplicity now
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Market Data
    const [candleElapsed, setCandleElapsed] = useState<number | null>(null);
    const [localElapsed, setLocalElapsed] = useState<number>(0);

    // Sync local ticking clock to API value
    useEffect(() => {
        if (candleElapsed !== null) setLocalElapsed(candleElapsed);
    }, [candleElapsed]);

    // Tick the local elapsed time
    useEffect(() => {
        const interval = setInterval(() => {
            setLocalElapsed(prev => prev + 1);
        }, 1000);
        return () => clearInterval(interval);
    }, []);

    const totalSeconds = selectedTimeframe === '1h' ? 3600 : selectedTimeframe === '4h' ? 14400 : 3600;

    // Mock Battle Meter Data (Ideally fetched from real-time DB)
    const [upPercent, setUpPercent] = useState(62.5);
    const [downPercent, setDownPercent] = useState(37.5);

    useEffect(() => {
        const fetchInitialPrice = async () => {
            try {
                const res = await fetch("/api/market/entry-price", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ symbol: "BTCUSDT", timeframe: selectedTimeframe, type: "CRYPTO" })
                });
                const json = await res.json();
                if (json.success && json.data) {
                    if (json.data.candleElapsedSeconds !== undefined) setCandleElapsed(json.data.candleElapsedSeconds);
                }
            } catch (e) {
                console.error("Server price API error", e);
            }
        };
        fetchInitialPrice();
    }, [selectedTimeframe]);

    // Initialize bet amount
    useEffect(() => {
        const isGuest = !user || user?.is_guest;
        const currentPoints = isGuest ? guestPoints : userPoints;
        if (isLoaded && currentPoints > 0 && betAmount === 10) {
            if (currentPoints <= 1000) {
                setBetAmount(10);
            } else {
                setBetAmount(Math.max(1, Math.floor(currentPoints * 0.01)));
            }
        }
    }, [userPoints, guestPoints, isLoaded, user]);

    const getWinPotential = () => {
        return {
            min: calculateReward(betAmount, 0, userStreak, selectedTimeframe, candleElapsed, false),
            max: calculateReward(betAmount, selectedPercent, userStreak, selectedTimeframe, candleElapsed, true)
        };
    };
    const rewards = getWinPotential();

    const fetchCandleData = async () => {
        try {
            const res = await fetch("/api/market/entry-price", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ symbol: BTC_ASSET.symbol, timeframe: selectedTimeframe, type: BTC_ASSET.type })
            });
            const json = await res.json();
            if (!json.success || !json.data) return null;
            return json.data;
        } catch (e) {
            return null;
        }
    };

    const handlePredict = async (direction: "UP" | "DOWN") => {
        setSelectedDirection(direction);
        if (isSubmitting) return;

        const isGuest = !user || user.is_guest;
        const points = isGuest ? guestPoints : userPoints;
        const minBet = 1;

        if (betAmount < minBet) {
            toast.warning(`Minimum bet is ${minBet} points`);
            return;
        }

        // Note: Allowing MAX bet now based on new UI, so skipping the strict 20% max if they click MAX, 
        // but ensuring it doesn't exceed total points.
        if (betAmount > points) {
            toast.warning(`Insufficient balance`);
            return;
        }

        if (isLocked) {
            toast.error("Round is locked! Create a prediction for the next candle.");
            return;
        }

        setIsSubmitting(true);
        try {
            const candleData = await fetchCandleData();
            if (!candleData) {
                toast.error("Could not fetch market data. Try again.");
                setIsSubmitting(false);
                return;
            }

            if (isGuest) {
                const now = Date.now();
                const adjustedNow = now + serverTimeOffset;
                const roundCloseTime = Math.floor(adjustedNow / (totalSeconds * 1000)) * (totalSeconds * 1000) + (totalSeconds * 1000);

                submitGuestPrediction({
                    asset_symbol: BTC_ASSET.symbol,
                    timeframe: selectedTimeframe,
                    direction,
                    target_percent: selectedPercent,
                    entry_price: candleData.openPrice,
                    bet_amount: betAmount,
                    candle_close_at: new Date(roundCloseTime).toISOString(),
                });
                toast.success("Guest Prediction Placed!");
                if (onBetSuccess) onBetSuccess();
                refreshPredictions();
            } else {
                const res = await fetch('/api/predictions/submit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        p_asset_symbol: BTC_ASSET.symbol,
                        p_timeframe: selectedTimeframe,
                        p_direction: direction,
                        p_target_percent: selectedPercent,
                        p_entry_price: candleData.openPrice,
                        p_bet_amount: betAmount
                    })
                });

                const result = await res.json();

                if (!res.ok || !result.success) {
                    toast.error(`Submission failed: ${result.error || 'Unknown error'}`);
                } else {
                    toast.success("Prediction Locked!");
                    if (onBetSuccess) onBetSuccess();
                    refreshPredictions();

                    if (result.data?.new_points !== undefined) {
                        setUserPoints(result.data.new_points);
                    } else {
                        fetchUserStats();
                    }
                }
            }
        } catch (error: any) {
            toast.error(error?.message || "An unexpected error occurred.");
        } finally {
            setIsSubmitting(false);
            setSelectedDirection(null);

            // Randomize battle meter a bit for effect
            const newUp = Math.random() * 40 + 30;
            setUpPercent(newUp);
            setDownPercent(100 - newUp);
        }
    };

    const isGuest = !user || user?.is_guest;
    const currentPoints = isGuest ? guestPoints : userPoints;

    return (
        <div className="flex flex-col h-full bg-[#080C14] rounded-2xl p-2 lg:p-3 border border-[#1E2D45] overflow-y-auto no-scrollbar relative lg:min-h-0">
            {/* 1. Round Status */}
            <RoundStatus
                timeframe={selectedTimeframe}
                referencePrice={roundOpenPrice ?? null}
                candleElapsed={localElapsed}
                isLocked={isLocked}
            />

            {/* If user HAS NOT bet yet, show the normal betting interface */}
            {!isAlreadyBet ? (
                <>
                    {/* 2. Battle Meter */}
                    <BattleMeter upPercent={upPercent} downPercent={downPercent} />

                    <div className="flex gap-2 mb-1.5 items-stretch">
                        {/* 3. Timeframe Toggle */}
                        <div className="w-[48px] shrink-0">
                            <TimeframeSelector selectedTimeframe={selectedTimeframe} onSelect={setSelectedTimeframe} />
                        </div>

                        {/* 4. Bet Input */}
                        <div className="flex-1">
                            <BetInput
                                amount={betAmount}
                                maxAmount={currentPoints}
                                onChange={(v) => setBetAmount(Math.min(v, currentPoints))}
                                disabled={isLocked || isAlreadyBet || isSubmitting}
                            />
                        </div>
                    </div>

                    {/* 5. Reward Display */}
                    <RewardDisplay
                        betAmount={betAmount}
                        expectedMin={rewards.min}
                        expectedMax={rewards.max}
                        streak={userStreak}
                        upPercent={upPercent}
                        downPercent={downPercent}
                    />

                    {/* 6. Action Buttons */}
                    <div className="pt-2 z-10 lg:static lg:bg-none lg:pt-0 pb-2 lg:pb-0">
                        <ActionButtons
                            selectedDirection={selectedDirection}
                            isSubmitting={isSubmitting || isLocked || isAlreadyBet}
                            onPredict={handlePredict}
                        />
                    </div>
                </>
            ) : (
                /* If user HAS bet, show their Active Position */
                <div className="flex-1 mt-2 mb-2 lg:mb-0">
                    <ActivePositionPanel
                        prediction={activePrediction}
                        currentPrice={roundOpenPrice ?? null} // We need real-time ticker here, but openPrice works as a fallback initially if real-time isn't fast enough
                    />
                </div>
            )}
        </div>
    );
}
