"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Activity, ArrowLeft, BarChart2, PieChart, Target, TrendingUp, Wallet2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { isAllowedAdminEmail } from "@/lib/admin-client";

type StatsState = {
    total: number;
    settled: number;
    open: number;
    wins: number;
    losses: number;
    refunds: number;
    winRate: string;
    netPnl: number;
    totalVolume: number;
    avgStake: number;
    upPicks: number;
    downPicks: number;
    recentProfits: number[];
};

export default function MyStatsPage() {
    const [stats, setStats] = useState<StatsState | null>(null);
    const supabase = createClient();

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        const {
            data: { user: realUser },
        } = await supabase.auth.getUser();
        if (!realUser) return;

        const ghostId = typeof window !== "undefined" ? sessionStorage.getItem("ghost_target_id") : null;
        const isImpersonating = ghostId && isAllowedAdminEmail(realUser.email);
        const targetId = isImpersonating ? ghostId : realUser.id;

        const { data: preds } = await supabase
            .from("predictions")
            .select("*")
            .eq("user_id", targetId)
            .order("created_at", { ascending: false })
            .limit(200);

        if (!preds) return;

        const settledPreds = preds.filter((prediction) => prediction.status !== "pending");
        const wins = settledPreds.filter((prediction) => prediction.status === "WIN").length;
        const losses = settledPreds.filter((prediction) => prediction.status === "LOSS").length;
        const refunds = settledPreds.filter((prediction) => prediction.status === "ND" || prediction.status === "REFUND").length;
        const decisiveTrades = wins + losses;
        const totalVolume = preds.reduce((sum, prediction) => sum + Number(prediction.bet_amount || 0), 0);
        const netPnl = settledPreds.reduce((sum, prediction) => sum + Number(prediction.profit || 0), 0);
        const recentProfits = settledPreds
            .slice(0, 7)
            .map((prediction) => Number(prediction.profit || 0))
            .reverse();

        setStats({
            total: preds.length,
            settled: settledPreds.length,
            open: preds.filter((prediction) => prediction.status === "pending").length,
            wins,
            losses,
            refunds,
            winRate: decisiveTrades > 0 ? ((wins / decisiveTrades) * 100).toFixed(1) : "0.0",
            netPnl,
            totalVolume,
            avgStake: preds.length > 0 ? totalVolume / preds.length : 0,
            upPicks: preds.filter((prediction) => prediction.direction === "UP").length,
            downPicks: preds.filter((prediction) => prediction.direction === "DOWN").length,
            recentProfits,
        });
    };

    if (!stats) {
        return <div className="min-h-screen bg-[#050505] flex items-center justify-center text-white">Loading stats...</div>;
    }

    const directionTotal = stats.upPicks + stats.downPicks || 1;
    const chartMax = Math.max(...stats.recentProfits.map((value) => Math.abs(value)), 1);

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <Activity className="w-5 h-5 text-emerald-500" /> My Performance
                    </h1>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-8 max-w-5xl pb-20">
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    <StatCard label="Net P&L" value={`${stats.netPnl >= 0 ? "+" : ""}${stats.netPnl.toFixed(2)} USDT`} icon={TrendingUp} color={stats.netPnl >= 0 ? "text-[#00E5B4]" : "text-[#FF8C8C]"} />
                    <StatCard label="Hit Rate" value={`${stats.winRate}%`} icon={Target} highlight />
                    <StatCard label="Settled Bets" value={`${stats.settled}`} icon={BarChart2} color="text-[#F5A623]" />
                    <StatCard label="Open Bets" value={`${stats.open}`} icon={Wallet2} />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <Card className="bg-card/10 border-white/5">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2 text-lg">
                                <PieChart className="w-5 h-5 text-blue-500" /> Direction Bias
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex items-center justify-between text-sm font-bold">
                                <span className="text-emerald-500">LONG ({stats.upPicks})</span>
                                <span className="text-red-500">SHORT ({stats.downPicks})</span>
                            </div>
                            <div className="h-4 w-full bg-white/5 rounded-full overflow-hidden flex">
                                <div className="h-full bg-emerald-500" style={{ width: `${(stats.upPicks / directionTotal) * 100}%` }} />
                                <div className="h-full bg-red-500" style={{ width: `${(stats.downPicks / directionTotal) * 100}%` }} />
                            </div>
                            <div className="grid grid-cols-2 gap-3 text-xs text-muted-foreground">
                                <div className="rounded-lg border border-white/10 bg-white/5 p-3">
                                    Total Volume
                                    <div className="mt-1 font-mono text-white">{stats.totalVolume.toFixed(2)} USDT</div>
                                </div>
                                <div className="rounded-lg border border-white/10 bg-white/5 p-3">
                                    Avg Stake
                                    <div className="mt-1 font-mono text-white">{stats.avgStake.toFixed(2)} USDT</div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="bg-card/10 border-white/5">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2 text-lg">
                                <TrendingUp className="w-5 h-5 text-purple-500" /> Recent Performance
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex items-end gap-2 h-[100px]">
                                {stats.recentProfits.length === 0 ? (
                                    <div className="w-full h-full flex items-center justify-center text-sm text-muted-foreground">
                                        No settled bets yet.
                                    </div>
                                ) : (
                                    stats.recentProfits.map((profit, index) => (
                                        <div
                                            key={`${profit}-${index}`}
                                            className={cn(
                                                "flex-1 rounded-t-sm relative group",
                                                profit >= 0 ? "bg-emerald-500/70 hover:bg-emerald-500" : "bg-red-500/70 hover:bg-red-500"
                                            )}
                                            style={{ height: `${Math.max(18, (Math.abs(profit) / chartMax) * 100)}%` }}
                                        >
                                            <div className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs font-bold opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                                                {profit >= 0 ? "+" : ""}{profit.toFixed(2)}
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                            <div className="grid grid-cols-3 gap-3 mt-4 text-xs text-muted-foreground">
                                <div className="rounded-lg border border-white/10 bg-white/5 p-3">
                                    Wins
                                    <div className="mt-1 text-[#00E5B4] font-bold">{stats.wins}</div>
                                </div>
                                <div className="rounded-lg border border-white/10 bg-white/5 p-3">
                                    Losses
                                    <div className="mt-1 text-[#FF8C8C] font-bold">{stats.losses}</div>
                                </div>
                                <div className="rounded-lg border border-white/10 bg-white/5 p-3">
                                    Refunds
                                    <div className="mt-1 text-[#F5A623] font-bold">{stats.refunds}</div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}

function StatCard({ label, value, icon: Icon, highlight, color }: any) {
    return (
        <Card className={cn("bg-[#141D2E] border-[#1E2D45]", highlight && "border-[#00E5B4]/30 bg-[#00E5B4]/5")}>
            <CardContent className="p-6 flex flex-col items-center text-center gap-2">
                <Icon className={cn("w-5 h-5 mb-1", color || (highlight ? "text-[#00E5B4]" : "text-[#5A7090]"))} />
                <div className={cn("text-2xl font-bold font-mono", color || (highlight && "text-[#00E5B4]"))}>{value}</div>
                <div className="text-[10px] text-[#5A7090] uppercase tracking-widest font-bold mt-1">{label}</div>
            </CardContent>
        </Card>
    );
}
