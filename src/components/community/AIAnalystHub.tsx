"use client";

import { InsightFeed } from "@/components/insight/InsightFeed";
import { InsightCardProps } from "@/components/insight/InsightCard";
import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { Bot, Sparkles, Search, Calendar, Clock } from "lucide-react";
import { ASSETS, TIMEFRAMES } from "@/lib/constants";
import { useMounted } from "@/hooks/use-mounted";

interface AIAnalystHubProps {
    initialAsset?: string;
    initialTimeframe?: string;
}

export function AIAnalystHub({ initialAsset, initialTimeframe }: AIAnalystHubProps = {}) {
    const [insights, setInsights] = useState<InsightCardProps[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedAsset, setSelectedAsset] = useState(initialAsset || "BTCUSDT");
    const [selectedTimeframe, setSelectedTimeframe] = useState(initialTimeframe || "15m");
    const mounted = useMounted();
    const [rounds, setRounds] = useState<{ round_time: string; post_count: number }[]>([]);
    const [selectedRound, setSelectedRound] = useState<string>("");

    const supabase = createClient();

    // 1. Fetch available analysis rounds for the selected asset/timeframe
    const fetchRounds = useCallback(async () => {
        const { data, error } = await supabase.rpc('get_analyst_rounds', {
            p_asset_symbol: selectedAsset,
            p_timeframe: selectedTimeframe,
            p_channel: 'analyst_hub'
        });

        if (data && data.length > 0) {
            setRounds(data);
            setSelectedRound(data[0].round_time); // Default to latest round
        } else {
            setRounds([]);
            setSelectedRound("");
            setInsights([]);
        }
    }, [selectedAsset, selectedTimeframe, supabase]);

    // 2. Fetch specific insights for the selected round (direct query - bypasses RPC)
    const fetchInsights = useCallback(async (assetSymbol: string | null, timeframe: string | null, roundTime: string | null) => {
        if (!roundTime) return;
        setLoading(true);
        try {
            // Use direct table query instead of broken RPC
            // date_trunc matching: filter within a 1-minute window to handle precision differences
            const roundTimeMs = new Date(roundTime).getTime();
            const from = new Date(roundTimeMs - 30000).toISOString(); // -30s
            const to = new Date(roundTimeMs + 30000).toISOString();   // +30s

            const { data, error } = await supabase
                .from('predictions')
                .select(`
                    id, user_id, asset_symbol, timeframe, direction,
                    target_percent, entry_price, status, profit,
                    created_at, resolved_at, comment, likes_count,
                    is_opinion, round_time,
                    profiles!inner(username, tier, total_games, total_wins)
                `)
                .eq('asset_symbol', assetSymbol!)
                .eq('timeframe', timeframe!)
                .eq('channel', 'analyst_hub')
                .eq('is_opinion', true)
                .gte('round_time', from)
                .lte('round_time', to)
                .not('comment', 'is', null)
                .order('created_at', { ascending: false })
                .limit(20);

            if (error) throw error;

            if (data) {
                const transformed: InsightCardProps[] = data.map((item: any) => ({
                    id: item.id,
                    username: item.profiles?.username,
                    badge: "🤖 SYSTEM",
                    winRate: item.profiles?.total_games > 0
                        ? Math.round((item.profiles.total_wins / item.profiles.total_games) * 100)
                        : 0,
                    asset: item.asset_symbol,
                    timeframe: item.timeframe,
                    reasoning: item.comment,
                    direction: item.direction,
                    targetPercent: Number(item.target_percent),
                    result: item.status,
                    likes: item.likes_count || 0,
                    comments: 0,
                    score: 0,
                    createdAt: mounted ? new Date(item.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "--:--",
                    entryPrice: item.entry_price,
                    isBot: true
                }));
                setInsights(transformed);
            }
        } catch (error) {
            console.error("AI HUB: Analysis round fetch error:", error);
        } finally {
            setLoading(false);
        }
    }, [selectedAsset, selectedTimeframe, supabase]);

    useEffect(() => {
        if (!mounted) return;
        fetchRounds();
    }, [mounted, fetchRounds]);

    useEffect(() => {
        if (selectedRound) {
            fetchInsights(selectedAsset, selectedTimeframe, selectedRound);
        }
    }, [selectedAsset, selectedTimeframe, selectedRound, fetchInsights]);

    const formatRoundLabel = (isoDate: string) => {
        if (!mounted) return "Loading Round...";
        const d = new Date(isoDate);
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        const time = d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true });
        return `${year}.${month}.${day} ${time}`;
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="bg-indigo-500/10 border border-indigo-500/20 rounded-2xl p-6 flex items-start gap-4">
                <div className="bg-indigo-500/20 p-3 rounded-xl border border-indigo-500/30">
                    <Bot className="w-6 h-6 text-indigo-400" />
                </div>
                <div>
                    <h3 className="text-lg font-bold text-white flex items-center gap-2">
                        AI Analyst Hub <Sparkles className="w-4 h-4 text-yellow-500" />
                    </h3>
                    <p className="text-sm text-indigo-300/70 mt-1">
                        Select a round to view synchronized insights from all 10 specialized analysts.
                    </p>
                </div>
            </div>

            {/* Filters */}
            <div className="flex flex-wrap gap-3 p-4 bg-white/5 rounded-2xl border border-white/10">
                {/* Asset Select */}
                <div className="flex items-center gap-2 bg-white/5 px-3 py-2 rounded-xl border border-white/10">
                    <Search className="w-4 h-4 text-gray-400" />
                    <select
                        className="bg-transparent text-sm text-white outline-none focus:ring-0"
                        value={selectedAsset}
                        onChange={(e) => setSelectedAsset(e.target.value)}
                    >
                        {Object.values(ASSETS).flat().map(a => (
                            <option key={a.symbol} value={a.symbol} className="bg-gray-900">{a.symbol}</option>
                        ))}
                    </select>
                </div>

                {/* Timeframe Select */}
                <div className="flex items-center gap-2 bg-white/5 px-3 py-2 rounded-xl border border-white/10">
                    <Clock className="w-4 h-4 text-gray-400" />
                    <select
                        className="bg-transparent text-sm text-white outline-none focus:ring-0"
                        value={selectedTimeframe}
                        onChange={(e) => setSelectedTimeframe(e.target.value)}
                    >
                        {TIMEFRAMES.filter(tf => tf !== '1m' && tf !== '5m').map(tf => (
                            <option key={tf} value={tf} className="bg-gray-900">{tf}</option>
                        ))}
                    </select>
                </div>

                {/* Round Select */}
                <div className="flex items-center gap-2 bg-indigo-500/10 px-3 py-2 rounded-xl border border-indigo-500/30">
                    <Calendar className="w-4 h-4 text-indigo-400" />
                    <select
                        className="bg-transparent text-sm text-indigo-100 outline-none focus:ring-0 min-w-[180px]"
                        value={selectedRound}
                        onChange={(e) => setSelectedRound(e.target.value)}
                        disabled={rounds.length === 0}
                    >
                        {rounds.length > 0 ? (
                            rounds.map(r => (
                                <option key={r.round_time} value={r.round_time} className="bg-gray-900">
                                    {formatRoundLabel(r.round_time)} ({r.post_count})
                                </option>
                            ))
                        ) : (
                            <option className="bg-gray-900">No rounds found</option>
                        )}
                    </select>
                </div>
            </div>

            {/* Insight List */}
            <div className="min-h-[400px]">
                {loading ? (
                    <div className="space-y-4">
                        {[1, 2, 3].map(i => (
                            <div key={i} className="h-32 bg-white/5 rounded-xl animate-pulse" />
                        ))}
                    </div>
                ) : insights.length > 0 ? (
                    <InsightFeed insights={insights} />
                ) : (
                    <div className="flex flex-col items-center justify-center py-20 text-gray-500">
                        <Bot className="w-12 h-12 mb-4 opacity-20" />
                        <p>No analyst insights found for this round.</p>
                    </div>
                )}
            </div>
        </div>
    );
}
