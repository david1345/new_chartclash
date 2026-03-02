"use client";

import { useState, useEffect } from "react";
import { useSearchParams } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import {
    ArrowLeft, TrendingUp,
    Home, Target, BarChart2, MessageSquare, Megaphone,
    Clock, PlusCircle, Sparkles
} from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { createClient } from "@/lib/supabase/client";
import { InsightFeed } from "@/components/insight/InsightFeed";
import { InsightCardProps } from "@/components/insight/InsightCard";
import { AIAnalystHub } from "@/components/community/AIAnalystHub";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { toast } from "sonner";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";

import { Suspense } from "react";

function CommunityContent() {
    const searchParams = useSearchParams();
    const [insights, setInsights] = useState<InsightCardProps[]>([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState("insights");
    const [aiHubAsset, setAiHubAsset] = useState<string | null>(null);
    const [aiHubTimeframe, setAiHubTimeframe] = useState<string | null>(null);

    // Handle URL parameters
    useEffect(() => {
        const tab = searchParams.get('tab');
        const asset = searchParams.get('asset');
        const timeframe = searchParams.get('timeframe');

        if (tab === 'analyst-hub') {
            setActiveTab('ai-hub');
            if (asset) setAiHubAsset(asset);
            if (timeframe) setAiHubTimeframe(timeframe);
        }
    }, [searchParams]);

    // Filters
    const [filterAsset, setFilterAsset] = useState("ALL");
    const [filterTF, setFilterTF] = useState("ALL");
    const [filterRound, setFilterRound] = useState("ALL");
    const [rounds, setRounds] = useState<{ round_time: string; post_count: number }[]>([]);
    const [sortBy, setSortBy] = useState("FOR_YOU");

    // Form State
    const [isDialogOpen, setIsDialogOpen] = useState(false);
    const [alphaAsset, setAlphaAsset] = useState("BTCUSDT");
    const [alphaDirection, setAlphaDirection] = useState("UP");
    const [alphaTimeframe, setAlphaTimeframe] = useState("1d");
    const [alphaTarget, setAlphaTarget] = useState("1.0");
    const [alphaComment, setAlphaComment] = useState("");
    const [isSubmitting, setIsSubmitting] = useState(false);

    const supabase = createClient();

    const fetchRounds = async () => {
        if (filterAsset === "ALL" || filterTF === "ALL") {
            setRounds([]);
            setFilterRound("ALL");
            return;
        }

        const { data } = await supabase.rpc('get_analyst_rounds', {
            p_asset_symbol: filterAsset,
            p_timeframe: filterTF,
            p_channel: 'main'
        });

        if (data) {
            setRounds(data);
        } else {
            setRounds([]);
        }
    };

    const fetchInsights = async () => {
        setLoading(true);
        try {
            const rpcSortMap: Record<string, string> = {
                'FOR_YOU': 'TOP',
                'ACCURACY': 'TOP',
                'LATEST': 'LATEST',
                'FOLLOWED': 'TOP',
                'RISING': 'RISING'
            };

            const { data, error } = await supabase.rpc('get_ranked_insights_v2', {
                p_asset_symbol: filterAsset === "ALL" ? null : filterAsset,
                p_timeframe: filterTF === "ALL" ? null : filterTF,
                p_round_time: filterRound === "ALL" ? null : filterRound,
                p_sort_by: rpcSortMap[sortBy] || 'TOP',
                p_limit: 50,
                p_is_opinion: true,
                p_channel: 'main'
            });

            if (error) {
                console.error("Error fetching insights:", error);
                toast.error("Failed to load insights. Please try again.");
                return;
            }

            if (data) {
                const transformed: InsightCardProps[] = data.map((item: any) => ({
                    id: item.id,
                    username: item.username || 'Anon',
                    badge: item.tier === 'Unranked' ? 'Novice' : item.tier,
                    winRate: Number(item.user_win_rate),
                    asset: item.asset_symbol,
                    timeframe: item.timeframe,
                    reasoning: item.comment || "No logic provided.",
                    direction: item.direction,
                    targetPercent: Number(item.target_percent),
                    result: item.status,
                    likes: item.likes_count || 0,
                    comments: 0,
                    score: Number(item.insight_score),
                    createdAt: new Date(item.created_at).toLocaleDateString() + " " + new Date(item.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                    entryPrice: item.entry_price
                }));
                setInsights(transformed);
            }
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchRounds();
    }, [filterAsset, filterTF]);

    useEffect(() => {
        fetchInsights();

        // 30초 주기로 자동 새로고침 (게시판 활성화를 위해)
        const interval = setInterval(fetchInsights, 30000);
        return () => clearInterval(interval);
    }, [filterAsset, filterTF, filterRound, sortBy]);

    const handleSubmitAlpha = async () => {
        if (!alphaComment.trim()) {
            toast.error("Please enter your reasoning.");
            return;
        }

        setIsSubmitting(true);
        try {
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) {
                toast.error("Please login to post alpha.");
                return;
            }

            // Fetch Current Price using internal robust API
            let entryPriceValue = 0;
            let candleOpenT = Date.now();
            try {
                const priceRes = await fetch("/api/market/entry-price", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        symbol: alphaAsset,
                        timeframe: alphaTimeframe,
                        type: (alphaAsset === 'XAUUSD' || alphaAsset === 'NQ') ? 'COMMODITY' : 'CRYPTO'
                    })
                });
                const priceJson = await priceRes.json();
                if (priceJson.success && priceJson.data) {
                    entryPriceValue = priceJson.data.openPrice || priceJson.data.currentPrice || 0;
                    candleOpenT = priceJson.data.openTime || Date.now();
                }
            } catch (pErr) {
                console.error("Price fetch error via API:", pErr);
            }

            // Ensure we have a valid number
            const finalEntryPrice = Number(entryPriceValue) || 0;

            // Calculate duration based on selected timeframe
            let durationMs = 24 * 60 * 60 * 1000; // default 1d
            const tfVal = parseInt(alphaTimeframe);
            if (alphaTimeframe.endsWith('m')) durationMs = tfVal * 60 * 1000;
            else if (alphaTimeframe.endsWith('h')) durationMs = tfVal * 60 * 60 * 1000;
            else if (alphaTimeframe.endsWith('d')) durationMs = tfVal * 24 * 60 * 60 * 1000;

            const insertPayload = {
                user_id: user.id,
                asset_symbol: alphaAsset,
                direction: alphaDirection,
                target_percent: Number(alphaTarget) || 0,
                comment: alphaComment,
                bet_amount: 0,
                entry_price: finalEntryPrice,
                is_opinion: true,
                status: 'pending',
                timeframe: alphaTimeframe,
                candle_close_at: new Date(candleOpenT + durationMs).toISOString()
            };

            console.log("Submitting Alpha Payload:", insertPayload);

            const { error: insertError } = await supabase
                .from('predictions')
                .insert(insertPayload);

            if (insertError) {
                console.error("Alpha Submit DB Error:", insertError);
                // Be specific for debugging
                if (insertError.code === '23514') {
                    toast.error("DB Constraint violation. Please ensure bet amount and price are valid.");
                } else {
                    toast.error(`Submission failed: ${insertError.message}`);
                }
                throw insertError;
            }

            toast.success("Alpha posted successfully!");
            setAlphaComment("");
            setAlphaTarget("1.0");
            setIsDialogOpen(false);
            // Refresh feed
            fetchInsights();
        } catch (err: any) {
            console.error("Alpha final error:", err);
            // Error toast handled above or here if it's a code error
            if (!err.message?.includes('failed')) {
                toast.error("An unexpected error occurred during submission.");
            }
        } finally {
            setIsSubmitting(false);
        }
    };

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
                        <TrendingUp className="w-5 h-5 text-indigo-500" /> Insight Feed
                    </h1>
                    <div className="ml-auto flex items-center gap-3">
                        <Link href="/">
                            <Button variant="ghost" size="sm" className="gap-2 text-muted-foreground hover:text-white hidden sm:flex">
                                <Home className="w-4 h-4" />
                                <span>Home</span>
                            </Button>
                        </Link>

                        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                            <DialogTrigger asChild>
                                <Button className="bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-700 hover:to-violet-700 text-white shadow-lg shadow-indigo-500/20 font-bold text-xs font-mono tracking-tighter">
                                    <PlusCircle className="w-3.5 h-3.5 mr-2" /> CREATE ALPHA
                                </Button>
                            </DialogTrigger>
                            <DialogContent className="bg-[#0f1115] border-white/10 text-white sm:max-w-[450px]">
                                <DialogHeader>
                                    <DialogTitle>Share Market Alpha</DialogTitle>
                                </DialogHeader>
                                <div className="space-y-4 py-4">
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <Label className="text-xs text-muted-foreground">Asset</Label>
                                            <Select value={alphaAsset} onValueChange={setAlphaAsset}>
                                                <SelectTrigger className="bg-white/5 border-white/10 h-9">
                                                    <SelectValue />
                                                </SelectTrigger>
                                                <SelectContent className="bg-[#1a1d24] border-white/10 text-white">
                                                    {["BTCUSDT", "ETHUSDT", "SOLUSDT", "XAUUSD", "NQ"].map(a => (
                                                        <SelectItem key={a} value={a}>{a}</SelectItem>
                                                    ))}
                                                </SelectContent>
                                            </Select>
                                        </div>
                                        <div className="space-y-2">
                                            <Label className="text-xs text-muted-foreground">Timeframe</Label>
                                            <Select value={alphaTimeframe} onValueChange={setAlphaTimeframe}>
                                                <SelectTrigger className="bg-white/5 border-white/10 h-9">
                                                    <SelectValue />
                                                </SelectTrigger>
                                                <SelectContent className="bg-[#1a1d24] border-white/10 text-white">
                                                    {["15m", "1h", "4h", "1d"].map(tf => (
                                                        <SelectItem key={tf} value={tf}>{tf}</SelectItem>
                                                    ))}
                                                </SelectContent>
                                            </Select>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <Label className="text-xs text-muted-foreground">Direction</Label>
                                            <Select value={alphaDirection} onValueChange={setAlphaDirection}>
                                                <SelectTrigger className="bg-white/5 border-white/10 h-9">
                                                    <SelectValue />
                                                </SelectTrigger>
                                                <SelectContent className="bg-[#1a1d24] border-white/10 text-white">
                                                    <SelectItem value="UP">🚀 Bullish (UP)</SelectItem>
                                                    <SelectItem value="DOWN">🐻 Bearish (DOWN)</SelectItem>
                                                </SelectContent>
                                            </Select>
                                        </div>
                                        <div className="space-y-2">
                                            <Label className="text-xs text-muted-foreground">Target Move (%)</Label>
                                            <Input
                                                type="number"
                                                value={alphaTarget}
                                                onChange={(e) => setAlphaTarget(e.target.value)}
                                                className="bg-white/5 border-white/10 h-9"
                                                placeholder="e.g. 1.5"
                                            />
                                        </div>
                                    </div>

                                    <div className="space-y-2">
                                        <Label className="text-xs text-muted-foreground">Research & Logic</Label>
                                        <Textarea
                                            value={alphaComment}
                                            onChange={(e) => setAlphaComment(e.target.value)}
                                            placeholder="Explain your market view in detail... (Use Enter for new lines)"
                                            className="bg-white/5 border-white/10 min-h-[150px] resize-none focus:ring-indigo-500/50"
                                        />
                                    </div>

                                    <Button
                                        onClick={handleSubmitAlpha}
                                        disabled={isSubmitting}
                                        className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold"
                                    >
                                        {isSubmitting ? "POSTING..." : "POST ALPHA"}
                                    </Button>

                                    <p className="text-[10px] text-center text-muted-foreground">
                                        Alpha posts are visible to all users and ranked by quality.
                                    </p>
                                </div>
                            </DialogContent>
                        </Dialog>
                    </div>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-6 max-w-3xl">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-2xl font-bold bg-gradient-to-r from-white to-gray-400 bg-clip-text text-transparent">
                            Market Alpha
                        </h2>
                        <p className="text-muted-foreground text-sm mt-1">
                            Discover high-quality market predictions ranked by algorithm.
                        </p>
                    </div>
                </div>

                <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                    <TabsList className="bg-white/5 border border-white/5 w-full h-auto p-1 grid grid-cols-4 gap-1 mb-6">
                        <TabsTrigger value="insights" className="gap-2 data-[state=active]:bg-indigo-500/20 data-[state=active]:text-indigo-400">
                            <BarChart2 className="w-4 h-4" /> Insights
                        </TabsTrigger>
                        <TabsTrigger value="strategies" className="gap-2 data-[state=active]:bg-emerald-500/20 data-[state=active]:text-emerald-400">
                            <Target className="w-4 h-4" /> Strategies
                        </TabsTrigger>
                        <TabsTrigger value="rounds" className="gap-2 data-[state=active]:bg-orange-500/20 data-[state=active]:text-orange-400">
                            <MessageSquare className="w-4 h-4" /> Discussions
                        </TabsTrigger>
                        <TabsTrigger value="updates" className="gap-2 data-[state=active]:bg-yellow-500/20 data-[state=active]:text-yellow-400">
                            <Megaphone className="w-4 h-4" /> Updates
                        </TabsTrigger>
                        <TabsTrigger value="ai-hub" className="gap-2 data-[state=active]:bg-indigo-500/20 data-[state=active]:text-indigo-400">
                            <Sparkles className="w-4 h-4" /> Analyst Hub
                        </TabsTrigger>
                    </TabsList>

                    <TabsContent value="insights" className="space-y-6">
                        <div className="sticky top-16 z-40 bg-[#050505]/95 backdrop-blur-md border border-white/10 p-2 rounded-xl flex flex-wrap gap-2 items-center justify-between shadow-2xl shadow-black/50">
                            <div className="flex flex-wrap gap-2 items-center w-full md:w-auto">
                                <FilterSelect label="Asset" value={filterAsset} onChange={setFilterAsset} options={["ALL", "BTCUSDT", "ETHUSDT", "SOLUSDT", "XAUUSD", "NQ"]} />
                                <FilterSelect label="Timeframe" value={filterTF} onChange={setFilterTF} options={["ALL", "15m", "30m", "1h", "4h", "1d"]} />
                                {(filterAsset !== "ALL" && filterTF !== "ALL") && (
                                    <FilterSelect
                                        label="Round"
                                        value={filterRound}
                                        onChange={setFilterRound}
                                        options={["ALL", ...rounds.map(r => r.round_time)]}
                                        formatter={(val) => {
                                            if (val === "ALL") return "Latest";
                                            const d = new Date(val);
                                            return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')} ${d.toLocaleTimeString('ko-KR', { hour12: false })}`;
                                        }}
                                    />
                                )}
                            </div>
                            <div className="flex items-center gap-2 w-full md:w-auto mt-2 md:mt-0">
                                <span className="text-xs text-muted-foreground whitespace-nowrap ml-1">Sort:</span>
                                <Select value={sortBy} onValueChange={setSortBy}>
                                    <SelectTrigger className="h-8 w-[140px] bg-white/5 border-white/10 text-xs font-medium focus:ring-indigo-500/50">
                                        <SelectValue />
                                    </SelectTrigger>
                                    <SelectContent className="bg-[#1a1d24] border-white/10 text-white">
                                        <SelectItem value="FOR_YOU">✨ Recommended</SelectItem>
                                        <SelectItem value="RISING">🔥 Rising</SelectItem>
                                        <SelectItem value="LATEST">🆕 Latest</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>

                        <div className="min-h-[300px]">
                            {loading ? (
                                <div className="space-y-4 py-8">
                                    {[1, 2, 3].map(i => (
                                        <div key={i} className="h-40 bg-white/5 rounded-xl animate-pulse" />
                                    ))}
                                </div>
                            ) : (
                                <InsightFeed insights={insights} />
                            )}
                        </div>
                    </TabsContent>

                    <TabsContent value="strategies" className="text-center py-20 text-muted-foreground">Strategy Feed Coming Soon</TabsContent>
                    <TabsContent value="rounds" className="text-center py-20 text-muted-foreground">Round Discussions Coming Soon</TabsContent>
                    <TabsContent value="updates" className="text-center py-20 text-muted-foreground">Updates Coming Soon</TabsContent>
                    <TabsContent value="ai-hub" className="py-4">
                        <AIAnalystHub
                            initialAsset={aiHubAsset || undefined}
                            initialTimeframe={aiHubTimeframe || undefined}
                        />
                    </TabsContent>
                </Tabs>
            </div>
        </div>
    );
}

export default function CommunityPage() {
    return (
        <Suspense fallback={<div className="min-h-screen bg-[#050505] flex items-center justify-center text-muted-foreground">Loading Arena...</div>}>
            <CommunityContent />
        </Suspense>
    );
}

function FilterSelect({ label, value, onChange, options, formatter }: { label: string, value: string, onChange: (v: string) => void, options: string[], formatter?: (v: string) => string }) {
    return (
        <Select value={value} onValueChange={onChange}>
            <SelectTrigger className={cn("h-8 bg-transparent border-transparent hover:bg-white/5 text-xs font-medium gap-1 px-2 focus:ring-0", value !== "ALL" && "text-indigo-400 bg-indigo-500/10 border-indigo-500/20")}>
                <span className="text-muted-foreground hidden sm:inline">{label}:</span>
                <span className={cn(value !== "ALL" ? "text-indigo-400" : "text-white")}>
                    {formatter ? formatter(value) : value}
                </span>
            </SelectTrigger>
            <SelectContent className="bg-[#1a1d24] border-white/10 text-white min-w-[120px]">
                {options.map(opt => (
                    <SelectItem key={opt} value={opt} className="text-xs focus:bg-white/10 focus:text-white cursor-pointer">
                        {formatter ? formatter(opt) : opt}
                    </SelectItem>
                ))}
            </SelectContent>
        </Select>
    )
}
