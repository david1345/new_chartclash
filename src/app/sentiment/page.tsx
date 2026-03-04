"use client";

import { useEffect, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import { ArrowUp, ArrowDown, BarChart3, ArrowLeft, Zap, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { cn } from "@/lib/utils";
import { createClient } from "@/lib/supabase/client";

// Dummy Data for Organic Empty State (Focused on BTC & Majors for now)
const DUMMY_SENTIMENT = [
    { asset_symbol: "BTCUSDT", total_votes: 12450, bull_percent: 68, bear_percent: 32, avg_target: 1.5 },
    { asset_symbol: "ETHUSDT", total_votes: 8900, bull_percent: 45, bear_percent: 55, avg_target: 2.1 },
    { asset_symbol: "SOLUSDT", total_votes: 21000, bull_percent: 82, bear_percent: 18, avg_target: 5.4 },
    { asset_symbol: "XRPUSDT", total_votes: 6500, bull_percent: 30, bear_percent: 70, avg_target: 0.8 },
];

export default function SentimentPage() {
    const [timeframe, setTimeframe] = useState("24"); // Default 24 Hours
    const [sentimentData, setSentimentData] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const supabase = createClient();

    useEffect(() => {
        const fetchSentiment = async (isInitial = false) => {
            if (isInitial) setIsLoading(true);
            try {
                const { data, error } = await supabase
                    .rpc('get_market_sentiment', { p_hours: parseInt(timeframe) });

                if (error) throw error;

                if (data && data.length > 0) {
                    setSentimentData(data);
                } else {
                    console.log("No data returned, using dummy sentiment data");
                    setSentimentData(DUMMY_SENTIMENT);
                }
            } catch (err) {
                console.error("Error fetching sentiment:", err);
                setSentimentData(DUMMY_SENTIMENT);
            } finally {
                if (isInitial) setIsLoading(false);
            }
        };

        fetchSentiment(true);

        // Realtime subscription (Optional: refresh on new prediction)
        const channel = supabase
            .channel('sentiment_feed')
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'predictions' }, () => {
                // Debounce refresh slightly to avoid flood during high activity
                const timer = setTimeout(() => fetchSentiment(false), 2000);
                return () => clearTimeout(timer);
            })
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        }
    }, [timeframe]);


    // Determine Trending Asset (Highest Volume or Highest Bullish/Bearish if volume is low)
    const trendingAsset = sentimentData.length > 0
        ? sentimentData.reduce((prev, current) => (prev.total_votes > current.total_votes) ? prev : current, sentimentData[0])
        : DUMMY_SENTIMENT[0];

    const isBullish = trendingAsset ? trendingAsset.bull_percent >= 50 : true;
    const trendColor = isBullish ? "text-emerald-400" : "text-red-400";
    const trendBg = isBullish ? "bg-emerald-500/10" : "bg-red-500/10";
    const trendBorder = isBullish ? "border-emerald-500/20" : "border-red-500/20";

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
                        <BarChart3 className="w-5 h-5 text-blue-500" /> Market Sentiment
                    </h1>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-8 pb-10">

                {/* Timeframe Tabs */}
                <div className="flex justify-center">
                    <Tabs defaultValue="24" onValueChange={setTimeframe} className="w-auto">
                        <TabsList className="bg-white/5 border border-white/5">
                            <TabsTrigger value="1">1h</TabsTrigger>
                            <TabsTrigger value="4">4h</TabsTrigger>
                            <TabsTrigger value="12">12h</TabsTrigger>
                            <TabsTrigger value="24">24h</TabsTrigger>
                        </TabsList>
                    </Tabs>
                </div>

                {isLoading ? (
                    <div className="flex justify-center py-20">
                        <Loader2 className="w-8 h-8 text-primary animate-spin" />
                    </div>
                ) : (
                    <>
                        {/* FEATURED: Live Trend Spotlight (Simulated) */}
                        <Card className="bg-gradient-to-br from-indigo-900/20 via-background to-background border-indigo-500/20 overflow-hidden relative">
                            <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2" />
                            <CardContent className="p-6 md:p-8 flex flex-col md:flex-row items-center gap-8 relative z-10">
                                <div className="flex-1 space-y-4 text-center md:text-left">
                                    <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full ${trendBg} ${trendBorder} ${trendColor} text-xs font-bold uppercase tracking-wider`}>
                                        <Zap className={`w-3 h-3 fill-current`} /> Trending Now
                                    </div>
                                    <h2 className="text-2xl md:text-3xl font-bold text-white">
                                        {trendingAsset.asset_symbol} Sentiment <span className={trendColor}>{isBullish ? "Surging" : "Plunging"}</span>
                                    </h2>
                                    <p className="text-muted-foreground max-w-lg">
                                        Over the last {timeframe} hours, {isBullish ? "bullish" : "bearish"} sentiment for {trendingAsset.asset_symbol} has dominated.
                                        Major volume incoming from {isBullish ? "optimistic" : "pessimistic"} traders.
                                    </p>
                                    <div className="flex flex-wrap justify-center md:justify-start gap-4 pt-2">
                                        <div className="px-4 py-2 rounded bg-white/5 border border-white/5">
                                            <div className="text-xs text-muted-foreground uppercase">Current Trend</div>
                                            <div className={`text-lg font-bold ${trendColor}`}>{isBullish ? "Extremely Bullish" : "Extremely Bearish"}</div>
                                        </div>
                                        <div className="px-4 py-2 rounded bg-white/5 border border-white/5">
                                            <div className="text-xs text-muted-foreground uppercase">{timeframe}h Volume</div>
                                            <div className="text-lg font-bold text-white">{trendingAsset.total_votes} Votes</div>
                                        </div>
                                    </div>
                                </div>
                                {/* Visual styling for "Trend" - kept abstract */}
                                <div className="w-full md:w-1/3 h-32 md:h-40 bg-white/5 rounded-lg border border-white/10 flex items-center justify-center relative overflow-hidden group">
                                    <div className={`absolute inset-0 bg-gradient-to-t ${isBullish ? "from-emerald-500/10" : "from-red-500/10"} to-transparent opacity-50`} />
                                    <svg viewBox="0 0 100 40" className={`w-full h-full ${isBullish ? "stroke-emerald-500 fill-emerald-500/20" : "stroke-red-500 fill-red-500/20"} stroke-2`} preserveAspectRatio="none">
                                        {isBullish ? (
                                            <path d="M0 35 Q 20 30, 40 25 T 100 5 V 40 H 0 Z" />
                                        ) : (
                                            <path d="M0 5 Q 20 10, 40 15 T 100 35 V 40 H 0 Z" />
                                        )}
                                    </svg>
                                    <div className={`absolute bottom-3 right-3 text-xs font-mono ${trendColor} bg-black/40 px-2 py-1 rounded backdrop-blur-sm`}>
                                        {isBullish ? `+${trendingAsset.bull_percent}% Bull` : `+${trendingAsset.bear_percent}% Bear`}
                                    </div>
                                </div>
                            </CardContent>
                        </Card>

                        {/* CTA: B2B API */}
                        <Card className="bg-[#141D2E] border border-[#00E5B4]/30 overflow-hidden relative">
                            <CardContent className="p-6 md:p-8 text-center flex flex-col items-center z-10 relative">
                                <h3 className="text-xl md:text-2xl font-black text-white mb-2 uppercase tracking-tight">Need Real-Time Betting Data?</h3>
                                <p className="text-[#8BA3BF] mb-6 max-w-xl mx-auto text-sm">
                                    Integrate ChartClash sentiment metrics directly into your trading algorithms or platform via our low-latency B2B API.
                                </p>
                                <Button className="bg-[#00E5B4] text-black hover:bg-[#00E5B4]/90 font-bold px-8 shadow-[0_0_15px_rgba(0,229,180,0.2)]">
                                    Request API Access
                                </Button>
                            </CardContent>
                        </Card>

                        {/* Section 1: Volatility Heatmap */}
                        <div>
                            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
                                <Zap className="w-4 h-4 text-muted-foreground" /> Market Pulse (Hot Assets)
                            </h2>
                            <Card className="bg-card/10 border-white/5">
                                <CardContent className="p-6">
                                    <div className="grid grid-cols-2 md:grid-cols-4 gap-2 h-[300px]">
                                        {sentimentData.slice(0, 6).map((asset, i) => (
                                            <HeatmapItem
                                                key={asset.asset_symbol}
                                                symbol={asset.asset_symbol}
                                                vol={asset.total_votes}
                                                color={asset.bull_percent > 55 ? "bg-[#00E5B4]/20 border border-[#00E5B4]/30" : asset.bear_percent > 55 ? "bg-[#FF4560]/20 border border-[#FF4560]/30" : "bg-[#F5A623]/20 border border-[#F5A623]/30"}
                                                size={i === 0 ? "col-span-2 row-span-2" : i === 1 ? "col-span-1 row-span-2" : "col-span-1 row-span-1"}
                                            />
                                        ))}
                                    </div>
                                </CardContent>
                            </Card>
                        </div>

                        {/* Section 2: Asset Sentiment Grid */}
                        <div>
                            <h2 className="text-lg font-bold mb-4 flex items-center gap-2">
                                <UsersIcon className="w-4 h-4 text-muted-foreground" /> Crowd Sentiment (All Assets)
                            </h2>
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                {sentimentData.map((asset) => (
                                    <Card key={asset.asset_symbol} className="bg-card/20 border-white/10 hover:bg-card/30 transition-colors">
                                        <CardContent className="p-5 space-y-4">
                                            <div className="flex items-center justify-between">
                                                <div className="flex items-center gap-2">
                                                    <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center font-bold text-xs ring-1 ring-white/10">
                                                        {asset.asset_symbol[0]}
                                                    </div>
                                                    <div>
                                                        <div className="font-bold">{asset.asset_symbol}</div>
                                                        <div className="text-xs text-muted-foreground">{asset.total_votes} Votes</div>
                                                    </div>
                                                </div>
                                                <Badge variant="outline" className="opacity-50 font-mono bg-white/5">
                                                    Target: ~{asset.avg_target}%
                                                </Badge>
                                            </div>

                                            {/* Bar */}
                                            <div className="space-y-1 mt-4">
                                                <div className="flex justify-between text-xs font-bold">
                                                    <span className="text-[#00E5B4]">{asset.bull_percent}% Bullish</span>
                                                    <span className="text-[#FF4560]">{asset.bear_percent}% Bearish</span>
                                                </div>
                                                <div className="h-2 w-full bg-white/5 rounded-full overflow-hidden flex">
                                                    <div className="h-full bg-[#00E5B4]" style={{ width: `${asset.bull_percent}%` }} />
                                                    <div className="h-full bg-[#FF4560]" style={{ width: `${asset.bear_percent}%` }} />
                                                </div>
                                            </div>

                                            <div className="pt-4 border-t border-white/5 flex justify-between items-center text-xs">
                                                <span className="text-[#5A7090]">Dominant View</span>
                                                <span className={cn("font-mono font-bold", asset.bull_percent >= 50 ? "text-[#00E5B4]" : "text-[#FF4560]")}>
                                                    {asset.bull_percent >= 50 ? "BULLISH" : "BEARISH"}
                                                </span>
                                            </div>
                                        </CardContent>
                                    </Card>
                                ))}
                            </div>
                        </div>
                    </>
                )}

            </div>
        </div>
    );
}

function HeatmapItem({ symbol, vol, color, size }: any) {
    return (
        <div className={cn("rounded-lg p-4 flex flex-col justify-between transition-transform hover:scale-[0.98] cursor-pointer", color, size)}>
            <span className="font-bold text-white/90 text-lg shadow-black/50 drop-shadow-md">{symbol}</span>
            <div className="text-right">
                <span className="text-xs text-white/70 font-bold uppercase">Activity</span>
                <div className="text-2xl font-mono font-bold text-white shadow-black/50 drop-shadow-md">{vol}</div>
            </div>
        </div>
    )
}

function UsersIcon(props: any) {
    return (
        <svg
            {...props}
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
    )
}
