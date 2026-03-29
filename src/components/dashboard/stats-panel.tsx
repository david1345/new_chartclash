"use client";

import { useEffect, useState } from "react";
import { ArrowDownRight, ArrowUpRight, Scale, Wallet2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";

interface StatsPanelProps {
    assetSymbol: string;
    timeframe: string;
}

type LiveStats = {
    longCount: number;
    shortCount: number;
    longStake: number;
    shortStake: number;
    totalStake: number;
};

const EMPTY_STATS: LiveStats = {
    longCount: 0,
    shortCount: 0,
    longStake: 0,
    shortStake: 0,
    totalStake: 0,
};

export function StatsPanel({ assetSymbol, timeframe }: StatsPanelProps) {
    const [stats, setStats] = useState<LiveStats>(EMPTY_STATS);
    const supabase = createClient();

    useEffect(() => {
        const fetchStats = async () => {
            const { data } = await supabase
                .from("predictions")
                .select("direction, bet_amount")
                .eq("asset_symbol", assetSymbol)
                .eq("timeframe", timeframe)
                .eq("status", "pending")
                .gt("candle_close_at", new Date().toISOString());

            if (!data) {
                setStats(EMPTY_STATS);
                return;
            }

            const nextStats = data.reduce<LiveStats>((acc, row) => {
                const amount = Number(row.bet_amount || 0);
                if (row.direction === "UP") {
                    acc.longCount += 1;
                    acc.longStake += amount;
                } else {
                    acc.shortCount += 1;
                    acc.shortStake += amount;
                }
                acc.totalStake += amount;
                return acc;
            }, { ...EMPTY_STATS });

            setStats(nextStats);
        };

        fetchStats();

        const channel = supabase
            .channel(`live-positioning:${assetSymbol}:${timeframe}`)
            .on("postgres_changes", { event: "*", schema: "public", table: "predictions" }, fetchStats)
            .subscribe();

        const interval = setInterval(fetchStats, 15000);

        return () => {
            supabase.removeChannel(channel);
            clearInterval(interval);
        };
    }, [assetSymbol, supabase, timeframe]);

    const longShare = stats.totalStake > 0 ? (stats.longStake / stats.totalStake) * 100 : 0;
    const shortShare = stats.totalStake > 0 ? (stats.shortStake / stats.totalStake) * 100 : 0;

    return (
        <Card className="bg-[#0F1623] border-[#1E2D45] w-full overflow-hidden flex flex-col">
            <CardHeader className="py-3 px-4 border-b border-[#1E2D45] bg-[#141D2E]">
                <CardTitle className="flex items-center gap-2 text-sm uppercase tracking-wider">
                    <Scale className="w-4 h-4 text-primary" />
                    Live Positioning
                    <span className="text-muted-foreground ml-1">({assetSymbol} / {timeframe})</span>
                </CardTitle>
            </CardHeader>
            <CardContent className="p-4 space-y-4">
                <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
                    <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#6E839C]">
                        <Wallet2 className="h-3.5 w-3.5 text-[#00E5B4]" />
                        Total Live Stake
                    </div>
                    <div className="mt-2 text-2xl font-black text-white">{stats.totalStake.toFixed(2)} USDT</div>
                </div>

                <div className="space-y-3">
                    <div className="rounded-2xl border border-[#00E5B4]/20 bg-[#08161C] p-4">
                        <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#9FF8E2]">
                                <ArrowUpRight className="h-3.5 w-3.5" />
                                Long Desk
                            </div>
                            <div className="text-sm font-black text-[#00E5B4]">{longShare.toFixed(0)}%</div>
                        </div>
                        <div className="mt-2 text-sm font-black text-white">{stats.longStake.toFixed(2)} USDT</div>
                        <div className="mt-1 text-xs text-[#8BA3BF]">{stats.longCount} open positions</div>
                    </div>

                    <div className="rounded-2xl border border-[#FF6B6B]/20 bg-[#170F14] p-4">
                        <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#FFC2C2]">
                                <ArrowDownRight className="h-3.5 w-3.5" />
                                Short Desk
                            </div>
                            <div className="text-sm font-black text-[#FF9A9A]">{shortShare.toFixed(0)}%</div>
                        </div>
                        <div className="mt-2 text-sm font-black text-white">{stats.shortStake.toFixed(2)} USDT</div>
                        <div className="mt-1 text-xs text-[#8BA3BF]">{stats.shortCount} open positions</div>
                    </div>
                </div>
            </CardContent>
        </Card>
    );
}
