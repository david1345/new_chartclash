"use client";

import { useEffect, useState } from "react";
import { Zap, Loader2 } from "lucide-react";
import { LiveRoundCard } from "./live-round-card";

interface LiveRound {
    asset_symbol: string;
    timeframe: string;
    asset_name: string;
    asset_type: string;
    participant_count: number;
    total_volume: number;
    ai_direction?: string;
    ai_confidence?: number;
}

interface MarketDiscoverySectionProps {
    searchQuery?: string;
    selectedCategory?: string;
}

export function MarketDiscoverySection({ searchQuery = "", selectedCategory = "CRYPTO" }: MarketDiscoverySectionProps) {
    const [liveRounds, setLiveRounds] = useState<LiveRound[]>([]);
    const [filteredRounds, setFilteredRounds] = useState<LiveRound[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchLiveRounds();
    }, [selectedCategory]);

    useEffect(() => {
        filterRounds();
    }, [liveRounds, searchQuery, selectedCategory]);

    const fetchLiveRounds = async () => {
        setLoading(true);
        try {
            const res = await fetch(`/api/market/live-rounds?category=${selectedCategory}&limit=50`);
            const data = await res.json();
            if (data.success) {
                setLiveRounds(data.data);
                setFilteredRounds(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch live rounds:', error);
        } finally {
            setLoading(false);
        }
    };

    const filterRounds = () => {
        let filtered = liveRounds;

        // Filter by search query
        if (searchQuery.trim()) {
            const query = searchQuery.toLowerCase();
            filtered = filtered.filter(
                round =>
                    round.asset_symbol.toLowerCase().includes(query) ||
                    round.asset_name.toLowerCase().includes(query)
            );
        }

        setFilteredRounds(filtered);
    };

    return (
        <section className="space-y-8">
            {/* Title */}
            <div className="flex items-center gap-3 text-3xl font-black italic tracking-tighter">
                <Zap className="text-yellow-400 fill-yellow-400 w-8 h-8" />
                <h2 className="uppercase">Market Discovery</h2>
                <span className="text-sm text-muted-foreground font-normal italic">
                    {filteredRounds.length} Live Rounds
                </span>
            </div>

            {/* Loading State */}
            {loading ? (
                <div className="flex items-center justify-center py-20">
                    <Loader2 className="w-8 h-8 animate-spin text-primary" />
                </div>
            ) : filteredRounds.length === 0 ? (
                <div className="text-center py-20 bg-white/5 rounded-[3rem] border border-white/5 border-dashed">
                    <p className="text-muted-foreground text-lg italic">
                        {searchQuery ? `No results for "${searchQuery}"` : 'No active rounds'}
                    </p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                    {filteredRounds.map((round, index) => (
                        <LiveRoundCard
                            key={`${round.asset_symbol}-${round.timeframe}`}
                            assetSymbol={round.asset_symbol}
                            timeframe={round.timeframe}
                            assetName={round.asset_name}
                            assetType={round.asset_type}
                            participantCount={Number(round.participant_count)}
                            totalVolume={Number(round.total_volume)}
                            aiDirection={round.ai_direction || undefined}
                            aiConfidence={round.ai_confidence ? Number(round.ai_confidence) : undefined}
                            index={index}
                        />
                    ))}
                </div>
            )}
        </section>
    );
}
