"use client";

import { useEffect, useState, useRef } from "react";
import { Badge } from "@/components/ui/badge";
import { Timer, Lock, Unlock } from "lucide-react";
import { cn } from "@/lib/utils";

interface CandleTimerProps {
    timeframe: string;
    onLockChange: (isLocked: boolean) => void;
}

export function CandleTimer({ timeframe, onLockChange }: CandleTimerProps) {
    const [displayTime, setDisplayTime] = useState("--:--");
    const [label, setLabel] = useState("");
    const [isLocked, setIsLocked] = useState(false);
    const [serverTimeOffset, setServerTimeOffset] = useState(0);

    const onLockChangeRef = useRef(onLockChange);

    useEffect(() => {
        onLockChangeRef.current = onLockChange;
    }, [onLockChange]);

    // Sync Time with Server (Consistency with hook)
    useEffect(() => {
        const syncTime = async () => {
            try {
                const start = Date.now();
                const res = await fetch("/api/market/entry-price", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ symbol: "BTCUSDT", timeframe })
                });
                const json = await res.json();
                const end = Date.now();
                const latency = (end - start) / 2;
                if (json.success && json.data?.serverTime) {
                    setServerTimeOffset((json.data.serverTime + latency) - Date.now());
                }
            } catch (e) { }
        };
        syncTime();
    }, [timeframe]);

    useEffect(() => {
        const getDurationMs = (tf: string) => {
            const unit = tf.slice(-1);
            const val = parseInt(tf);
            if (unit === 'm') return val * 60 * 1000;
            if (unit === 'h') return val * 60 * 60 * 1000;
            if (unit === 'd') return val * 24 * 60 * 60 * 1000;
            return 15 * 60 * 1000;
        };

        const duration = getDurationMs(timeframe);

        const tick = () => {
            const now = Date.now() + serverTimeOffset;
            const candleStart = Math.floor(now / duration) * duration;
            const candleEnd = candleStart + duration;

            // Logic: Lock at 90%
            const lockTime = candleStart + (duration * 0.9);

            let locked = false;
            let targetTime = 0;
            let reason = "";

            if (now < lockTime) {
                locked = false;
                targetTime = lockTime;
                reason = "LOCKS IN";
            } else {
                locked = true;
                targetTime = candleEnd;
                reason = "NEXT ROUND";
            }

            if (locked !== isLocked) {
                setIsLocked(locked);
                onLockChangeRef.current(locked);
            }

            const diff = targetTime - now;
            if (diff > 0) {
                const h = Math.floor((diff / (1000 * 60 * 60)) % 24).toString().padStart(2, '0');
                const m = Math.floor((diff / 1000 / 60) % 60).toString().padStart(2, '0');
                const s = Math.floor((diff / 1000) % 60).toString().padStart(2, '0');

                if (h !== "00") {
                    setDisplayTime(`${h}:${m}:${s}`);
                } else {
                    setDisplayTime(`${m}:${s}`);
                }
            } else {
                setDisplayTime("00:00");
            }

            setLabel(reason);
        };

        tick();
        const interval = setInterval(tick, 1000);
        return () => clearInterval(interval);
    }, [timeframe, isLocked, serverTimeOffset]);

    return (
        <div className="flex items-center gap-2 bg-black/40 px-3 py-1.5 rounded-lg border border-white/5 backdrop-blur-md">
            {isLocked ? (
                <Lock className="w-3.5 h-3.5 text-rose-500 animate-pulse" />
            ) : (
                <Timer className="w-3.5 h-3.5 text-emerald-500" />
            )}
            <div className="flex flex-col leading-none">
                <span className="text-[10px] text-muted-foreground font-bold">{label}</span>
                <span className={cn(
                    "text-sm font-mono font-bold tabular-nums tracking-wide",
                    isLocked ? "text-rose-400" : "text-emerald-400"
                )}>
                    {displayTime}
                </span>
            </div>
        </div>
    );
}
