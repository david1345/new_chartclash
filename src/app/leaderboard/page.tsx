"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Trophy, Flame, Shield, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { cn } from "@/lib/utils";

import { motion, AnimatePresence } from "framer-motion";

export default function LeaderboardPage() {
    const [leaders, setLeaders] = useState<any[]>([]);

    const [userRank, setUserRank] = useState<any>(null);
    const leaderType = "USER"; // Hardcoded as filter was removed
    const [isLoading, setIsLoading] = useState(true);
    const [fetchError, setFetchError] = useState<string | null>(null);
    const supabase = createClient();

    useEffect(() => {
        fetchLeaderboard();

        // --- REALTIME SUBSCRIPTION ---
        const channel = supabase
            .channel('leaderboard-updates')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'profiles'
                },
                (payload) => {
                    fetchLeaderboard();
                }
            )
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, []);

    const fetchLeaderboard = async () => {
        setIsLoading(true);
        console.log("[Leaderboard] Fetching", leaderType, "data...");

        const query = supabase
            .from('profiles')
            .select('id, username, points, total_games, total_wins, streak_count, streak')
            .eq('is_bot', false) // Filter by bot status
            .order('points', { ascending: false })
            .limit(100);

        const { data: profiles, error } = await query;

        if (error) {
            console.error("[Leaderboard] Fetch error:", error);
            setFetchError(error.message);
            setIsLoading(false);
            return;
        }

        setFetchError(null);

        if (profiles) {
            const enriched = profiles.map((p, i) => ({
                ...p,
                rank: i + 1,
                winRate: p.total_games > 0 ? Math.round((p.total_wins / p.total_games) * 100) : 0,
                streak: Math.max(p.streak || 0, p.streak_count || 0)
            }));
            setLeaders(enriched);

            // Identify current user 
            const { data: { user } } = await supabase.auth.getUser();

            if (user) {
                const myProfile = enriched.find(p => p.id === user.id);
                if (myProfile) {
                    setUserRank(myProfile);
                } else {
                    const { data: rank } = await supabase.rpc('get_user_rank', { p_user_id: user.id });
                    const { data: myData } = await supabase
                        .from('profiles')
                        .select('id, username, points, total_games, total_wins, streak_count, streak, tier')
                        .eq('id', user.id)
                        .single();

                    if (myData) {
                        setUserRank({
                            ...myData,
                            rank: rank || '100+',
                            winRate: myData.total_games > 0 ? Math.round((myData.total_wins / myData.total_games) * 100) : 0,
                            streak: Math.max(myData.streak_count || 0, myData.streak || 0)
                        });
                    }
                }
            } else {
                setUserRank(null);
            }
        }
        setIsLoading(false);
    };

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            {/* Header */}
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
                        <Button variant="outline" onClick={() => fetchLeaderboard()} className="border-white/10 hover:bg-white/5">
                            Try Again
                        </Button>
                    </div>
                )}

                {isLoading && leaders.length === 0 && (
                    <div className="flex items-center justify-center py-20">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
                    </div>
                )}

                {!isLoading && leaders.length === 0 && !fetchError && (
                    <div className="flex flex-col items-center justify-center py-20 gap-2 opacity-50">
                        <Trophy className="w-12 h-12 mb-2" />
                        <div className="text-xl font-bold">No Records Found</div>
                        <p className="text-sm">Be the first one to join the leaderboard!</p>
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
                                            <th className="px-2 py-1">Nickname</th>
                                            <th className="px-2 py-1 text-right">Balance</th>
                                            <th className="px-2 py-1 text-right hidden md:table-cell">Efficiency</th>
                                            <th className="px-2 py-1 text-right hidden md:table-cell">Hot Streak</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5 text-xs">
                                        <AnimatePresence mode="popLayout">
                                            {leaders.map((leader) => (
                                                <motion.tr
                                                    key={leader.id}
                                                    data-testid="leaderboard-item"
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
                                                                <AvatarImage src={leader.avatar_url} />
                                                                <AvatarFallback className="text-[9px] bg-white/5">{leader.username?.slice(0, 2).toUpperCase()}</AvatarFallback>
                                                            </Avatar>
                                                            <div className="flex flex-col leading-tight">
                                                                <span className="font-bold text-white group-hover:text-primary transition-colors text-xs">{leader.username}</span>
                                                                <span className="text-[9px] text-muted-foreground uppercase">{leader.total_games} trades</span>
                                                            </div>
                                                        </div>
                                                    </td>
                                                    <td className="px-2 py-1 text-right font-mono text-yellow-500 font-bold text-xs">
                                                        {leader.points.toLocaleString()}
                                                    </td>
                                                    <td className="px-2 py-1 text-right hidden md:table-cell">
                                                        <div className="flex flex-col items-end leading-tight">
                                                            <span className={cn(
                                                                "font-bold text-xs",
                                                                leader.winRate > 60 ? "text-emerald-500" : leader.winRate > 40 ? "text-yellow-500" : "text-red-500"
                                                            )}>
                                                                {leader.winRate}%
                                                            </span>
                                                            <span className="text-[7px] text-muted-foreground uppercase tracking-tighter">Win Rate</span>
                                                        </div>
                                                    </td>
                                                    <td className="px-2 py-1 text-right hidden md:table-cell">
                                                        <div className="flex justify-end">
                                                            <Badge variant="outline" className={cn(
                                                                "border-orange-500/50 text-orange-500 bg-orange-500/10 gap-1 px-1 py-0 text-[10px]",
                                                                leader.streak > 0 && "animate-pulse",
                                                                leader.streak === 0 && "opacity-30 border-white/10 text-white bg-transparent"
                                                            )}>
                                                                <Flame className="w-2.5 h-2.5" /> {leader.streak}
                                                            </Badge>
                                                        </div>
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

            {/* Sticky My Position Bar */}
            {userRank && (
                <motion.div
                    initial={{ y: 100 }}
                    animate={{ y: 0 }}
                    data-testid="user-rank"
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
                                    Nickname: <span className="text-primary font-bold uppercase">{userRank.username}</span>
                                    {typeof userRank.rank === 'number' && ` · Top ${Math.max(1, Math.floor((userRank.rank / Math.max(leaders.length, 1)) * 100))}%`}
                                </span>
                            </div>
                        </div>
                        <div className="flex items-center gap-6">
                            <div className="text-right hidden sm:block">
                                <div className="text-[10px] text-muted-foreground uppercase font-bold">Accuracy</div>
                                <div className="font-mono font-bold text-emerald-500">{userRank.winRate}%</div>
                            </div>
                            <div className="text-right">
                                <div className="text-[10px] text-muted-foreground uppercase font-bold">Net Points</div>
                                <div className="font-mono font-bold text-yellow-500 text-xl">{userRank.points.toLocaleString()}</div>
                            </div>
                        </div>
                    </div>
                </motion.div>
            )}
        </div>
    );
}
