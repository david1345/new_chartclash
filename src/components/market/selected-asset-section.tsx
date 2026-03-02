"use client";

import { useEffect, useState } from "react";
import { Zap, Loader2, X } from "lucide-react";
import { LiveRoundCard } from "./live-round-card";
import { Asset } from "@/lib/constants";

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

interface SelectedAssetSectionProps {
    asset: Asset;
    onClear: () => void;
}

export function SelectedAssetSection({ asset, onClear }: SelectedAssetSectionProps) {
    const [rounds, setRounds] = useState<LiveRound[]>([]);
    const [loading, setLoading] = useState(true);
    const timeframes = ['15m', '30m', '1h', '4h', '1d'];

    useEffect(() => {
        fetchRounds();
    }, [asset]);

    const fetchRounds = async () => {
        setLoading(true);
        try {
            // Fetch all live rounds for all categories
            const categories = ['CRYPTO', 'STOCKS', 'COMMODITIES'];
            let allRounds: LiveRound[] = [];

            for (const category of categories) {
                const res = await fetch(`/api/market/live-rounds?category=${category}&limit=50`);
                const data = await res.json();
                if (data.success) {
                    allRounds = [...allRounds, ...data.data];
                }
            }

            const assetRounds = allRounds.filter((r: LiveRound) => r.asset_symbol === asset.symbol);
            console.log('Asset rounds found:', assetRounds);

            // Map to ensure we have cards for all requested timeframes, even if 0 stats
            const results = timeframes.map(tf => {
                const existing = assetRounds.find((r: LiveRound) => r.timeframe === tf);
                if (existing) return existing;
                return {
                    asset_symbol: asset.symbol,
                    timeframe: tf,
                    asset_name: asset.name,
                    asset_type: asset.type,
                    participant_count: 0,
                    total_volume: 0
                };
            });

            console.log('Final results:', results);
            setRounds(results);
        } catch (error) {
            console.error('Failed to fetch rounds for asset:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <section className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
            {/* Title */}
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-3xl font-black italic tracking-tighter">
                    <Zap className="text-primary fill-primary w-8 h-8" />
                    <h2 className="uppercase">
                        Analysis: <span className="text-primary">{asset.name}</span>
                    </h2>
                    <span className="text-sm text-muted-foreground font-normal italic uppercase tracking-widest ml-2">
                        {asset.symbol}
                    </span>
                </div>
                <button
                    onClick={onClear}
                    className="flex items-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 rounded-xl transition-all border border-white/5 text-xs font-bold uppercase tracking-widest text-muted-foreground hover:text-white"
                >
                    <X className="w-4 h-4" />
                    Clear Selection
                </button>
            </div>

            {/* Loading / Grid */}
            {loading ? (
                <div className="flex items-center justify-center py-20">
                    <Loader2 className="w-8 h-8 animate-spin text-primary" />
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-6">
                    {rounds.map((round, index) => (
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
