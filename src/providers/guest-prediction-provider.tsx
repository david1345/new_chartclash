"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import { GuestPrediction } from "@/types/guest-prediction";
import { createClient } from "@/lib/supabase/client";
import { calculateReward } from "@/lib/rewards";

interface GuestPredictionContextType {
    guestPredictions: GuestPrediction[];
    guestPoints: number;
    guestId: string;
    setGuestPoints: (points: number) => void;
    submitGuestPrediction: (data: Omit<GuestPrediction, "id" | "created_at" | "status" | "is_guest">) => GuestPrediction;
    resolveGuestPrediction: (id: string, closePrice: number) => GuestPrediction | undefined;
    clearGuestPredictions: () => void;
}

const GuestPredictionContext = createContext<GuestPredictionContextType | undefined>(undefined);

const STORAGE_KEY = "chartclash_guest_predictions";
const POINTS_KEY = "chartclash_guest_points";
const GUEST_ID_KEY = "chartclash_guest_id";

export function GuestPredictionProvider({ children }: { children: React.ReactNode }) {
    const [guestPredictions, setGuestPredictions] = useState<GuestPrediction[]>([]);
    const [guestPoints, setGuestPoints] = useState<number>(1000);
    const [guestId, setGuestId] = useState<string>("");
    const supabase = createClient();

    // Helper functions for UUID generation
    const generateUUID = () => {
        if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID();
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    };

    // 1. Load from localStorage on mount
    useEffect(() => {
        if (typeof window === 'undefined') return;

        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
            try {
                const parsed = JSON.parse(stored);
                if (Array.isArray(parsed)) setGuestPredictions(parsed);
            } catch (e) {
                console.error("Failed to parse guest predictions", e);
            }
        }

        const storedPoints = localStorage.getItem(POINTS_KEY);
        if (storedPoints) {
            setGuestPoints(Number(storedPoints));
        }

        let storedId = localStorage.getItem(GUEST_ID_KEY);
        // Ensure it's a valid UUID
        if (!storedId || !storedId.includes('-')) {
            storedId = generateUUID();
            localStorage.setItem(GUEST_ID_KEY, storedId);
        }
        setGuestId(storedId);
    }, []);

    // 2. Sync with Database whenever profile data (points) changes
    useEffect(() => {
        if (!guestId) return;

        const syncProfile = async () => {
            try {
                await supabase.rpc('upsert_temporary_profile', {
                    p_id: guestId,
                    p_username: `Guest_${guestId.substring(0, 5)}`,
                    p_points: guestPoints
                });
            } catch (err) {
                console.error("Failed to sync guest profile to DB:", err);
            }
        };

        const timer = setTimeout(syncProfile, 2000); // 2s debounce
        return () => clearTimeout(timer);
    }, [guestId, guestPoints, supabase]);

    // 3. Save to localStorage whenever state changes
    useEffect(() => {
        if (guestPredictions.length > 0 || guestPoints !== 1000) {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(guestPredictions));
            localStorage.setItem(POINTS_KEY, guestPoints.toString());
        }
    }, [guestPredictions, guestPoints]);

    const submitGuestPrediction = useCallback((data: Omit<GuestPrediction, "id" | "created_at" | "status" | "is_guest">) => {
        const newPrediction: GuestPrediction = {
            ...data,
            id: `guest_${Date.now()}`,
            created_at: new Date().toISOString(),
            status: "pending",
            is_guest: true
        };

        setGuestPoints(prev => Math.max(0, prev - data.bet_amount));
        setGuestPredictions(prev => [newPrediction, ...prev]);

        return newPrediction;
    }, []);

    const resolveGuestPrediction = useCallback((id: string, closePrice: number) => {
        let resolvedPred: GuestPrediction | undefined;
        let pointsToAdd = 0;

        setGuestPredictions(prev => {
            const predIndex = prev.findIndex(p => p.id === id && p.status === "pending");
            if (predIndex === -1) return prev;

            const pred = prev[predIndex];
            const priceChange = closePrice - pred.entry_price;
            const isWin = (pred.direction === "UP" && priceChange > 0) || (pred.direction === "DOWN" && priceChange < 0);

            const profitValue = isWin
                ? calculateReward(pred.bet_amount, pred.target_percent, 0, pred.timeframe, 0, true)
                : -pred.bet_amount;

            if (isWin) pointsToAdd = pred.bet_amount + profitValue;

            resolvedPred = {
                ...pred,
                status: isWin ? "WIN" : "LOSS",
                actual_price: closePrice,
                profit: profitValue,
                resolved_at: new Date().toISOString()
            };

            const next = [...prev];
            next[predIndex] = resolvedPred;
            return next;
        });

        if (pointsToAdd > 0) {
            setGuestPoints(prev => prev + pointsToAdd);
        }

        return resolvedPred;
    }, []);

    const clearGuestPredictions = useCallback(() => {
        setGuestPredictions([]);
        setGuestPoints(1000);
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(POINTS_KEY);
    }, []);

    return (
        <GuestPredictionContext.Provider value={{
            guestPredictions,
            guestPoints,
            guestId,
            setGuestPoints,
            submitGuestPrediction,
            resolveGuestPrediction,
            clearGuestPredictions
        }}>
            {children}
        </GuestPredictionContext.Provider>
    );
}

export const useGuestPredictions = () => {
    const context = useContext(GuestPredictionContext);
    if (!context) throw new Error("useGuestPredictions must be used within GuestPredictionProvider");
    return context;
};
