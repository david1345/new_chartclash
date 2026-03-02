"use client";

// Mock data relocated outside to avoid render-time Date.now()
const GUEST_MOCK_HISTORY: any[] = [
    {
        id: "mock1",
        asset_symbol: "BTCUSDT",
        timeframe: "15m",
        prediction_count: 12,
        total_volume: 1200,
        direction: "UP",
        target_percent: 1.2,
        status: "WIN",
        profit: 180,
        created_at: new Date(Date.now() - 3600000).toISOString(),
        candle_close_at: new Date(Date.now() - 3600000 + 900000).toISOString(),
        is_guest: true,
        is_mock: true
    },
    {
        id: "mock2",
        asset_symbol: "ETHUSDT",
        timeframe: "1h",
        prediction_count: 8,
        total_volume: 850,
        direction: "DOWN",
        target_percent: 2.5,
        status: "LOSS",
        profit: -100,
        created_at: new Date(Date.now() - 7200000).toISOString(),
        candle_close_at: new Date(Date.now() - 7200000 + 3600000).toISOString(),
        is_guest: true,
        is_mock: true
    }
];

const GUEST_SAMPLE_CARDS = [
    { id: 'h1', time: Date.now() - 1000 * 60 * 15, symbol: 'BTC', timeframe: '1m', direction: 'UP', result: 'WIN', profit: 45 },
    { id: 'h2', time: Date.now() - 1000 * 60 * 45, symbol: 'ETH', timeframe: '5m', direction: 'DOWN', result: 'WIN', profit: 80 },
    { id: 'h3', time: Date.now() - 1000 * 60 * 120, symbol: 'BTC', timeframe: '1m', direction: 'UP', result: 'LOSS', profit: -50 },
    { id: 'h4', time: Date.now() - 1000 * 60 * 240, symbol: 'SOL', timeframe: '15m', direction: 'DOWN', result: 'WIN', profit: 120 },
];
import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowUp, ArrowDown, Sparkles, History, Activity } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import { cn } from "@/lib/utils";
import { getZoneInfo } from "@/lib/rewards";
import { useMounted } from "@/hooks/use-mounted";
import { useGuestPrediction } from "@/hooks/dashboard/use-guest-prediction";
import { toast } from "sonner";

interface Prediction {
    id: string;
    created_at: string;
    asset_symbol: string;
    direction: "UP" | "DOWN";
    status: "pending" | "WIN" | "LOSS" | "REFUND" | "ND";
    timeframe: string;
    candle_close_at: string;
    target_percent?: number;
    entry_price?: number;
    close_price?: number;
    profit?: number;
    profit_loss?: number;
    is_guest?: boolean;
    is_mock?: boolean;
}

interface PredictionTabsProps {
    predictions: Prediction[];
    user: any;
}

export function PredictionTabs({ predictions, user }: PredictionTabsProps) {
    const mounted = useMounted();
    const { guestPredictions } = useGuestPrediction();

    // Use either real predictions or guest prediction
    let allPredictions = [...predictions];

    // Add Guest Predictions correctly if they exist
    if (!user && guestPredictions && guestPredictions.length > 0) {
        // Avoid duplicate if it somehow exists in predictions
        const newGuestPreds = guestPredictions.filter(gp => !predictions.find(p => p.id === gp.id));
        allPredictions = [...newGuestPreds, ...allPredictions];
    }

    if (!user && predictions.length === 0 && (!guestPredictions || guestPredictions.length === 0)) {
        allPredictions = [...allPredictions, ...GUEST_MOCK_HISTORY];
    }

    const pendingPredictions = allPredictions.filter(p => p.status === 'pending');
    const historyPredictions = allPredictions
        .filter(p => p.status !== 'pending')
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    const formatTime = (date: string | number) => {
        if (!mounted) return "--:--";
        return new Date(date).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true });
    };

    return (
        <Card className="h-[340px] mt-auto bg-card/20 border-white/60 overflow-hidden flex flex-col shrink-0">
            <CardHeader className="py-1 px-3 bg-black/20 border-b border-white/10 shrink-0 min-h-[36px] flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-xs font-bold flex items-center gap-2 uppercase tracking-wider text-white">
                    <History className="w-3 h-3 text-primary" /> Active Predictions
                </CardTitle>
                {user || (guestPredictions && guestPredictions.length > 0) ? (
                    <Button id="tutorial-all-history" variant="ghost" size="sm" className="h-5 text-[10px] px-2 text-muted-foreground hover:text-white hover:bg-white/10" asChild>
                        <Link href="/match-history">
                            All History <ArrowUp className="w-3 h-3 rotate-45 ml-1" />
                        </Link>
                    </Button>
                ) : (
                    <Button
                        id="tutorial-all-history"
                        variant="ghost"
                        size="sm"
                        onClick={() => toast.info("Make a prediction to see your match history and detailed analytics!")}
                        className="h-5 text-[10px] px-2 text-muted-foreground hover:text-white hover:bg-white/10"
                    >
                        All History <ArrowUp className="w-3 h-3 rotate-45 ml-1" />
                    </Button>
                )}
            </CardHeader>

            <CardContent className="p-0 flex-1 relative min-h-0 flex flex-col">
                <Tabs defaultValue="active" className="w-full h-full flex flex-col">
                    <div className="px-3 border-b border-white/5 bg-black/40 pt-1 shrink-0">
                        <TabsList className="h-7 bg-white/5">
                            <TabsTrigger id="tutorial-active-tab" value="active" className="h-6 text-[10px]">
                                Active
                                {pendingPredictions.length > 0 && (
                                    <Badge className="ml-1.5 h-4 px-1 min-w-[16px] bg-primary/20 text-primary border-0">{pendingPredictions.length}</Badge>
                                )}
                            </TabsTrigger>
                            <TabsTrigger id="tutorial-history-tab" value="history" className="h-6 text-[10px]">History</TabsTrigger>
                        </TabsList>
                    </div>

                    {/* Column Headers */}
                    <div className="grid grid-cols-5 px-2 pt-1 pb-1 bg-black/40 border-b border-white/5 text-[9px] md:text-[10px] font-bold text-gray-500 uppercase tracking-widest text-center shrink-0">
                        <span>Time</span>
                        <span>Asset</span>
                        <span>Chart</span>
                        <span>My Pick</span>
                        <span>Status</span>
                    </div>

                    <div className="flex-1 min-h-0 relative">
                        <ScrollArea className="h-full w-full [&_.radix-scroll-area-thumb]:bg-white/40 [&_.radix-scroll-area-thumb]:hover:bg-white/60 [&_.radix-scroll-area-scrollbar]:w-2 [&_.radix-scroll-area-scrollbar]:bg-white/5">
                            <TabsContent value="active" className="m-0 border-0 h-full">
                                <div className="divide-y divide-white/5">
                                    {pendingPredictions.length === 0 ? (
                                        <div className="h-full flex flex-col items-center justify-center p-6 text-center">
                                            {!user ? (
                                                <div className="space-y-4 max-w-[240px]">
                                                    <div className="w-12 h-12 mx-auto rounded-full bg-primary/10 flex items-center justify-center mb-2">
                                                        <Sparkles className="w-6 h-6 text-primary animate-pulse" />
                                                    </div>
                                                    <div className="space-y-1">
                                                        <h3 className="text-sm font-bold text-white">Sign in to start</h3>
                                                        <p className="text-[10px] text-muted-foreground leading-relaxed">
                                                            Join the competition to earn points and climb the leaderboard.
                                                        </p>
                                                    </div>
                                                    <div className="text-[10px] text-left space-y-1.5 bg-white/5 p-3 rounded-lg border border-white/5">
                                                        <div className="flex items-center gap-2 text-gray-300">
                                                            <div className="w-1 h-1 rounded-full bg-emerald-500" />
                                                            Make predictions
                                                        </div>
                                                        <div className="flex items-center gap-2 text-gray-300">
                                                            <div className="w-1 h-1 rounded-full bg-amber-500" />
                                                            Earn points
                                                        </div>
                                                        <div className="flex items-center gap-2 text-gray-300">
                                                            <div className="w-1 h-1 rounded-full bg-blue-500" />
                                                            Climb leaderboard
                                                        </div>
                                                    </div>
                                                    <div className="flex gap-2 justify-center pt-2">
                                                        <Link href="/login" className="flex-1">
                                                            <Button size="sm" className="w-full h-7 text-xs font-bold bg-primary text-primary-foreground hover:bg-primary/90">
                                                                Sign In
                                                            </Button>
                                                        </Link>
                                                    </div>
                                                </div>
                                            ) : (
                                                <div className="py-8 space-y-3 flex flex-col items-center justify-center h-full opacity-60">
                                                    <div className="relative w-16 h-16 flex items-center justify-center">
                                                        <Activity className="w-8 h-8 text-muted-foreground/50" />
                                                    </div>
                                                    <div className="text-center space-y-1">
                                                        <h4 className="text-xs font-bold text-muted-foreground tracking-widest uppercase">No Active Predictions</h4>
                                                        <p className="text-[10px] text-muted-foreground/60 font-mono">
                                                            Place a bet to separate the alpha from the noise.
                                                        </p>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    ) : (
                                        pendingPredictions.map((pred) => {
                                            const zone = getZoneInfo(pred.timeframe, pred.created_at, pred.candle_close_at);
                                            return (
                                                <div key={pred.id} className="grid grid-cols-5 items-center p-2.5 text-xs hover:bg-white/5 transition-colors text-center border-l-2 border-transparent hover:border-primary/50 relative group">
                                                    <div className="absolute inset-0 bg-gradient-to-r from-primary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
                                                    {/* Time */}
                                                    <span className="text-gray-400 font-mono text-[10px]">{formatTime(pred.created_at)}</span>

                                                    {/* Asset */}
                                                    <div className="flex flex-col items-center">
                                                        <span className="font-bold text-white tracking-tight">{pred.asset_symbol}</span>
                                                        {pred.is_guest && (
                                                            <Badge className={cn(
                                                                "scale-[0.7] h-3 px-1 border-primary/30",
                                                                pred.is_mock ? "bg-white/10 text-white/40" : "bg-primary/20 text-primary"
                                                            )}>
                                                                {pred.is_mock ? "DEMO" : "GUEST"}
                                                            </Badge>
                                                        )}
                                                    </div>

                                                    {/* Timeframe with Zone Styling */}
                                                    <div className="flex justify-center">
                                                        <Badge variant="outline" className={cn(
                                                            "h-4 px-1.5 text-[9px] font-bold border-2",
                                                            zone.color,
                                                            zone.border,
                                                            zone.bg
                                                        )}>
                                                            {pred.timeframe || '-'}
                                                        </Badge>
                                                    </div>

                                                    {/* Pick */}
                                                    <div className="flex justify-center gap-1">
                                                        {pred.direction === 'UP' ? (
                                                            <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20 px-1 py-0 h-4 font-mono text-[9px]">
                                                                <ArrowUp className="w-2 h-2 mr-0.5" /> Target {pred.target_percent}%
                                                            </Badge>
                                                        ) : (
                                                            <Badge variant="outline" className="bg-red-500/10 text-red-500 border-red-500/20 px-1 py-0 h-4 font-mono text-[9px]">
                                                                <ArrowDown className="w-2 h-2 mr-0.5" /> Target {pred.target_percent}%
                                                            </Badge>
                                                        )}
                                                    </div>

                                                    {/* Status - Animated Pulse */}
                                                    <div className="flex justify-center">
                                                        <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-white/5 border border-white/5 text-[9px]">
                                                            <div className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse shadow-[0_0_8px_rgba(245,158,11,0.5)]" />
                                                            <span className="text-amber-500 font-bold tracking-wider">LIVE</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            )
                                        })
                                    )}
                                </div>
                            </TabsContent>

                            <TabsContent value="history" className="m-0 border-0 flex-1 overflow-hidden min-h-0">
                                <div className="h-full overflow-y-auto divide-y divide-white/5 scrollbar-thin scrollbar-thumb-white/10">
                                    {historyPredictions.length === 0 ? (
                                        // Dummy History Data
                                        <>
                                            {[
                                                { id: 'h1', time: Date.now() - 1000 * 60 * 15, symbol: 'BTC', timeframe: '1m', direction: 'UP', result: 'WIN', profit: 45 },
                                                { id: 'h2', time: Date.now() - 1000 * 60 * 45, symbol: 'ETH', timeframe: '5m', direction: 'DOWN', result: 'WIN', profit: 80 },
                                                { id: 'h3', time: Date.now() - 1000 * 60 * 120, symbol: 'BTC', timeframe: '1m', direction: 'UP', result: 'LOSS', profit: -50 },
                                                { id: 'h4', time: Date.now() - 1000 * 60 * 240, symbol: 'SOL', timeframe: '15m', direction: 'DOWN', result: 'WIN', profit: 120 },
                                            ].map((item) => (
                                                <div key={item.id} className="grid grid-cols-5 items-center p-2.5 text-xs text-center border-l-2 border-transparent opacity-60 grayscale hover:grayscale-0 hover:opacity-100 transition-all">
                                                    <span className="text-gray-500 font-mono text-[10px]">{formatTime(item.time)}</span>
                                                    <span className="font-bold text-gray-400">{item.symbol}</span>
                                                    <div className="flex justify-center">
                                                        <Badge variant="outline" className="h-4 px-1.5 text-[9px] font-bold border-white/10 text-gray-500 bg-white/5">
                                                            {item.timeframe}
                                                        </Badge>
                                                    </div>
                                                    <span className={cn("font-bold text-[10px]", item.direction === 'UP' ? "text-emerald-500/70" : "text-red-500/70")}>
                                                        {item.direction}
                                                    </span>
                                                    <div>
                                                        {item.result === 'WIN' && <Badge className="bg-emerald-500/10 text-emerald-500/70 border-0 h-4 px-1 text-[9px]">WIN (+{item.profit})</Badge>}
                                                        {item.result === 'LOSS' && <Badge className="bg-red-500/10 text-red-500/70 border-0 h-4 px-1 text-[9px]">LOSS</Badge>}
                                                    </div>
                                                </div>
                                            ))}
                                            <div className="p-2 text-center border-t border-white/5">
                                                <p className="text-[9px] text-muted-foreground italic">
                                                    (Sample History - Make a prediction to see yours)
                                                </p>
                                            </div>
                                        </>
                                    ) : (
                                        historyPredictions.map((pred) => {
                                            const zone = getZoneInfo(pred.timeframe, pred.created_at, pred.candle_close_at);
                                            return (
                                                <div key={pred.id} className="grid grid-cols-5 items-center p-2.5 text-xs text-center hover:bg-white/5">
                                                    <span className="text-gray-500 font-mono text-[10px]">{formatTime(pred.created_at)}</span>
                                                    <div className="flex flex-col items-center">
                                                        <span className="font-bold">{pred.asset_symbol}</span>
                                                        {pred.is_guest && (
                                                            <Badge className={cn(
                                                                "scale-[0.7] h-3 px-1 border-primary/30",
                                                                pred.is_mock ? "bg-white/10 text-white/40" : "bg-primary/20 text-primary"
                                                            )}>
                                                                {pred.is_mock ? "DEMO" : "GUEST"}
                                                            </Badge>
                                                        )}
                                                    </div>
                                                    <div className="flex justify-center">
                                                        <Badge variant="outline" className={cn(
                                                            "h-4 px-1.5 text-[9px] font-bold border-2",
                                                            zone.color,
                                                            zone.border,
                                                            zone.bg
                                                        )}>
                                                            {pred.timeframe}
                                                        </Badge>
                                                    </div>
                                                    <span className={cn("font-bold text-[10px]", pred.direction === 'UP' ? "text-emerald-500" : "text-red-500")}>
                                                        {pred.direction}
                                                    </span>
                                                    <div>
                                                        {pred.status === 'WIN' && <Badge className="bg-emerald-500/20 text-emerald-400 border-0 h-4 px-1 text-[9px]">WIN (+{Math.round(Number(pred.profit_loss || pred.profit || 0))})</Badge>}
                                                        {pred.status === 'LOSS' && <Badge className="bg-red-500/20 text-red-400 border-0 h-4 px-1 text-[9px]">LOSS</Badge>}
                                                        {pred.status === 'REFUND' && <Badge className="bg-white/10 text-gray-400 border-0 h-4 px-1 text-[9px]">REFUND</Badge>}
                                                        {pred.status === 'ND' && <Badge className="bg-white/10 text-gray-400 border-0 h-4 px-1 text-[9px]">DRAW</Badge>}
                                                    </div>
                                                </div>
                                            )
                                        })
                                    )}
                                </div>
                            </TabsContent>
                        </ScrollArea>
                    </div>
                </Tabs>
            </CardContent>
        </Card>
    );
}
