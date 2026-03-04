"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Target, TrendingUp, Activity, BarChart2, PieChart, Trophy } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

export default function MyStatsPage() {
    const [stats, setStats] = useState<any>(null);
    const supabase = createClient();

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        const { data: { user: realUser } } = await supabase.auth.getUser();
        if (!realUser) return;

        // Ghost Mode logic
        const ghostId = typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null;
        const isImpersonating = ghostId && realUser.email === 'sjustone000@gmail.com';
        const targetId = isImpersonating ? ghostId : realUser.id;

        if (isImpersonating) {
            console.log("👻 STATS: GHOST MODE - Viewing stats for", targetId);
        }

        // Fetch Profile
        const { data: profile } = await supabase.from('profiles').select('*').eq('id', targetId).maybeSingle();

        // Fetch Predictions
        const { data: preds } = await supabase.from('predictions').select('*').eq('user_id', targetId);

        if (preds) {
            const total = preds.length;
            const wins = preds.filter(p => p.status === 'WIN').length;
            const losses = preds.filter(p => p.status === 'LOSE').length;
            const upPicks = preds.filter(p => p.direction === 'UP').length;
            const downPicks = preds.filter(p => p.direction === 'DOWN').length;

            // Mocking some 'Avg Target' as we might not have it easily calculable without loop
            // Mocking some 'Avg Target' as we might not have it easily calculable without loop
            const winRate = total > 0 ? ((wins / total) * 100).toFixed(1) : "0.0";

            // For now, Global rank and streak are mocked since we don't have a direct query for it in this simple view
            const rank = profile?.rank || "Unranked";
            const streak = profile?.current_streak || 0;

            setStats({
                total,
                wins,
                losses,
                winRate,
                streak,
                rank,
                earnings: profile?.total_earnings || 0,
                upPicks,
                downPicks
            });
        }
    };

    if (!stats) return <div className="min-h-screen bg-[#050505] flex items-center justify-center text-white">Loading stats...</div>;

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            {/* Header */}
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

                {/* KPI Grid */}
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    <StatCard data-testid="net-earnings" label="Net P&L" value={`${stats.earnings >= 0 ? '+' : ''}$${stats.earnings.toFixed(2)}`} icon={TrendingUp} color={stats.earnings >= 0 ? "text-[#00E5B4]" : "text-[#FF4560]"} />
                    <StatCard data-testid="win-rate" label="Win Rate" value={`${stats.winRate}%`} icon={Target} highlight />
                    <StatCard data-testid="global-rank" label="Global Rank" value={`#${stats.rank}`} icon={Trophy} color="text-[#F5A623]" />
                    <StatCard data-testid="best-streak" label="Best Streak" value={`${stats.streak} W`} icon={Activity} />
                </div>

                {/* Charts / Details */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

                    {/* Direction Preference */}
                    <Card className="bg-card/10 border-white/5">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2 text-lg">
                                <PieChart className="w-5 h-5 text-blue-500" /> Direction Bias
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex items-center justify-between text-sm font-bold">
                                <span className="text-emerald-500">UP ({stats.upPicks})</span>
                                <span className="text-red-500">DOWN ({stats.downPicks})</span>
                            </div>
                            <div className="h-4 w-full bg-white/5 rounded-full overflow-hidden flex">
                                <div className="h-full bg-emerald-500" style={{ width: `${(stats.upPicks / (stats.total || 1)) * 100}%` }} />
                                <div className="h-full bg-red-500" style={{ width: `${(stats.downPicks / (stats.total || 1)) * 100}%` }} />
                            </div>
                            <p className="text-xs text-muted-foreground text-center">
                                You are {stats.upPicks > stats.downPicks ? "Bullish" : "Bearish"} dominant.
                            </p>
                        </CardContent>
                    </Card>

                    {/* Recent Activity Mock */}
                    <Card className="bg-card/10 border-white/5">
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2 text-lg">
                                <TrendingUp className="w-5 h-5 text-purple-500" /> Recent Performance
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex items-end gap-2 h-[100px]">
                                {[60, 40, 70, 50, 80, 90, 30].map((h, i) => (
                                    <div key={i} className="flex-1 bg-white/10 hover:bg-purple-500/50 transition-colors rounded-t-sm relative group" style={{ height: `${h}%` }}>
                                        <div className="absolute -top-6 left-1/2 -translate-x-1/2 text-xs font-bold opacity-0 group-hover:opacity-100 transition-opacity">
                                            {h}%
                                        </div>
                                    </div>
                                ))}
                            </div>
                            <div className="flex justify-between text-xs text-muted-foreground mt-2">
                                <span>Mon</span>
                                <span>Sun</span>
                            </div>
                        </CardContent>
                    </Card>

                </div>

            </div>
        </div>
    );
}

function StatCard({ label, value, icon: Icon, highlight, color, "data-testid": testId }: any) {
    return (
        <Card data-testid={testId} className={cn("bg-[#141D2E] border-[#1E2D45]", highlight && "border-[#00E5B4]/30 bg-[#00E5B4]/5")}>
            <CardContent className="p-6 flex flex-col items-center text-center gap-2">
                <Icon className={cn("w-5 h-5 mb-1", color || (highlight ? "text-[#00E5B4]" : "text-[#5A7090]"))} />
                <div className={cn("text-2xl font-bold font-mono", color || (highlight && "text-[#00E5B4]"))}>{value}</div>
                <div className="text-[10px] text-[#5A7090] uppercase tracking-widest font-bold mt-1">{label}</div>
            </CardContent>
        </Card>
    )
}
