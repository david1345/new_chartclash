"use client";

import { cn } from "@/lib/utils";
import { ArrowUp, ArrowDown, Target, Clock, Activity } from "lucide-react";

interface ActivePositionPanelProps {
    prediction: {
        direction: "UP" | "DOWN";
        entry_price?: number;
        target_percent?: number;
        bet_amount: number;
        timeframe: string;
        candle_close_at: string;
    };
    currentPrice: number | null;
}

export function ActivePositionPanel({ prediction, currentPrice }: ActivePositionPanelProps) {
    if (!prediction) return null;

    const { direction, entry_price, target_percent, bet_amount, timeframe, candle_close_at } = prediction;
    const isUp = direction === "UP";
    const colorClass = isUp ? "text-emerald-400" : "text-rose-400";
    const bgClass = isUp ? "bg-emerald-500/10 border-emerald-500/30" : "bg-rose-500/10 border-rose-500/30";
    const Icon = isUp ? ArrowUp : ArrowDown;

    // Calculate live distance if currentPrice and entry_price are available
    let priceDiffPercent = 0;
    if (currentPrice && entry_price) {
        priceDiffPercent = ((currentPrice - entry_price) / entry_price) * 100;
    }

    // Determine current winning state
    let isWinning = false;
    if (currentPrice && entry_price) {
        isWinning = isUp ? currentPrice > entry_price : currentPrice < entry_price;
    }

    return (
        <div className="flex flex-col h-full bg-[#0F1623] border border-[#1E2D45] rounded-xl overflow-hidden relative group">
            {/* Background Glow */}
            <div className={cn("absolute -top-20 -right-20 w-40 h-40 blur-[80px] opacity-20 rounded-full", isUp ? "bg-emerald-500" : "bg-rose-500")} />

            {/* Header */}
            <div className={cn("px-3 py-2 flex justify-between items-center border-b border-[#1E2D45]", bgClass)}>
                <div className="flex items-center gap-1.5">
                    <Activity className="w-3.5 h-3.5 text-white/70" />
                    <span className="text-[10px] uppercase font-bold tracking-widest text-white/70">My Position</span>
                </div>
                <div className={cn("flex items-center gap-1 font-black text-sm", colorClass)}>
                    <Icon className="w-4 h-4" />
                    {direction}
                </div>
            </div>

            {/* Content */}
            <div className="p-3 flex flex-col gap-3 relative z-10 flex-1 justify-center">

                {/* Entry vs Current */}
                <div className="grid grid-cols-2 gap-2 relative">
                    <div className="flex flex-col gap-1 items-start">
                        <span className="text-[9px] text-[#5A7090] font-bold uppercase tracking-widest uppercase">Entry Price</span>
                        <span className="font-mono text-sm font-bold text-white">
                            ${entry_price ? entry_price.toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 }) : "---"}
                        </span>
                    </div>

                    {/* Divider Arrow */}
                    <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-[#1E2D45]">
                        <div className="w-4 border-t border-dashed border-[#1E2D45]" />
                    </div>

                    <div className="flex flex-col gap-1 items-end">
                        <span className="text-[9px] text-[#5A7090] font-bold uppercase tracking-widest uppercase">Current Price</span>
                        <span className={cn("font-mono text-sm font-black", currentPrice ? (isWinning ? colorClass : "text-white") : "text-white")}>
                            {currentPrice ? `$${currentPrice.toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 })}` : "Loading..."}
                        </span>
                    </div>
                </div>

                {/* Status Bar */}
                <div className="bg-[#141D2E] rounded-lg p-2 flex items-center justify-between border border-[#1E2D45]">
                    <div className="flex items-center gap-2">
                        <div className="bg-[#0F1623] px-2 py-1 rounded text-[10px] font-mono font-bold border border-[#1E2D45] text-white">
                            {bet_amount} PTS
                        </div>
                    </div>

                    <div className="flex items-center gap-2 text-right">
                        <div className="flex flex-col items-end">
                            <span className="text-[9px] text-[#5A7090] font-bold uppercase tracking-widest">Target</span>
                            <div className={cn("flex items-center gap-1 text-xs font-black", colorClass)}>
                                {target_percent}%
                            </div>
                        </div>
                    </div>
                </div>

                {/* Visual indicator of Winning/Losing */}
                {currentPrice && entry_price && (
                    <div className="pt-1">
                        <div className="flex justify-between items-center text-[10px] mb-1 font-bold">
                            <span className={isWinning ? colorClass : "text-gray-500"}>
                                {isWinning ? "WINNING" : "LOSING"}
                            </span>
                            <span className={isWinning ? colorClass : "text-gray-500 font-mono"}>
                                {isUp ? "+" : ""}{priceDiffPercent.toFixed(2)}%
                            </span>
                        </div>
                        <div className="h-1 w-full bg-[#141D2E] rounded-full overflow-hidden">
                            <div
                                className={cn("h-full rounded-full transition-all duration-500", isWinning ? (isUp ? "bg-emerald-500" : "bg-rose-500") : "bg-gray-600")}
                                style={{ width: "100%" }} // In a real app with strict bounds, calculate width based on distance to target.
                            />
                        </div>
                    </div>
                )}
            </div>

            {/* Waiting Overlay when price is loading */}
            {(!currentPrice || !entry_price) && (
                <div className="absolute inset-0 bg-[#0F1623]/80 backdrop-blur-sm z-20 flex items-center justify-center">
                    <div className="flex flex-col items-center gap-2 animate-pulse">
                        <Target className="w-6 h-6 text-primary" />
                        <span className="text-xs font-bold text-primary tracking-widest uppercase">Initializing Position...</span>
                    </div>
                </div>
            )}
        </div>
    );
}
