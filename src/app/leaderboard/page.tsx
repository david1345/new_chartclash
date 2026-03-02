"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Trophy, Medal, Flame, TrendingUp, Shield, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { cn } from "@/lib/utils";

import { motion, AnimatePresence } from "framer-motion";

export default function LeaderboardPage() {
    const [leaders, setLeaders] = useState<any[]>([]);

    const [userRank, setUserRank] = useState<any>(null);
    const [leaderType, setLeaderType] = useState<"USER" | "AI">("USER");
    const [filterTimeframe, setFilterTimeframe] = useState("OVERALL");
    const [filterAsset, setFilterAsset] = useState("ALL");
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
    }, [filterTimeframe, filterAsset, leaderType]);

    const fetchLeaderboard = async () => {
        setIsLoading(true);
        console.log("[Leaderboard] Fetching", leaderType, "data...");

        const query = supabase
            .from('profiles')
            .select('id, username, points, total_games, total_wins, streak_count, streak')
            .eq('is_bot', leaderType === "AI") // Filter by bot status
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

            // Identify current user (Only if viewing USERS)
            const { data: { user } } = await supabase.auth.getUser();

            if (user && leaderType === "USER") {
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
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
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

            <div className="flex-1 container mx-auto px-4 py-6 space-y-6 pb-24">
                {/* User/AI Toggle */}
                <div className="flex bg-white/5 p-1 rounded-xl border border-white/10 w-fit">
                    <button
                        onClick={() => setLeaderType("USER")}
                        className={cn(
                            "px-8 py-2 text-sm font-bold uppercase transition-all rounded-lg",
                            leaderType === "USER"
                                ? "bg-primary text-white shadow-[0_0_20px_rgba(59,130,246,0.5)]"
                                : "text-muted-foreground hover:text-white"
                        )}
                    >
                        Users
                    </button>
                    <button
                        onClick={() => setLeaderType("AI")}
                        className={cn(
                            "px-8 py-2 text-sm font-bold uppercase transition-all rounded-lg",
                            leaderType === "AI"
                                ? "bg-purple-600 text-white shadow-[0_0_20px_rgba(147,51,234,0.5)]"
                                : "text-muted-foreground hover:text-white"
                        )}
                    >
                        AI Analysts
                    </button>
                </div>



                {/* Filters */}
                <div className="flex flex-col md:flex-row gap-4 justify-between items-center">
                    <Tabs defaultValue="OVERALL" onValueChange={setFilterTimeframe} className="w-full md:w-auto">
                        <TabsList className="bg-white/5 border border-white/5">
                            <TabsTrigger value="OVERALL">Overall</TabsTrigger>
                            <TabsTrigger value="WEEKLY" disabled>Weekly</TabsTrigger>
                            <TabsTrigger value="SEASON" disabled>Season</TabsTrigger>
                        </TabsList>
                    </Tabs>

                    <Select defaultValue="ALL" onValueChange={setFilterAsset}>
                        <SelectTrigger className="w-full md:w-[180px] bg-white/5 border-white/10">
                            <SelectValue placeholder="Asset Class" />
                        </SelectTrigger>
                        <SelectContent className="bg-[#0b0b0f] border-white/10 text-white">
                            <SelectItem value="ALL">All Assets</SelectItem>
                            <SelectItem value="CRYPTO" disabled>Crypto Only</SelectItem>
                            <SelectItem value="STOCKS" disabled>Stocks Only</SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                {fetchError ? (
                    <div className="flex flex-col items-center justify-center py-20 gap-4">
                        <Shield className="w-12 h-12 text-red-500 opacity-50" />
                        <div className="text-red-500 font-mono text-sm bg-red-500/10 p-4 rounded-lg border border-red-500/20 max-w-md text-center">
                            Error: {fetchError}
                        </div>
                        <Button variant="outline" onClick={() => fetchLeaderboard()} className="border-white/10 hover:bg-white/5">
                            Try Again
                        </Button>
                    </div>
                ) : isLoading && leaders.length === 0 ? (
                    <div className="flex items-center justify-center py-20">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
                    </div>
                ) : leaders.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-20 gap-2 opacity-50">
                        <Trophy className="w-12 h-12 mb-2" />
                        <div className="text-xl font-bold">No Records Found</div>
                        <p className="text-sm">Be the first one to join the leaderboard!</p>
                    </div>
                ) : (
                    <>
                        {/* Top 3 Podium */}
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4">
                            <AnimatePresence mode="popLayout">
                                {leaders.slice(0, 3).map((leader, i) => (
                                    <motion.div
                                        key={leader.id}
                                        layout
                                        initial={{ opacity: 0, y: 20 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        exit={{ opacity: 0, scale: 0.9 }}
                                        transition={{ duration: 0.5, delay: i * 0.1 }}
                                        className={cn(
                                            "order-last md:order-none",
                                            i === 0 ? "md:order-2 md:-mt-6" : i === 1 ? "md:order-1" : "md:order-3"
                                        )}
                                    >
                                        <Card className={cn(
                                            "bg-card/20 border-white/10 relative overflow-hidden h-full",
                                            i === 0 ? "border-yellow-500/50 bg-yellow-500/5 shadow-[0_0_30px_rgba(234,179,8,0.1)]" :
                                                i === 1 ? "border-gray-400/50" : "border-amber-700/50"
                                        )}>
                                            <CardContent className="p-6 flex flex-col items-center text-center gap-2">
                                                <div className="absolute top-2 right-2 opacity-10">
                                                    <Trophy className="w-16 h-16" />
                                                </div>
                                                <div className="relative">
                                                    <Avatar className={cn("w-20 h-20 border-4", i === 0 ? "border-yellow-500" : i === 1 ? "border-gray-400" : "border-amber-700")}>
                                                        <AvatarImage src={leader.avatar_url} />
                                                        <AvatarFallback className="bg-white/5 text-xl">{leader.username?.slice(0, 2).toUpperCase()}</AvatarFallback>
                                                    </Avatar>
                                                    <div className={cn(
                                                        "absolute -bottom-2 -right-2 w-8 h-8 rounded-full flex items-center justify-center font-bold text-black",
                                                        i === 0 ? "bg-yellow-500" : i === 1 ? "bg-gray-400" : "bg-amber-700"
                                                    )}>
                                                        {i + 1}
                                                    </div>
                                                </div>
                                                <div className="space-y-1 mt-4">
                                                    <div className="text-xl font-bold text-white truncate max-w-[150px]">{leader.username}</div>
                                                    <div className="text-lg font-mono font-bold text-yellow-500">{leader.points.toLocaleString()} <span className="text-xs text-muted-foreground">pts</span></div>
                                                </div>
                                                <div className="flex gap-2 mt-2">
                                                    <Badge variant="outline" className="border-emerald-500/30 text-emerald-500 bg-emerald-500/5">
                                                        {leader.winRate}% WR
                                                    </Badge>
                                                    <Badge variant="outline" className={cn(
                                                        "border-orange-500/30 text-orange-500 bg-orange-500/5",
                                                        leader.streak === 0 && "opacity-40 grayscale"
                                                    )}>
                                                        <Flame className="w-3 h-3 mr-1" /> {leader.streak}
                                                    </Badge>
                                                </div>
                                            </CardContent>
                                        </Card>
                                    </motion.div>
                                ))}
                            </AnimatePresence>
                        </div>

                        {/* Ranking List */}
                        <Card className="bg-card/10 border-white/5 overflow-hidden">
                            <CardHeader className="pb-2 bg-white/5 border-b border-white/5">
                                <CardTitle className="text-sm font-medium text-muted-foreground uppercase tracking-wider">Top 100 Rankers</CardTitle>
                            </CardHeader>
                            <CardContent className="p-0">
                                <div className="overflow-x-auto">
                                    <table className="w-full text-sm text-left">
                                        <thead className="bg-[#0b0b0f] text-muted-foreground font-medium border-b border-white/5">
                                            <tr>
                                                <th className="px-6 py-4 w-[80px] text-center">Rank</th>
                                                <th className="px-6 py-4">Nickname</th>
                                                <th className="px-6 py-4 text-right">Balance</th>
                                                <th className="px-6 py-4 text-right hidden md:table-cell">Efficiency</th>
                                                <th className="px-6 py-4 text-right hidden md:table-cell">Hot Streak</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-white/5">
                                            <AnimatePresence mode="popLayout">
                                                {leaders.slice(3).map((leader) => (
                                                    <motion.tr
                                                        key={leader.id}
                                                        data-testid="leaderboard-item"
                                                        layout
                                                        initial={{ opacity: 0 }}
                                                        animate={{ opacity: 1 }}
                                                        exit={{ opacity: 0 }}
                                                        className="hover:bg-white/5 transition-colors group relative"
                                                    >
                                                        <td className="px-6 py-4 text-center font-mono font-bold text-muted-foreground group-hover:text-white transition-colors">
                                                            #{leader.rank}
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <div className="flex items-center gap-3">
                                                                <Avatar className="w-9 h-9 border border-white/10">
                                                                    <AvatarImage src={leader.avatar_url} />
                                                                    <AvatarFallback className="text-[10px] bg-white/5">{leader.username?.slice(0, 2).toUpperCase()}</AvatarFallback>
                                                                </Avatar>
                                                                <div className="flex flex-col">
                                                                    <span className="font-bold text-white group-hover:text-primary transition-colors">{leader.username}</span>
                                                                    <span className="text-[10px] text-muted-foreground uppercase">{leader.total_games} trades</span>
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4 text-right font-mono text-yellow-500 font-bold text-lg">
                                                            {leader.points.toLocaleString()}
                                                        </td>
                                                        <td className="px-6 py-4 text-right hidden md:table-cell">
                                                            <div className="flex flex-col items-end">
                                                                <span className={cn(
                                                                    "font-bold",
                                                                    leader.winRate > 60 ? "text-emerald-500" : leader.winRate > 40 ? "text-yellow-500" : "text-red-500"
                                                                )}>
                                                                    {leader.winRate}%
                                                                </span>
                                                                <span className="text-[9px] text-muted-foreground uppercase tracking-tighter">Win Rate</span>
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4 text-right hidden md:table-cell">
                                                            <div className="flex justify-end">
                                                                <Badge variant="outline" className={cn(
                                                                    "border-orange-500/50 text-orange-500 bg-orange-500/10 gap-1",
                                                                    leader.streak > 0 && "animate-pulse",
                                                                    leader.streak === 0 && "opacity-30 border-white/10 text-white bg-transparent"
                                                                )}>
                                                                    <Flame className="w-3 h-3" /> {leader.streak}
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
                    </>
                )}
            </div>

            {/* Sticky My Position Bar */}
            {
                userRank && (
                    <motion.div
                        initial={{ y: 100 }}
                        animate={{ y: 0 }}
                        data-testid="user-rank"
                        className="fixed bottom-0 left-0 w-full bg-[#0b0b0f]/90 backdrop-blur-xl border-t border-white/10 p-4 z-40 shadow-[0_-10px_40px_rgba(0,0,0,0.8)]"
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
                )
            }
        </div >
    );
}
