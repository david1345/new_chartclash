import { useState, useEffect, useRef } from 'react';
import { toast } from 'sonner';

interface UsePredictionLockProps {
    timeframe: string;
    selectedAssetSymbol: string;
}

export function usePredictionLock({ timeframe, selectedAssetSymbol }: UsePredictionLockProps) {
    const [timeLeft, setTimeLeft] = useState<string>("");
    const [label, setLabel] = useState<string>("LOCKS IN");
    const [isLocked, setIsLocked] = useState(false);
    const [lockReason, setLockReason] = useState("");
    const [serverTimeOffset, setServerTimeOffset] = useState(0);

    // 1. Sync Time with Server on Mount (or when asset changes)
    useEffect(() => {
        const syncTime = async () => {
            try {
                const start = Date.now();
                const res = await fetch("/api/market/entry-price", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ symbol: selectedAssetSymbol, timeframe })
                });
                const json = await res.json();
                const end = Date.now();
                const latency = (end - start) / 2;

                if (json.success && json.data?.serverTime) {
                    const serverTime = json.data.serverTime;
                    const clientTime = Date.now();
                    const offset = (serverTime + latency) - clientTime;
                    setServerTimeOffset(offset);
                }
            } catch (e) {
                console.error("Time sync failed, using local time", e);
            }
        };

        syncTime();
    }, [selectedAssetSymbol, timeframe]);

    // 2. Timer Logic
    useEffect(() => {
        const calculateTime = () => {
            const nowMs = Date.now() + serverTimeOffset;

            let candleDurationMinutes = 15;
            if (timeframe === '1m') candleDurationMinutes = 1;
            else if (timeframe === '5m') candleDurationMinutes = 5;
            else if (timeframe === '15m') candleDurationMinutes = 15;
            else if (timeframe === '30m') candleDurationMinutes = 30;
            else if (timeframe === '1h') candleDurationMinutes = 60;
            else if (timeframe === '4h') candleDurationMinutes = 240;
            else if (timeframe === '1d') candleDurationMinutes = 1440;

            const durationMs = candleDurationMinutes * 60 * 1000;

            let candleStartMs = Math.floor(nowMs / durationMs) * durationMs;
            const candleEndMs = candleStartMs + durationMs;
            const lockTimeMs = candleStartMs + (durationMs * 0.9);

            // Determine Lock State & Label & Target
            let targetTimeMs = 0;
            if (nowMs >= lockTimeMs) {
                if (!isLocked) {
                    setIsLocked(true);
                    setLockReason("LOCKED: WAITING FOR NEXT ROUND");
                }
                setLabel("NEXT ROUND");
                targetTimeMs = candleEndMs;
            } else {
                if (isLocked) {
                    setIsLocked(false);
                    setLockReason("");
                }
                setLabel("LOCKS IN");
                targetTimeMs = lockTimeMs;
            }

            // Calculate Remaining Time
            const diff = targetTimeMs - nowMs;
            if (diff > 0) {
                const m = Math.floor((diff / 1000 / 60) % 60);
                const s = Math.floor((diff / 1000) % 60);
                const h = Math.floor((diff / (1000 * 60 * 60)) % 24);

                if (h > 0) {
                    setTimeLeft(`${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`);
                } else {
                    setTimeLeft(`${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`);
                }
            } else {
                setTimeLeft("00:00");
            }
        };

        calculateTime();
        const interval = setInterval(calculateTime, 1000);

        const resolutionInterval = setInterval(async () => {
            try {
                await fetch('/api/resolve', { method: 'GET', cache: 'no-store' });
            } catch (e) { }
        }, 30000);

        return () => {
            clearInterval(interval);
            clearInterval(resolutionInterval);
        };
    }, [timeframe, serverTimeOffset, isLocked, selectedAssetSymbol]);

    return { timeLeft, label, isLocked, lockReason, serverTimeOffset };
}
