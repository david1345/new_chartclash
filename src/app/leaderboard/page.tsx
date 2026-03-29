"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowLeft, Shield, Trophy, Wallet2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

type LeaderRow = {
    id: string;
    username: string;
    rank: number;
    netPnl: number;
    hitRate: number;
    settledCount: number;
    liveCount: number;
    totalVolume: number;
};

type PredictionRow = {
    user_id: string;
    status: "pending" | "WIN" | "LOSS" | "ND" | "REFUND";
    profit: number | null;
    bet_amount: number;
};

export default function LeaderboardPage() {
    const [leaders, setLeaders] = useState<LeaderRow[]>([]);
    const [userRank, setUserRank] = useState<LeaderRow | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [fetchError, setFetchError] = useState<string | null>(null);
    const supabase = createClient();

    useEffect(() => {
        fetchLeaderboard();

        const channel = supabase
            .channel("leaderboard-updates")
            .on("postgres_changes", { event: "*", schema: "public", table: "predictions" }, fetchLeaderboard)
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, [supabase]);

    const fetchLeaderboard = async () => {
        setIsLoading(true);

        const [{ data: profiles, error: profilesError }, { data: predictions, error: predictionsError }] = await Promise.all([
            supabase
                .from("profiles")
                .select("id, username")
                .range(0, 499),
            supabase
                .from("predictions")
                .select("user_id, status, profit, bet_amount")
                .range(0, 4999),
        ]);

        if (profilesError || predictionsError) {
            setFetchError(profilesError?.message || predictionsError?.message || "Failed to load leaderboard");
            setIsLoading(false);
            return;
        }

        const aggregates = new Map<string, {
            wins: number;
            losses: number;
            settledCount: number;
            liveCount: number;
            totalVolume: number;
            netPnl: number;
        }>();

        for (const prediction of (predictions || []) as PredictionRow[]) {
            const current = aggregates.get(prediction.user_id) || {
                wins: 0,
                losses: 0,
                settledCount: 0,
                liveCount: 0,
                totalVolume: 0,
                netPnl: 0,
            };

            current.totalVolume += Number(prediction.bet_amount || 0);

            if (prediction.status === "pending") {
                current.liveCount += 1;
            } else {
                current.settledCount += 1;
                current.netPnl += Number(prediction.profit || 0);
                if (prediction.status === "WIN") current.wins += 1;
                if (prediction.status === "LOSS") current.losses += 1;
            }

            aggregates.set(prediction.user_id, current);
        }

        const nextLeaders = (profiles || [])
            .map((profile) => {
                const aggregate = aggregates.get(profile.id);
                if (!aggregate) return null;

                const decisiveTrades = aggregate.wins + aggregate.losses;
                const hitRate = decisiveTrades > 0 ? Math.round((aggregate.wins / decisiveTrades) * 100) : 0;

                return {
                    id: profile.id,
                    username: profile.username || "Trader",
                    rank: 0,
                    netPnl: aggregate.netPnl,
                    hitRate,
                    settledCount: aggregate.settledCount,
                    liveCount: aggregate.liveCount,
                    totalVolume: aggregate.totalVolume,
                } satisfies LeaderRow;
            })
            .filter((leader): leader is LeaderRow => Boolean(leader))
            .sort((a, b) => {
                if (b.netPnl !== a.netPnl) return b.netPnl - a.netPnl;
                if (b.hitRate !== a.hitRate) return b.hitRate - a.hitRate;
                return b.totalVolume - a.totalVolume;
            })
            .map((leader, index) => ({ ...leader, rank: index + 1 }));

        setLeaders(nextLeaders.slice(0, 100));
        setFetchError(null);

        const {
            data: { user },
        } = await supabase.auth.getUser();

        if (user) {
            const mine = nextLeaders.find((leader) => leader.id === user.id) || null;
            setUserRank(mine);
        } else {
            setUserRank(null);
        }

        setIsLoading(false);
    };

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-12 flex items-center gap-4">
                    <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white" asChild>
                        <Link href="/">
                            <ArrowLeft className="w-5 h-5" />
                        </Link>
                    </Button>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <Trophy className="w-5 h-5 text-yellow-500" /> Leaderboard
                    </h1>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-0 pb-24">
                {fetchError && (
                    <div className="flex flex-col items-center justify-center py-20 gap-4">
                        <Shield className="w-12 h-12 text-red-500 opacity-50" />
                        <div className="text-red-500 font-mono text-sm bg-red-500/10 p-4 rounded-lg border border-red-500/20 max-w-md text-center">
                            Error: {fetchError}
                        </div>
                        <Button variant="outline" onClick={fetchLeaderboard} className="border-white/10 hover:bg-white/5">
                            Try Again
                        </Button>
                    </div>
                )}

                {isLoading && leaders.length === 0 && (
                    <div className="flex items-center justify-center py-20">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" />
                    </div>
                )}

                {!isLoading && leaders.length === 0 && !fetchError && (
                    <div className="flex flex-col items-center justify-center py-20 gap-2 opacity-50">
                        <Trophy className="w-12 h-12 mb-2" />
                        <div className="text-xl font-bold">No Settled Bets Yet</div>
                        <p className="text-sm">Be the first trader to close a market in profit.</p>
                    </div>
                )}

                {leaders.length > 0 && !fetchError && (
                    <Card className="bg-card/10 border-white/5 overflow-hidden border-t-0 rounded-t-none">
                        <CardContent className="p-0">
                            <div className="overflow-x-auto">
                                <table className="w-full text-sm text-left">
                                    <thead className="bg-[#0b0b0f] text-muted-foreground font-medium border-b border-white/5 text-xs">
                                        <tr>
                                            <th className="px-2 py-1 w-[40px] text-center">Rank</th>
                                            <th className="px-2 py-1">Trader</th>
                                            <th className="px-2 py-1 text-right">Net P&amp;L</th>
                                            <th className="px-2 py-1 text-right hidden md:table-cell">Hit Rate</th>
                                            <th className="px-2 py-1 text-right hidden md:table-cell">Live Bets</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5 text-xs">
                                        <AnimatePresence mode="popLayout">
                                            {leaders.map((leader) => (
                                                <motion.tr
                                                    key={leader.id}
                                                    layout
                                                    initial={{ opacity: 0 }}
                                                    animate={{ opacity: 1 }}
                                                    exit={{ opacity: 0 }}
                                                    className="hover:bg-white/5 transition-colors group relative"
                                                >
                                                    <td className="px-2 py-1 text-center font-mono font-bold text-muted-foreground group-hover:text-white transition-colors text-xs">
                                                        #{leader.rank}
                                                    </td>
                                                    <td className="px-2 py-1">
                                                        <div className="flex items-center gap-2">
                                                            <Avatar className="w-6 h-6 border border-white/10 hidden sm:block">
                                                                <AvatarFallback className="text-[9px] bg-white/5">
                                                                    {leader.username.slice(0, 2).toUpperCase()}
                                                                </AvatarFallback>
                                                            </Avatar>
                                                            <div className="flex flex-col leading-tight">
                                                                <span className="font-bold text-white group-hover:text-primary transition-colors text-xs">
                                                                    {leader.username}
                                                                </span>
                                                                <span className="text-[9px] text-muted-foreground uppercase">
                                                                    {leader.settledCount} settled · {leader.totalVolume.toFixed(0)} USDT volume
                                                                </span>
                                                            </div>
                                                        </div>
                                                    </td>
                                                    <td className={cn(
                                                        "px-2 py-1 text-right font-mono font-bold text-xs",
                                                        leader.netPnl >= 0 ? "text-[#00E5B4]" : "text-[#FF8C8C]"
                                                    )}>
                                                        {leader.netPnl >= 0 ? "+" : ""}{leader.netPnl.toFixed(2)}
                                                    </td>
                                                    <td className="px-2 py-1 text-right hidden md:table-cell">
                                                        <div className="flex flex-col items-end leading-tight">
                                                            <span className={cn(
                                                                "font-bold text-xs",
                                                                leader.hitRate >= 60 ? "text-emerald-500" : leader.hitRate >= 40 ? "text-yellow-500" : "text-red-500"
                                                            )}>
                                                                {leader.hitRate}%
                                                            </span>
                                                            <span className="text-[7px] text-muted-foreground uppercase tracking-tighter">Win Rate</span>
                                                        </div>
                                                    </td>
                                                    <td className="px-2 py-1 text-right hidden md:table-cell">
                                                        <Badge variant="outline" className="border-[#00E5B4]/30 bg-[#00E5B4]/10 text-[#00E5B4] text-[10px]">
                                                            {leader.liveCount} open
                                                        </Badge>
                                                    </td>
                                                </motion.tr>
                                            ))}
                                        </AnimatePresence>
                                    </tbody>
                                </table>
                            </div>
                        </CardContent>
                    </Card>
                )}
            </div>

            {userRank && (
                <motion.div
                    initial={{ y: 100 }}
                    animate={{ y: 0 }}
                    className="fixed bottom-0 left-0 w-full bg-[#0b0b0f]/90 backdrop-blur-xl border-t border-white/10 p-3 z-40 shadow-[0_-10px_40px_rgba(0,0,0,0.8)]"
                >
                    <div className="container mx-auto flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-xl bg-primary/20 flex flex-col items-center justify-center border border-primary/30">
                                <span className="text-[10px] text-primary font-bold uppercase tracking-tighter">Rank</span>
                                <span className="font-mono text-lg font-bold text-white leading-tight">#{userRank.rank}</span>
                            </div>
                            <div className="flex flex-col">
                                <span className="text-sm font-bold text-white flex items-center gap-2">
                                    {userRank.username}
                                    <Badge className="bg-primary/20 text-primary border-0 h-4 text-[9px] uppercase">You</Badge>
                                </span>
                                <span className="text-xs text-muted-foreground">
                                    {userRank.settledCount} settled · {userRank.liveCount} live
                                </span>
                            </div>
                        </div>
                        <div className="flex items-center gap-6">
                            <div className="text-right hidden sm:block">
                                <div className="text-[10px] text-muted-foreground uppercase font-bold">Accuracy</div>
                                <div className="font-mono font-bold text-emerald-500">{userRank.hitRate}%</div>
                            </div>
                            <div className="text-right">
                                <div className="text-[10px] text-muted-foreground uppercase font-bold flex items-center gap-1 justify-end">
                                    <Wallet2 className="w-3 h-3" />
                                    Net P&amp;L
                                </div>
                                <div className={cn(
                                    "font-mono font-bold text-xl",
                                    userRank.netPnl >= 0 ? "text-yellow-500" : "text-[#FF8C8C]"
                                )}>
                                    {userRank.netPnl >= 0 ? "+" : ""}{userRank.netPnl.toFixed(2)}
                                </div>
                            </div>
                        </div>
                    </div>
                </motion.div>
            )}
        </div>
    );
}
