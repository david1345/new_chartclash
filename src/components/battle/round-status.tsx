"use client";

import { useState, useEffect } from "react";
import { Clock, Zap } from "lucide-react";
import { cn } from "@/lib/utils";

interface RoundStatusProps {
    timeframe: string;
    referencePrice: number | null;
    candleElapsed: number | null;
    isLocked: boolean;
}

export function RoundStatus({ timeframe, referencePrice, candleElapsed, isLocked }: RoundStatusProps) {
    const [localElapsed, setLocalElapsed] = useState(candleElapsed || 0);

    useEffect(() => {
        setLocalElapsed(candleElapsed || 0);
    }, [candleElapsed]);

    useEffect(() => {
        const interval = setInterval(() => {
            setLocalElapsed((prev) => prev + 1);
        }, 1000);
        return () => clearInterval(interval);
    }, []);

    const totalSeconds = timeframe === '1h' ? 3600 : timeframe === '4h' ? 14400 : 3600;
    const remaining = Math.max(0, totalSeconds - localElapsed);

    const h = Math.floor(remaining / 3600);
    const m = Math.floor((remaining % 3600) / 60);
    const s = remaining % 60;

    const ratio = Math.min(1, localElapsed / totalSeconds);
    let zoneColor = "bg-[#00E5B4]";
    let textColor = "text-[#00E5B4]";

    if (ratio > 0.3) {
        zoneColor = "bg-[#F5A623]";
        textColor = "text-[#F5A623]";
    }
    if (ratio > 0.6) {
        zoneColor = "bg-[#FF4560]";
        textColor = "text-[#FF4560]";
    }
    if (isLocked) {
        zoneColor = "bg-[#FF4560]"; // Keep red when locked instead of gray for intensity
        textColor = "text-[#FF4560]";
    }

    return (
        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-2 mb-1.5 relative overflow-hidden">
            {/* Background Glow */}
            <div className={cn("absolute -top-10 -right-10 w-32 h-32 blur-[60px] opacity-20 rounded-full", isLocked ? "bg-red-500" : zoneColor)} />

            <div className="flex justify-between items-center relative z-10 mb-1.5">
                <div>
                    <div className="flex items-center gap-1.5 mb-0.5">
                        <div className="w-1.5 h-1.5 rounded-full bg-[#00E5B4] animate-pulse" />
                        <span className="text-[10px] font-black text-white uppercase tracking-wider text-[#00E5B4]">Live Round</span>
                    </div>
                    <div className="text-xl font-black font-mono tracking-tighter text-white leading-none">
                        ${referencePrice ? referencePrice.toLocaleString() : "---"}
                    </div>
                    <div className="text-[9px] text-[#5A7090] uppercase font-bold tracking-widest mt-0.5">Ref Price</div>
                </div>

                <div className="flex flex-col items-end">
                    <div className={cn("flex items-center gap-1.5 px-2 py-1 rounded bg-[#0F1623] border", isLocked ? "border-[#FF4560]" : "border-[#1E2D45]")}>
                        <Clock className={cn("w-3.5 h-3.5", isLocked ? "text-[#FF4560]" : textColor)} />
                        <span className={cn("font-mono text-sm font-black leading-none", isLocked ? "text-[#FF4560]" : textColor)}>
                            {isLocked ? "LOCKED" : `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`}
                        </span>
                    </div>
                    <div className="text-[9px] text-[#8BA3BF] font-bold uppercase mt-1">Until close</div>
                </div>
            </div>

            {/* Timeline Bar */}
            <div className="w-full h-1.5 bg-[#0F1623] rounded-full overflow-hidden">
                <div
                    className={cn("h-full transition-all duration-1000 shadow-[0_0_10px_rgba(0,0,0,0.5)]", zoneColor)}
                    style={{ width: `${ratio * 100}%` }}
                />
            </div>
        </div>
    );
}
