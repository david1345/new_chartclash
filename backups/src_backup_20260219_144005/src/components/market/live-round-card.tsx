"use client";

import { useEffect, useState, useMemo } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Users, TrendingUp, TrendingDown, Sparkles } from "lucide-react";

interface LiveRoundCardProps {
    assetSymbol: string;
    timeframe: string;
    assetName: string;
    assetType: string;
    participantCount: number;
    totalVolume: number;
    aiDirection?: string;
    aiConfidence?: number;
    index?: number;
}

export function LiveRoundCard({
    assetSymbol,
    timeframe,
    assetName,
    assetType,
    participantCount,
    totalVolume,
    aiDirection,
    aiConfidence,
    index = 0
}: LiveRoundCardProps) {
    const [candleData, setCandleData] = useState<number[]>([]);
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    // Fetch mini chart data
    useEffect(() => {
        if (assetType !== 'CRYPTO') return;

        const fetchCandles = async () => {
            try {
                const interval = timeframe;
                const symbol = assetSymbol.replace('/', '');
                const res = await fetch(`https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=${interval}&limit=24`);
                const data = await res.json();

                if (Array.isArray(data)) {
                    const closes = data.map((d: any) => parseFloat(d[4]));
                    setCandleData(closes);
                }
            } catch (e) {
                console.error("Failed to fetch candles", e);
            }
        };

        fetchCandles();
    }, [assetSymbol, timeframe, assetType]);

    // Generate SVG Path
    const chartPath = useMemo(() => {
        if (candleData.length === 0) {
            if (!mounted) return `M0 30 Q 25 30, 50 30 T 100 30`;
            return `M0 30 Q 25 ${Math.random() * 60}, 50 30 T 100 30`;
        }

        const min = Math.min(...candleData);
        const max = Math.max(...candleData);
        const range = max - min;

        const points = candleData.map((price, i) => {
            const x = (i / (candleData.length - 1)) * 100;
            const y = 60 - ((price - min) / range) * 60;
            return `${x},${y}`;
        });

        return `M ${points.join(' L ')}`;
    }, [candleData, mounted]);

    const isUp = candleData.length > 0 ? candleData[candleData.length - 1] > candleData[0] : true;

    // Category color
    const categoryColor = assetType === 'CRYPTO' ? 'text-blue-500' : assetType === 'STOCKS' ? 'text-green-500' : 'text-yellow-500';
    const categoryBg = assetType === 'CRYPTO' ? 'bg-blue-500/10' : assetType === 'STOCKS' ? 'bg-green-500/10' : 'bg-yellow-500/10';

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: index * 0.05 }}
            whileHover={{ y: -8, scale: 1.02 }}
            className="h-full"
        >
            <Link href={`/play/${assetSymbol}/${timeframe}`}>
                <Card className="group relative overflow-hidden transition-all duration-500 h-full flex flex-col justify-between p-4 border-white/5 bg-white/5 hover:bg-white/[0.08] hover:border-white/20 cursor-pointer">
                    {/* Header */}
                    <div className="flex justify-between items-start mb-3">
                        <div className="flex-1">
                            <h3 className="text-base font-black group-hover:text-primary transition-colors leading-tight uppercase tracking-tighter">
                                {assetName}
                            </h3>
                            <div className="flex items-center gap-2 mt-1">
                                <Badge variant="outline" className={`text-[9px] h-4 px-1.5 py-0 border-white/10 font-mono uppercase ${categoryColor} ${categoryBg}`}>
                                    {timeframe.toUpperCase()}
                                </Badge>
                                <Badge variant="outline" className="text-[9px] h-4 px-1.5 py-0 border-white/10 text-muted-foreground font-mono uppercase">
                                    {assetType}
                                </Badge>
                            </div>
                        </div>

                        {/* AI Prediction Button */}
                        {aiDirection && (
                            <Link
                                href={`/community?tab=analyst-hub&asset=${assetSymbol}&timeframe=${timeframe}`}
                                onClick={(e) => e.stopPropagation()}
                                className="flex items-center gap-1 px-2 py-1 rounded-full bg-purple-500/10 border border-purple-500/20 hover:bg-purple-500/20 hover:border-purple-500/40 transition-all group/ai"
                            >
                                <Sparkles className="w-3 h-3 text-purple-400 group-hover/ai:animate-pulse" />
                                <span className="text-[10px] font-bold text-purple-400 uppercase">
                                    AI {aiDirection} {aiConfidence}%
                                </span>
                            </Link>
                        )}
                    </div>

                    {/* Mini Chart */}
                    <div className="h-16 w-full bg-black/20 rounded-lg overflow-hidden relative border border-white/5 mb-3">
                        <motion.svg
                            initial={{ opacity: 0, pathLength: 0 }}
                            animate={{ opacity: 1, pathLength: 1 }}
                            transition={{ duration: 1.5, ease: "easeOut" }}
                            className="absolute inset-0 w-full h-full p-2"
                            preserveAspectRatio="none"
                            viewBox="0 0 100 60"
                        >
                            <motion.path
                                d={chartPath}
                                stroke={isUp ? '#22c55e' : '#ef4444'}
                                fill="none"
                                strokeWidth="2"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                            />
                        </motion.svg>
                        <div className={`absolute inset-0 bg-gradient-to-t ${isUp ? 'from-green-500/10' : 'from-red-500/10'} to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500`} />
                    </div>

                    {/* Footer Stats */}
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 px-2 py-1 bg-white/5 rounded-full border border-white/5">
                            <Users className="w-3 h-3 text-blue-500" />
                            <span className="text-[10px] font-bold text-muted-foreground">{participantCount}</span>
                        </div>

                        <div className="flex items-center gap-1.5 px-2 py-1 bg-white/5 rounded-full border border-white/5">
                            <span className="text-[10px] text-muted-foreground font-bold">Vol.</span>
                            <span className="text-orange-500 font-bold text-[10px]">{totalVolume.toLocaleString()} pts</span>
                        </div>
                    </div>

                    {/* Hover Glow */}
                    <div className="absolute inset-0 border-[1px] border-white/0 group-hover:border-white/10 rounded-[inherit] transition-all duration-700 pointer-events-none" />
                    <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-primary/5 blur-[80px] group-hover:bg-primary/20 transition-all duration-700 pointer-events-none" />
                </Card>
            </Link>
        </motion.div>
    );
}
