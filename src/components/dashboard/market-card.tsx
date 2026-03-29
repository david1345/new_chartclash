"use client";

import { useEffect, useState, useMemo } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Asset } from "@/lib/constants";
import {
    Coins, Zap, TrendingUp, Trophy, LineChart,
    ArrowRight, Clock, Users, Flame, BarChart3
} from "lucide-react";

interface MarketCardProps {
    asset: Asset & { predictionCount?: number, totalVolume?: number, timeframe?: string };
    featured?: boolean;
    isTrending?: boolean; // New prop for Trending section specific styling/data
    index?: number; // Used for "Hot" badge in Trending section
}

export function MarketCard({ asset, featured = false, isTrending = false, index }: MarketCardProps) {
    // State for real-time data
    const [candleData, setCandleData] = useState<number[]>([]);
    const [liveChange, setLiveChange] = useState<string>("0.00");
    const [isLiveUp, setIsLiveUp] = useState(true);
    const [mounted, setMounted] = useState(false);

    // Determines the display time (e.g. 1H, 15M) - defaults to 1H if not provided
    const displayTimeframe = asset.timeframe ? asset.timeframe.toUpperCase() : '1H';

    useEffect(() => {
        setMounted(true);
    }, []);

    // Fetch Candle Data (Crypto)
    useEffect(() => {
        if (asset.type !== 'CRYPTO') return;

        const fetchCandles = async () => {
            try {
                const interval = asset.timeframe || '1h';
                const symbol = asset.symbol.replace('/', '');
                const res = await fetch(`https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=${interval}&limit=24`);
                const data = await res.json();

                if (Array.isArray(data)) {
                    const closes = data.map((d: any) => parseFloat(d[4]));
                    setCandleData(closes);

                    const currentOpen = parseFloat(data[data.length - 1][1]);
                    const currentClose = parseFloat(data[data.length - 1][4]);
                    const changePercent = ((currentClose - currentOpen) / currentOpen) * 100;

                    setLiveChange(changePercent.toFixed(2));
                    setIsLiveUp(changePercent >= 0);
                }
            } catch (e) {
                console.error("Failed to fetch candles", e);
            }
        };

        fetchCandles();
    }, [asset.symbol, asset.timeframe, asset.type]);


    // Placeholder for non-trending or failed fetch
    const mockVol = useMemo(() => {
        if (!mounted) return "50.0";
        return (Math.random() * 100 + 5).toFixed(1);
    }, [mounted]);

    const mockChange = useMemo(() => {
        if (!mounted) return "0.00";
        return (Math.random() * 5 - 2).toFixed(2);
    }, [mounted]);

    const isMockUp = parseFloat(mockChange) >= 0;

    // Use live data if available, else mock
    const change = candleData.length > 0 ? liveChange : mockChange;
    const isUp = candleData.length > 0 ? isLiveUp : isMockUp;

    // Generate SVG Path
    const chartPath = useMemo(() => {
        if (candleData.length === 0) {
            // Fixed fallback to prevent hydration mismatch
            if (!mounted) {
                return `M0 30 Q 25 30, 50 30 T 100 30`;
            }
            // Random fallback only after mount
            return `M0 30 Q 25 ${Math.random() * 60}, 50 30 T 100 30`;
        }

        const min = Math.min(...candleData);
        const max = Math.max(...candleData);
        const range = max - min;

        // Normalize to 0-100 width, 0-60 height (SVG viewbox is usually small)
        const points = candleData.map((price, i) => {
            const x = (i / (candleData.length - 1)) * 100;
            const y = 60 - ((price - min) / range) * 60; // Invert Y
            return `${x},${y}`;
        });

        // Catmull-Rom or simple line? Simple polyline for sparkline is robust
        return `M ${points.join(' L ')}`;

    }, [candleData, mounted]);


    // Asset Logo Helper
    const getAssetLogo = (symbol: string) => {
        if (symbol.includes('BTC')) return { icon: <Coins className="text-yellow-500" />, label: "BTC" };
        if (symbol.includes('ETH')) return { icon: <Zap className="text-purple-400" />, label: "ETH" };
        if (symbol.includes('SOL')) return { icon: <Zap className="text-emerald-400" />, label: "SOL" };
        if (symbol === 'AAPL') return { icon: <TrendingUp className="text-slate-400" />, label: "" };
        if (symbol.includes('XAU')) return { icon: <Trophy className="text-yellow-600" />, label: "AU" };
        return { icon: <LineChart className="text-blue-400" />, label: symbol.slice(0, 2) };
    };

    const logo = getAssetLogo(asset.symbol);

    // Mock participant count (consistent across renders)
    const mockParticipants = useMemo(() => {
        if (!mounted) return 100;
        return Math.floor(Math.random() * 200) + 42;
    }, [mounted]);

    return (
        <motion.div whileHover={{ y: -8 }} className="h-full">
            <Link href={`/play/${asset.symbol}/${asset.timeframe || '1h'}`}>
                <Card className={`group relative overflow-hidden transition-all duration-500 h-full flex flex-col justify-between ${featured
                    ? 'p-8 min-h-[280px] border-primary/20 bg-gradient-to-br from-primary/10 to-transparent hover:border-primary/50 shadow-2xl'
                    : 'p-6 border-white/5 bg-white/5 hover:bg-white/[0.08] hover:border-white/20'
                    }`}>

                    {/* Header: Logo, Name, Badge */}
                    <div className="flex justify-between items-start mb-6">
                        <div className="flex items-center gap-4">
                            <div className={`rounded-3xl flex items-center justify-center font-black transition-all ${featured
                                ? 'w-20 h-20 text-2xl bg-white/5 text-primary border border-white/5'
                                : 'w-12 h-12 text-sm bg-white/5 text-muted-foreground group-hover:bg-primary/20 group-hover:text-primary'
                                }`}>
                                {logo.icon}
                            </div>
                            <div>
                                <h3 className={`${featured ? 'text-2xl' : 'text-lg'} font-black group-hover:text-primary transition-colors leading-tight italic uppercase tracking-tighter`}>
                                    {asset.name}
                                </h3>
                                {/* Timeframe Badge in Header */}
                                <div className="flex items-center gap-2 mt-1">
                                    <span className="text-xs text-muted-foreground font-mono opacity-60 tracking-widest">{asset.symbol}</span>
                                    {isTrending && (
                                        <Badge variant="outline" className="text-[9px] h-4 px-1.5 py-0 border-white/10 text-muted-foreground font-mono uppercase">
                                            {displayTimeframe} ROUND
                                        </Badge>
                                    )}
                                </div>
                            </div>
                        </div>

                        {/* Right Top Status */}
                        <div className="flex flex-col items-end gap-1.5 pt-1">
                            {isTrending && index === 0 ? (
                                <Badge className="bg-red-500/10 text-red-500 border-red-500/20 text-[9px] font-black uppercase tracking-widest animate-pulse">
                                    Hot
                                </Badge>
                            ) : (
                                <>
                                    <div className={`text-xs font-black flex items-center gap-1 ${isUp ? 'text-green-500' : 'text-red-500'}`}>
                                        {isUp ? <TrendingUp className="w-4 h-4" /> : <TrendingUp className="w-4 h-4 rotate-180" />}
                                        {isUp ? '+' : ''}{change}%
                                    </div>
                                    <Badge variant="outline" className="bg-transparent border-white/10 text-[9px] font-black opacity-40">
                                        LIVE
                                    </Badge>
                                </>
                            )}
                        </div>
                    </div>

                    {/* Middle: Chart (Always visible for consistency) */}
                    <div className="space-y-6 flex-1 flex flex-col justify-end">
                        <div className="h-14 w-full bg-white/5 rounded-2xl overflow-hidden relative group/chart border border-white/5">
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
                                    strokeWidth="2.5"
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                />
                            </motion.svg>
                            {/* Animated Glow based on Direction */}
                            <div className={`absolute inset-0 bg-gradient-to-t ${isUp ? 'from-green-500/10' : 'from-red-500/10'} to-transparent opacity-0 group-hover/chart:opacity-100 transition-opacity duration-500`} />

                            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000" />
                        </div>

                        {/* Footer: Stats (Consistent across both) */}
                        {/* Footer: Stats (Consistent across both) */}
                        <div className="flex items-center justify-between pt-2">
                            {isTrending ? (
                                <>
                                    {/* Left: Participants */}
                                    <div className="flex items-center gap-1.5 px-3 py-1.5 bg-white/5 rounded-full border border-white/5" title="Active Participants">
                                        <Users className="w-3 h-3 text-blue-500" />
                                        <span className="text-[10px] font-bold text-muted-foreground">{asset.predictionCount || 0}</span>
                                    </div>

                                    {/* Right: Volume + Arrow */}
                                    <div className="flex items-center gap-2">
                                        <div className="flex items-center gap-1.5 px-3 py-1.5 bg-white/5 rounded-full border border-white/5" title="Total Volume">
                                            <span className="text-[10px] text-muted-foreground font-bold mr-1">Vol.</span>
                                            <span className="text-orange-500 font-bold text-[10px]">{typeof asset.totalVolume === 'number' ? asset.totalVolume.toLocaleString() : '0'} USDT</span>
                                        </div>
                                        <motion.div
                                            whileHover={{ x: 5 }}
                                            className="w-8 h-8 rounded-full bg-primary flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all shadow-[0_0_20px_rgba(59,130,246,0.5)]"
                                        >
                                            <ArrowRight className="w-4 h-4 text-white" />
                                        </motion.div>
                                    </div>
                                </>
                            ) : (
                                <>
                                    {/* Left: Timeframe */}
                                    <div className="flex items-center gap-1.5 px-3 py-1.5 bg-white/5 rounded-full border border-white/5 text-[10px] font-bold text-muted-foreground">
                                        <Clock className="w-3 h-3 text-blue-500" />
                                        1H RND
                                    </div>

                                    {/* Right: Participants + Arrow */}
                                    <div className="flex items-center gap-2">
                                        <div className="flex items-center gap-1.5 px-3 py-1.5 bg-white/5 rounded-full border border-white/5 text-[10px] font-bold text-muted-foreground">
                                            <Users className="w-3 h-3 text-orange-500" />
                                            {mockParticipants} LV
                                        </div>
                                        <motion.div
                                            whileHover={{ x: 5 }}
                                            className="w-8 h-8 rounded-full bg-primary flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all shadow-[0_0_20px_rgba(59,130,246,0.5)]"
                                        >
                                            <ArrowRight className="w-4 h-4 text-white" />
                                        </motion.div>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>

                    {/* AI Insight Badge (Common to both) */}
                    {!isTrending && (
                        <div className="absolute top-4 right-4 group-hover:scale-110 transition-transform">
                            <Badge className="bg-[#a855f7]/20 text-[#a855f7] border-[#a855f7]/20 text-[9px] font-black italic tracking-widest px-2 py-0.5 rounded-full">
                                AI ANALYST: {isUp ? 'BULLISH' : 'BEARISH'}
                            </Badge>
                        </div>
                    )}


                    {/* Premium Glow Overlay */}
                    <div className="absolute inset-0 border-[1px] border-white/0 group-hover:border-white/10 rounded-[inherit] transition-all duration-700 pointer-events-none" />
                    <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-primary/5 blur-[80px] group-hover:bg-primary/20 transition-all duration-700 pointer-events-none" />
                </Card>
            </Link>
        </motion.div>
    );
}
