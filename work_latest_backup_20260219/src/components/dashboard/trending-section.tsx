"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { ASSETS } from "@/lib/constants";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Flame, Trophy, TrendingUp, ArrowRight, Zap, Coins, LineChart } from "lucide-react";
import Link from "next/link";
import { motion } from "framer-motion";
import { MarketCard } from "@/components/dashboard/market-card";


export function TrendingSection() {
    const [trendingAssets, setTrendingAssets] = useState<any[]>([]);
    const [topLeaders, setTopLeaders] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const supabase = createClient();

    useEffect(() => {
        async function fetchData() {
            try {
                // 1. Fetch Trending Assets (Fetch top 100 to ensure we cover all categories)
                const { data: trendingData, error: trendingError } = await supabase
                    .rpc('get_trending_assets', { limit_count: 100 });

                if (trendingError) console.error("Error fetching trending assets:", trendingError);

                // Helper to find top asset (round) in a list
                // trendingData is already sorted by volume DESC, count DESC from RPC
                const getTopRoundForCategory = (categoryAssets: any[]) => {
                    if (!trendingData) return null;

                    // Find the first item in trendingData that matches a symbol in this category
                    const topRound = trendingData.find((t: any) =>
                        categoryAssets.some(ca => ca.symbol === t.symbol)
                    );

                    if (topRound) {
                        // Merge static asset data with dynamic round data
                        const staticAsset = categoryAssets.find(ca => ca.symbol === topRound.symbol);
                        return {
                            ...staticAsset,
                            predictionCount: topRound.prediction_count,
                            totalVolume: topRound.total_volume,
                            timeframe: topRound.timeframe // "1m", "5m", "15m", "1h", "4h", "1d"
                        };
                    }

                    // Fallback: Return the first asset in the category with default formatting if no trending data
                    return { ...categoryAssets[0], predictionCount: 0, totalVolume: 0, timeframe: '1h' };
                };

                // Select Top 1 Round for each category
                const topCrypto = getTopRoundForCategory(ASSETS.CRYPTO);
                const topStock = getTopRoundForCategory(ASSETS.STOCKS);
                const topCommodity = getTopRoundForCategory(ASSETS.COMMODITIES);

                setTrendingAssets([topCrypto, topStock, topCommodity].filter(Boolean));


                // 2. Fetch Top Leaders (via secure RPC)
                const { data: leadersData, error: leadersError } = await supabase
                    .rpc('get_top_leaders', { limit_count: 3 });

                if (leadersError) console.error("Error fetching leaders:", leadersError);
                if (leadersData) setTopLeaders(leadersData);

            } catch (error) {
                console.error("Failed to fetch trending section data:", error);
            } finally {
                setIsLoading(false);
            }
        }

        fetchData();
    }, []);

    return (
        <section className="space-y-6">
            <div className="flex items-center gap-3 text-3xl font-black italic tracking-tighter">
                <Flame className="text-orange-500 fill-orange-500 w-8 h-8" />
                <h2 className="uppercase">Trending</h2>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                {/* Left: Trending Assets (3 Columns wide on large screens) */}
                <div className="lg:col-span-3 grid grid-cols-1 md:grid-cols-3 gap-4">
                    {isLoading ? (
                        Array(3).fill(0).map((_, i) => (
                            <Card key={i} className="h-[200px] bg-white/5 border-white/5 animate-pulse rounded-2xl" />
                        ))
                    ) : (
                        trendingAssets.map((asset, i) => (
                            <MarketCard
                                key={asset.symbol}
                                asset={asset}
                                index={i}
                                isTrending={true}
                            />
                        ))
                    )}
                </div>

                {/* Right: Top Leaders (1 Column wide) - Compact Version */}
                <div className="lg:col-span-1">
                    <Card className="h-full bg-white/5 border-white/5 backdrop-blur-sm flex flex-col">
                        <CardHeader className="py-3 px-4 border-b border-white/5 shrink-0">
                            <div className="flex items-center justify-between">
                                <CardTitle className="text-xs font-black uppercase tracking-wider flex items-center gap-2">
                                    <Trophy className="w-3 h-3 text-yellow-500" />
                                    Top Leaders
                                </CardTitle>
                                <Link href="/leaderboard" className="text-[9px] text-primary hover:underline uppercase font-bold">
                                    View All
                                </Link>
                            </div>
                        </CardHeader>
                        <CardContent className="p-0 flex-1 overflow-hidden">
                            {isLoading ? (
                                <div className="p-3 space-y-3">
                                    {Array(3).fill(0).map((_, i) => (
                                        <div key={i} className="flex items-center gap-2 animate-pulse">
                                            <div className="w-6 h-6 rounded-full bg-white/10" />
                                            <div className="h-3 w-16 bg-white/10 rounded" />
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="divide-y divide-white/5 h-full flex flex-col justify-center">
                                    {topLeaders.length === 0 ? (
                                        <div className="flex flex-col items-center justify-center p-4 text-center h-full opacity-50">
                                            <Trophy className="w-6 h-6 mb-2 text-muted-foreground" />
                                            <p className="text-[10px]">No visible leaders yet</p>
                                        </div>
                                    ) : (
                                        topLeaders.map((leader, i) => (
                                            <div key={leader.id} className="flex items-center gap-2 p-3 hover:bg-white/5 transition-colors group">
                                                <div className="font-mono font-bold text-[10px] text-muted-foreground w-3 text-center">
                                                    {i + 1}
                                                </div>
                                                <Avatar className="w-6 h-6 border border-white/10">
                                                    <AvatarImage src={leader.avatar_url} />
                                                    <AvatarFallback className="text-[8px] bg-white/10">{leader.username?.substring(0, 2).toUpperCase()}</AvatarFallback>
                                                </Avatar>
                                                <div className="flex-1 min-w-0">
                                                    <div className="text-xs font-bold truncate group-hover:text-primary transition-colors">
                                                        {leader.username}
                                                    </div>
                                                    <div className="text-[9px] text-muted-foreground leading-none mt-0.5">
                                                        {leader.total_wins} Wins
                                                    </div>
                                                </div>
                                                <div className="text-[10px] font-mono font-bold text-yellow-500">
                                                    {leader.points.toLocaleString()}
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>
            </div>
        </section>
    );
}


