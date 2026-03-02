"use client";

import { useEffect, useState } from "react";
import { Flame, Trophy } from "lucide-react";
import { LiveRoundCard } from "./live-round-card";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { createClient } from "@/lib/supabase/client";
import Link from "next/link";

interface TrendingAsset {
    asset_symbol: string;
    timeframe: string;
    asset_name: string;
    asset_type: string;
    participant_count: number;
    total_volume: number;
    ai_direction?: string;
    ai_confidence?: number;
}

interface TrendingMarketSectionProps {
    searchQuery?: string;
    selectedCategory?: string;
}

export function TrendingMarketSection({ searchQuery = "", selectedCategory = "CRYPTO" }: TrendingMarketSectionProps) {
    const [trendingAssets, setTrendingAssets] = useState<TrendingAsset[]>([]);
    const [topLeaders, setTopLeaders] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const supabase = createClient();

    useEffect(() => {
        fetchData();
    }, [selectedCategory]);

    useEffect(() => {
        if (trendingAssets.length > 0) {
            filterAssets();
        }
    }, [searchQuery]);

    const fetchData = async () => {
        try {
            // Fetch trending assets for selected category
            const res = await fetch(`/api/market/trending?category=${selectedCategory}`);
            const data = await res.json();

            // Fetch top leaders
            const { data: leadersData, error: leadersError } = await supabase
                .rpc('get_top_leaders', { limit_count: 3 });

            if (data.success) {
                setTrendingAssets(data.data);
            }

            if (leadersData && !leadersError) {
                setTopLeaders(leadersData);
            }
        } catch (error) {
            console.error('Failed to fetch trending:', error);
        } finally {
            setLoading(false);
        }
    };

    const filterAssets = () => {
        fetchData().then(() => {
            if (searchQuery.trim()) {
                const query = searchQuery.toLowerCase();
                setTrendingAssets(prev => prev.filter((asset: TrendingAsset) =>
                    asset.asset_symbol.toLowerCase().includes(query) ||
                    asset.asset_name.toLowerCase().includes(query)
                ));
            }
        });
    };

    if (loading) {
        return (
            <section className="space-y-6">
                <div className="flex items-center gap-3 text-3xl font-black italic tracking-tighter">
                    <Flame className="text-red-500 fill-red-500 w-8 h-8 animate-pulse" />
                    <h2 className="uppercase">Trending Now</h2>
                </div>
                <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                    <div className="lg:col-span-3 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[1, 2, 3].map((i) => (
                            <div key={i} className="h-64 bg-white/5 rounded-2xl animate-pulse" />
                        ))}
                    </div>
                    <div className="lg:col-span-1 h-64 bg-white/5 rounded-2xl animate-pulse" />
                </div>
            </section>
        );
    }

    return (
        <section className="space-y-6">
            <div className="flex items-center gap-3 text-3xl font-black italic tracking-tighter">
                <Flame className="text-red-500 fill-red-500 w-8 h-8" />
                <h2 className="uppercase">Trending Now</h2>
                <span className="text-sm text-muted-foreground font-normal italic">Top by Volume & Activity</span>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                {/* Left: Trending Assets (3 columns) */}
                <div className="lg:col-span-3 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                    {trendingAssets.length === 0 ? (
                        <div className="col-span-full text-center py-20 bg-white/5 rounded-[3rem] border border-white/5 border-dashed">
                            <p className="text-muted-foreground text-lg italic">No active rounds yet. Be the first!</p>
                        </div>
                    ) : (
                        trendingAssets.slice(0, 3).map((asset, index) => (
                            <LiveRoundCard
                                key={`${asset.asset_symbol}-${asset.timeframe}`}
                                assetSymbol={asset.asset_symbol}
                                timeframe={asset.timeframe}
                                assetName={asset.asset_name}
                                assetType={asset.asset_type}
                                participantCount={Number(asset.participant_count)}
                                totalVolume={Number(asset.total_volume)}
                                aiDirection={asset.ai_direction || undefined}
                                aiConfidence={asset.ai_confidence ? Number(asset.ai_confidence) : undefined}
                                index={index}
                            />
                        ))
                    )}
                </div>

                {/* Right: Top Leaders (1 column) */}
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
                            {loading ? (
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
