"use client";

import { useEffect, useState } from "react";
import { ArrowUp, ArrowDown, ArrowRight, Activity, Sparkles, Trophy, Timer, Loader2, ChevronDown, Search, Zap } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import { cn } from "@/lib/utils";
import { ASSETS, TIMEFRAMES } from "@/lib/constants";
import { calculateReward } from "@/lib/rewards";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { CandleTimer } from "@/components/dashboard/candle-timer";
import { Lock } from "lucide-react";
// import Link from "next/link";
import { useGuestPrediction } from "@/hooks/dashboard/use-guest-prediction";


interface OrderPanelProps {
    user: any;
    userPoints: number;
    userStreak: number;
    setUserPoints: (points: number) => void;
    selectedAsset: any;
    setSelectedAsset: (asset: any) => void;
    selectedTimeframe: string;
    setSelectedTimeframe: (tf: string) => void;
    marketStatus: { isOpen: boolean; reason?: string };
    isLocked: boolean;
    isAlreadyBet: boolean;
    refreshPredictions: () => void;
    fetchUserStats: () => void;
    onBetSuccess?: () => void;
    isLoaded: boolean;

}

export function OrderPanel({
    user,
    userPoints,
    userStreak,
    setUserPoints,
    selectedAsset,
    setSelectedAsset,
    selectedTimeframe,
    setSelectedTimeframe,
    marketStatus,
    isLocked,
    isAlreadyBet,
    refreshPredictions,
    fetchUserStats,
    onBetSuccess,
    isLoaded
}: OrderPanelProps) {
    const { submitGuestPrediction, guestPoints } = useGuestPrediction();

    // Local State
    const [betAmount, setBetAmount] = useState(10);
    const [selectedDirection, setSelectedDirection] = useState<"UP" | "DOWN" | null>(null);
    const [selectedPercent, setSelectedPercent] = useState<number | null>(0.5);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [assetSearch, setAssetSearch] = useState("");
    const [isAssetDialogOpen, setIsAssetDialogOpen] = useState(false);
    const [isTimeframeOpen, setIsTimeframeOpen] = useState(false);

    const [isDetailsOpen, setIsDetailsOpen] = useState(false);
    const [isGuideActive, setIsGuideActive] = useState(false); // Visual cue for new users

    useEffect(() => {
        const isGuest = !user || user.is_guest;

        // Point 3: Only show visual guidance for quests or newly transitioning users
        const isTransitioning = typeof window !== 'undefined' ? localStorage.getItem('chartclash_is_transitioning') === 'true' : false;
        const isNewUser = typeof window !== 'undefined' ? !localStorage.getItem('vibe_tutorial_completed') : false;

        if (isTransitioning || isNewUser || isGuest) {
            setIsGuideActive(true);
            const timer = setTimeout(() => setIsGuideActive(false), 3000);
            return () => clearTimeout(timer);
        }
    }, [user, guestPoints]);

    // Market Data (Round specifics)
    // const [userStreakState, setUserStreakState] = useState<number | null>(null);
    // const [rewardsState, setRewardsState] = useState({ min: 0, max: 0 });
    const isAIBeatEnabled = process.env.NEXT_PUBLIC_ENABLE_AI_BEAT === 'true';
    const [candleElapsed, setCandleElapsed] = useState<number | null>(null);
    const [roundOpenPrice, setRoundOpenPrice] = useState<number | null>(null);

    const supabase = createClient();

    const [isUserModified, setIsUserModified] = useState(false);

    // Realtime Subscription (Notifications -> Refresh Stats)
    useEffect(() => {
        if (!user || user.is_guest) return;
        // Placeholder for actual subscription logic
        // For example:
        // const channel = supabase.channel('user_updates')
        //   .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'profiles', filter: `id=eq.${user.id}` }, payload => {
        //     console.log('Change received!', payload);
        //     fetchUserStats();
        //   })
        //   .subscribe();
        // return () => {
        //   supabase.removeChannel(channel);
        // };
    }, [user, fetchUserStats]);

    // Initialize bet amount when user points load
    useEffect(() => {
        const isGuest = !user || user?.is_guest;
        const currentPoints = isGuest ? guestPoints : userPoints;
        if (!isUserModified && isLoaded && currentPoints > 0) {
            if (currentPoints <= 1000) {
                setBetAmount(10);
            } else {
                setBetAmount(Math.max(1, Math.floor(currentPoints * 0.01)));
            }
        }
    }, [userPoints, guestPoints, isLoaded, isUserModified, user]);

    const filteredAssets = (category: any[] = []) => {
        const list = category || [];
        const search = assetSearch.trim().toLowerCase();
        if (!search) return list;
        return list.filter(a =>
            (a.name?.toLowerCase().includes(search)) ||
            (a.symbol?.toLowerCase().includes(search))
        );
    };

    // Helper for UI calculation display
    const getWinPotential = () => {
        // Use shared logic from lib/rewards for consistency
        return {
            min: calculateReward(betAmount, 0, userStreak, selectedTimeframe, candleElapsed, false),
            max: calculateReward(betAmount, selectedPercent || 0, userStreak, selectedTimeframe, candleElapsed, true)
        };
    };

    const rewards = getWinPotential();


    const fetchCandleData = async (symbol: string, timeframe: string, type: 'CRYPTO' | 'STOCK' | 'COMMODITY') => {
        try {
            const res = await fetch("/api/market/entry-price", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ symbol, timeframe, type })
            });
            const json = await res.json();
            if (!json.success || !json.data) {
                console.error("Price fetch failed:", json.error);
                return null;
            }
            if (json.data.candleElapsedSeconds !== undefined) setCandleElapsed(json.data.candleElapsedSeconds);
            if (json.data.openPrice !== undefined) setRoundOpenPrice(json.data.openPrice);
            return json.data;
        } catch (e) {
            console.error("Server price API error", e);
            return null;
        }
    };

    const handleSubmitPrediction = async () => {
        if (isSubmitting) return;

        const isGuest = !user || user.is_guest;

        if (isGuest) {
            const maxBet = Math.floor(guestPoints * 0.2);
            const minBet = Math.max(10, Math.floor(guestPoints * 0.01));

            if (betAmount < minBet) {
                toast.warning(<div data-testid="error-min-bet">Minimum bet is {minBet} points (1% of your holdings)</div>);
                return;
            }
            if (betAmount > maxBet && guestPoints > 50) {
                toast.warning(<div data-testid="error-max-bet">Max bet is {maxBet} pts (20% of your holdings)</div>);
                return;
            }

            if (isLocked) {
                toast.error("Round is locked! Create a prediction for the next candle.");
                return;
            }

            setIsSubmitting(true);
            try {
                const candleData = await fetchCandleData(selectedAsset.symbol as string, selectedTimeframe, selectedAsset.type as any);
                if (!candleData) {
                    toast.error("Could not fetch market data. Try again.");
                    return;
                }

                submitGuestPrediction({
                    asset_symbol: selectedAsset.symbol,
                    timeframe: selectedTimeframe,
                    direction: selectedDirection!,
                    target_percent: selectedPercent!,
                    entry_price: candleData.openPrice,
                    bet_amount: betAmount,
                    candle_close_at: new Date(Date.now() + 60000).toISOString(), // Mock for UI, PlayContent will re-calc
                });

                toast.success(
                    <div className="flex flex-col gap-1">
                        <p className="font-bold">Guest Prediction Placed!</p>
                        <p className="text-xs">Experience the clash. Sign up after resolution to save points!</p>
                    </div>
                );

                // Reset UI
                setSelectedDirection(null);
                setIsDetailsOpen(false);

                // Clear Round Info after a delay (same as logged-in flow)
                setTimeout(() => {
                    setRoundOpenPrice(null);
                    setCandleElapsed(null);
                }, 5000);

                if (onBetSuccess) onBetSuccess();
                refreshPredictions();

            } catch (e) {
                console.error(e);
            } finally {
                setIsSubmitting(false);
            }
            return;
        }

        const maxBet = Math.floor(userPoints * 0.2);
        const minBet = Math.max(10, Math.floor(userPoints * 0.01));

        if (betAmount < minBet) {
            toast.warning(<div data-testid="error-min-bet">Minimum bet is {minBet} points (1% of your holdings)</div>);
            return;
        }
        if (betAmount > maxBet && userPoints > 50) {
            toast.warning(<div data-testid="error-max-bet">Max bet is {maxBet} pts (20% of your holdings)</div>);
            return;
        }

        if (isLocked) {
            toast.error("Round is locked! Create a prediction for the next candle.");
            return;
        }

        setIsSubmitting(true);
        console.log(`[OrderPanel] Submitting prediction: ${selectedAsset.symbol} ${selectedTimeframe} ${selectedDirection}`);

        try {
            const candleData = await fetchCandleData(selectedAsset.symbol as string, selectedTimeframe, selectedAsset.type as any);

            if (!candleData) {
                toast.error("Could not fetch market data. Try again.");
                return;
            }

            // Ensure Profile Exists with Initial Points (Idempotent)
            const { data: existingProfile } = await supabase
                .from('profiles')
                .select('id, points')
                .eq('id', user.id)
                .single();

            if (!existingProfile) {
                const userEmail = (user as any).email || "";
                await supabase.from('profiles').insert({
                    id: user.id,
                    email: userEmail,
                    username: userEmail.split('@')[0] || 'User',
                    points: 1000
                });
            } else if (existingProfile.points === null || existingProfile.points === undefined) {
                // Fix existing profiles with null points
                await supabase
                    .from('profiles')
                    .update({ points: 1000 })
                    .eq('id', user.id);
            }

            // *** TRANSACTIONAL SUBMISSION (RPC) ***
            const { data: rpcData, error: rpcError } = await supabase.rpc('submit_prediction', {
                p_user_id: user.id,
                p_asset_symbol: selectedAsset.symbol,
                p_timeframe: selectedTimeframe,
                p_direction: selectedDirection,
                p_target_percent: selectedPercent,
                p_entry_price: candleData.openPrice,
                p_bet_amount: betAmount
            });

            if (rpcError) {
                const isInsufficient = rpcError.message?.toLowerCase().includes('insufficient');
                toast.error(
                    <div data-testid={isInsufficient ? "error-insufficient-balance" : undefined}>
                        Submission failed: {rpcError.message}
                    </div>
                );
                return;
            } else {
                const formattedPrice = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(candleData.openPrice);

                toast.success(
                    <div data-testid="prediction-success" className="flex flex-col gap-2">
                        <p className="font-bold">Locked for Round Start: {formattedPrice}</p>
                        {isAIBeatEnabled && (
                            <p className="text-xs text-muted-foreground">Waiting for results? Try a quick AI-Beat 챌린지!</p>
                        )}
                    </div>,
                    {
                        duration: 5000,
                        action: isAIBeatEnabled ? {
                            label: "Challenge AI",
                            onClick: () => onBetSuccess?.(),
                        } : undefined
                    }
                );

                // Auto-open if enabled
                if (isAIBeatEnabled) {
                    onBetSuccess?.();
                }

                // Keep Round Info for a bit
                setTimeout(() => {
                    setRoundOpenPrice(null);
                    setCandleElapsed(null);
                }, 5000);

                // Reset UI
                setSelectedDirection(null);
                setSelectedPercent(0.5);
                setBetAmount(10);
                setIsUserModified(false);
                setIsDetailsOpen(false);

                // Refresh Data
                refreshPredictions();

                // Update local points
                if (rpcData && rpcData.new_points !== undefined) {
                    setUserPoints(rpcData.new_points);
                } else {
                    fetchUserStats();
                }
            }
        } catch (error: any) {
            console.error("Submission error:", error);
            toast.error(error?.message || "An unexpected error occurred. Please try again.");
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <Card className="h-[480px] flex-none border-white/60 bg-gradient-to-b from-card/80 to-card/40 shadow-2xl shadow-primary/5 overflow-visible flex flex-col pb-2">
            <CardHeader className="py-2 px-3 border-b border-white/10 flex flex-row items-center justify-between space-y-0 h-10 shrink-0 bg-black/20">
                <CardTitle className="text-sm font-bold flex items-center gap-2 uppercase tracking-wider text-white">
                    <Zap className="w-4 h-4 text-primary" /> Forecast
                </CardTitle>
                <div className="flex items-center gap-1">
                    <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 px-2 flex flex-col items-center justify-center leading-none border border-white/5 bg-white/5 hover:bg-primary/10 group transition-all rounded-md"
                        onClick={() => window.dispatchEvent(new Event("trigger-tutorial"))}
                    >
                        <span className="text-[8px] font-black text-muted-foreground group-hover:text-primary transition-colors uppercase tracking-widest">How to</span>
                        <span className="text-[10px] font-black text-primary group-hover:scale-105 transition-transform uppercase tracking-tighter">Play</span>
                    </Button>
                    <div className={cn("text-[10px] font-mono font-bold px-1.5 py-0.5 rounded border flex items-center gap-1.5 min-w-[80px] justify-center bg-black/40 border-white/10")}>
                        <CandleTimer timeframe={selectedTimeframe} onLockChange={() => { }} />
                    </div>
                </div>
            </CardHeader>

            <div className="relative w-full flex-1 flex flex-col">
                {/* ⚖️ Fairness Model Header Info */}
                {roundOpenPrice && (
                    <div className="absolute inset-x-0 mx-3 mt-1.5 p-3 rounded-xl bg-black/95 backdrop-blur-xl border border-primary/20 flex flex-col gap-1 z-50 shadow-[0_20px_50px_rgba(0,0,0,0.5)] animate-in fade-in zoom-in duration-300">
                        <div className="flex justify-between items-center">
                            <span className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Round Start Price</span>
                            <span className="text-xs font-mono font-bold text-primary">${roundOpenPrice.toLocaleString()}</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <span className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Round Process (%)</span>
                            <span className="text-xs font-mono text-white">
                                {Math.floor(candleElapsed! / 60)}m {candleElapsed! % 60}s
                            </span>
                        </div>

                        {/* Reward Decay Indicator (Multiplier Zones) */}
                        {candleElapsed !== null && (
                            <div className="mt-2 pt-2 border-t border-white/5 space-y-2">
                                <div className="flex justify-between items-center">
                                    <span className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Reward Multiplier</span>
                                    {(() => {
                                        const tf = selectedTimeframe;
                                        let tfSeconds = 900;
                                        if (tf === '1m') tfSeconds = 60;
                                        else if (tf === '5m') tfSeconds = 300;
                                        else if (tf === '15m') tfSeconds = 900;
                                        else if (tf === '30m') tfSeconds = 1800;
                                        else if (tf.includes('h')) tfSeconds = parseInt(tf) * 3600;
                                        else if (tf.includes('d')) tfSeconds = 86400;

                                        const ratio = candleElapsed / tfSeconds;
                                        let zone = { label: "GREEN", color: "text-emerald-400", mult: "1.0x", bg: "bg-emerald-500/10", border: "border-emerald-500/30" };

                                        if (ratio >= 0.9) zone = { label: "LOCKED", color: "text-rose-600", mult: "0.0x", bg: "bg-rose-600/10", border: "border-rose-600/30" };
                                        else if (ratio >= 0.66) zone = { label: "RED", color: "text-rose-400", mult: "0.3x", bg: "bg-rose-400/10", border: "border-rose-400/30" };
                                        else if (ratio >= 0.33) zone = { label: "YELLOW", color: "text-amber-400", mult: "0.6x", bg: "bg-amber-400/10", border: "border-amber-400/30" };

                                        return (
                                            <Badge variant="outline" className={cn("h-4 text-[9px] px-1.5 font-bold", zone.color, zone.bg, zone.border)}>
                                                {zone.label} ZONE ({zone.mult})
                                            </Badge>
                                        );
                                    })()}
                                </div>

                                {/* Timeline Gauge */}
                                <div className="h-1.5 w-full bg-white/5 rounded-full overflow-hidden flex">
                                    {(() => {
                                        const tf = selectedTimeframe;
                                        let tfSeconds = 900;
                                        if (tf === '1m') tfSeconds = 60;
                                        else if (tf === '5m') tfSeconds = 300;
                                        else if (tf === '15m') tfSeconds = 900;
                                        else if (tf === '30m') tfSeconds = 1800;
                                        else if (tf.includes('h')) tfSeconds = parseInt(tf) * 3600;
                                        else if (tf.includes('d')) tfSeconds = 86400;

                                        const ratio = Math.min(1, candleElapsed / tfSeconds);
                                        return (
                                            <div
                                                className={cn(
                                                    "h-full transition-all duration-1000",
                                                    ratio < 0.33 ? "bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.4)]" :
                                                        ratio < 0.66 ? "bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.4)]" :
                                                            "bg-rose-500 shadow-[0_0_8px_rgba(244,63,94,0.4)]"
                                                )}
                                                style={{ width: `${ratio * 100}%` }}
                                            />
                                        );
                                    })()}
                                </div>
                                <p className="text-[9px] text-center text-muted-foreground">
                                    {candleElapsed > (900 * 0.66) ? "🔥 High risk, low reward" : candleElapsed > (900 * 0.33) ? "⚠️ Early entry for streak bonus" : "✨ Early Bird: Full Multiplier & Streak Bonus"}
                                </p>
                            </div>
                        )}
                    </div>
                )}

                {/* Unlocked Selector Area */}
                <div className="px-3 pt-1 pb-1">
                    <div id="tutorial-asset-time" className={cn(
                        "flex items-center gap-2 transition-all duration-500 rounded-lg p-1",
                        isGuideActive && "bg-primary/20 ring-2 ring-primary shadow-[0_0_30px_rgba(16,185,129,0.3)] animate-pulse"
                    )}>
                        {/* Asset Selector */}
                        <Dialog open={isAssetDialogOpen} onOpenChange={setIsAssetDialogOpen}>
                            <DialogTrigger asChild>
                                <Button data-testid="asset-selector" variant="outline" className="flex-1 justify-between border-white/20 bg-primary/5 hover:bg-primary/10 text-sm h-8 hover:border-white/40 transition-colors">
                                    <span className="flex items-center gap-2 truncate">
                                        {selectedAsset.type === 'CRYPTO' && <span className="text-[10px] text-muted-foreground">Crypto</span>}
                                        {selectedAsset.type === 'STOCK' && <span className="text-[10px] text-muted-foreground">Stock</span>}
                                        <span className="font-bold">{selectedAsset.symbol}</span>
                                    </span>
                                    <ChevronDown className="w-3 h-3 opacity-50" />
                                </Button>
                            </DialogTrigger>
                            <DialogContent className="sm:max-w-[425px] bg-card border-white/10">
                                <DialogHeader>
                                    <DialogTitle>Select Asset</DialogTitle>
                                </DialogHeader>
                                <div className="p-1">
                                    <div className="relative mb-4">
                                        <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                                        <Input
                                            placeholder="Search assets..."
                                            className="pl-8 bg-black/20 border-white/10"
                                            value={assetSearch}
                                            onChange={(e) => setAssetSearch(e.target.value)}
                                        />
                                    </div>
                                    <Tabs defaultValue="CRYPTO" className="w-full">
                                        <TabsList className="grid w-full grid-cols-3 bg-black/20">
                                            <TabsTrigger value="CRYPTO" className="text-[11px]">Crypto ({ASSETS.CRYPTO?.length || 0})</TabsTrigger>
                                            <TabsTrigger value="STOCKS" className="text-[11px]">Stocks ({ASSETS.STOCKS?.length || 0})</TabsTrigger>
                                            <TabsTrigger value="COMMODITIES" className="text-[11px]">Cmdty ({ASSETS.COMMODITIES?.length || 0})</TabsTrigger>
                                        </TabsList>

                                        <ScrollArea className="h-[300px] mt-2 pr-4 bg-black/10 rounded-md border border-white/5">
                                            <TabsContent value="CRYPTO" className="space-y-1 p-1">
                                                {filteredAssets(ASSETS.CRYPTO).map(asset => (
                                                    <Button key={`list-crypto-${asset.symbol}`} data-testid={`asset-option-${asset.symbol}`} variant="ghost" className="w-full justify-start font-mono h-12" onClick={() => { setSelectedAsset(asset); setIsAssetDialogOpen(false); setAssetSearch(""); }}>
                                                        <div className="flex flex-col items-start text-left">
                                                            <span className="font-bold">{asset.symbol}</span>
                                                            <span className="text-[10px] text-muted-foreground">{asset.name}</span>
                                                        </div>
                                                        {selectedAsset.symbol === asset.symbol && <div className="ml-auto w-2 h-2 rounded-full bg-primary" />}
                                                    </Button>
                                                ))}
                                            </TabsContent>
                                            <TabsContent value="STOCKS" className="space-y-1 p-1">
                                                {filteredAssets(ASSETS.STOCKS).map(asset => (
                                                    <Button key={`list-stock-${asset.symbol}`} data-testid={`asset-option-${asset.symbol}`} variant="ghost" className="w-full justify-start font-mono h-12" onClick={() => { setSelectedAsset(asset); setIsAssetDialogOpen(false); setAssetSearch(""); }}>
                                                        <div className="flex flex-col items-start text-left">
                                                            <span className="font-bold">{asset.symbol}</span>
                                                            <span className="text-[10px] text-muted-foreground">{asset.name}</span>
                                                        </div>
                                                        {selectedAsset.symbol === asset.symbol && <div className="ml-auto w-2 h-2 rounded-full bg-primary" />}
                                                    </Button>
                                                ))}
                                                {filteredAssets(ASSETS.STOCKS).length === 0 && (
                                                    <div className="text-center py-10 text-xs text-muted-foreground">No stocks found</div>
                                                )}
                                            </TabsContent>
                                            <TabsContent value="COMMODITIES" className="space-y-1 p-1">
                                                {filteredAssets(ASSETS.COMMODITIES).map(asset => (
                                                    <Button key={`list-cmdty-${asset.symbol}`} data-testid={`asset-option-${asset.symbol}`} variant="ghost" className="w-full justify-start font-mono h-12" onClick={() => { setSelectedAsset(asset); setIsAssetDialogOpen(false); setAssetSearch(""); }}>
                                                        <div className="flex flex-col items-start text-left">
                                                            <span className="font-bold">{asset.symbol}</span>
                                                            <span className="text-[10px] text-muted-foreground">{asset.name}</span>
                                                        </div>
                                                        {selectedAsset.symbol === asset.symbol && <div className="ml-auto w-2 h-2 rounded-full bg-primary" />}
                                                    </Button>
                                                ))}
                                            </TabsContent>
                                        </ScrollArea>
                                    </Tabs>
                                </div>
                            </DialogContent>
                        </Dialog>

                        {/* Timeframe Selector */}
                        <Popover open={isTimeframeOpen} onOpenChange={setIsTimeframeOpen}>
                            <PopoverTrigger asChild>
                                <Button data-testid="timeframe-selector" variant="outline" className="w-[80px] justify-between border-white/20 bg-black/20 hover:bg-white/5 text-xs h-8 hover:border-white/40 transition-colors">
                                    <span className="font-bold">{selectedTimeframe}</span>
                                    <ChevronDown className="w-3 h-3 opacity-50" />
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent className="w-[120px] p-1 bg-card border-white/10">
                                <div className="flex flex-col gap-1">
                                    {TIMEFRAMES.filter((tf) => {
                                        // Restricted timeframes for normal users
                                        if (tf === '1m' || tf === '5m') {
                                            const authorizedEmails = ['sjustone000@gmail.com', 'admin@chartclash.app'];
                                            const userEmail = user?.email || user?.user_metadata?.email;
                                            return authorizedEmails.includes(userEmail);
                                        }
                                        return true;
                                    }).map((tf) => (
                                        <Button
                                            key={tf}
                                            data-testid={`timeframe-${tf}`}
                                            size="sm"
                                            variant="ghost"
                                            onClick={() => { setSelectedTimeframe(tf); setIsTimeframeOpen(false); }}
                                            className={cn("h-8 w-full justify-start font-mono text-xs", selectedTimeframe === tf && "bg-white/10 text-white font-bold")}
                                        >
                                            {tf}
                                        </Button>
                                    ))}
                                </div>
                            </PopoverContent>
                        </Popover>
                    </div>
                </div>

                {/* Magnitude & Bet Amount */}
                <div className="px-3 space-y-2">
                    {/* Magnitude (Target) */}
                    <div id="tutorial-target" className="flex items-center gap-2 h-7 mb-0.5">
                        <div className="flex-1 relative">
                            <Button
                                variant="outline"
                                className="h-7 w-full justify-start pl-2 text-[10px] font-bold text-muted-foreground border-white/5 bg-black/40 hover:bg-black/40 cursor-default"
                            >
                                TARGET
                            </Button>
                        </div>
                        <div className="flex gap-1">
                            {[0.5, 1.0, 1.5, 2.0].map((val) => (
                                <Button
                                    key={val}
                                    data-testid={`target-${val.toFixed(1)}`}
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setSelectedPercent(val)}
                                    className={cn(
                                        "h-7 min-w-[3rem] px-0 transition-all font-mono text-[10px] border-2",
                                        selectedPercent === val
                                            ? "bg-transparent text-amber-500 font-extrabold border-amber-500 scale-105 z-10 shadow-[0_0_15px_rgba(245,158,11,0.3)]"
                                            : "border-white/5 bg-black/20 text-muted-foreground hover:border-white/20 hover:text-white transition-colors"
                                    )}
                                >
                                    {val}%
                                </Button>
                            ))}
                        </div>
                    </div>

                    {/* Bet Amount */}
                    <div id="tutorial-bet" className="flex items-center gap-2 h-7 mb-0.5">
                        <div className="flex-1 relative">
                            <span className="absolute left-2 top-1.5 text-[10px] text-muted-foreground font-bold">BET</span>
                            <Input
                                data-testid="bet-amount-input"
                                type="number"
                                value={betAmount}
                                onChange={(e) => {
                                    setBetAmount(Number(e.target.value));
                                    setIsUserModified(true);
                                }}
                                className="h-7 pl-10 pr-2 text-xs font-mono bg-black/40 border-white/5 focus-visible:ring-primary/50 text-right"
                            />
                        </div>
                        <div className="flex gap-1 overflow-x-auto scrollbar-none pb-0.5">
                            {[0.01, 0.03, 0.05, 0.1, 0.2].map((p) => {
                                const isGuest = !user || user?.is_guest;
                                const currentPoints = isGuest ? guestPoints : userPoints;
                                let targetValue = Math.floor(currentPoints * p);
                                let label = `${p * 100}%`;
                                let isSpecialMin = false;

                                // Special case for 1% when points <= 1000
                                if (p === 0.01 && currentPoints <= 1000) {
                                    targetValue = 10;
                                    label = "10 pt";
                                    isSpecialMin = true;
                                }

                                const isActive = currentPoints > 0 && Math.abs(betAmount - targetValue) < 1;

                                return (
                                    <Button
                                        key={p}
                                        size="sm"
                                        variant="outline"
                                        onClick={() => {
                                            setBetAmount(Math.max(1, targetValue));
                                            setIsUserModified(true);
                                        }}
                                        className={cn(
                                            "h-7 px-1.5 text-[9px] transition-all border-2 rounded-md font-bold",
                                            isActive
                                                ? isSpecialMin
                                                    ? "bg-transparent text-white border-white scale-105 z-10 shadow-[0_0_15px_rgba(255,255,255,0.3)]"
                                                    : "bg-transparent text-amber-500 border-amber-500/50 scale-105 z-10 shadow-[0_0_15px_rgba(245,158,11,0.3)]"
                                                : "bg-white/5 text-muted-foreground border-white/5 hover:border-amber-500/50 hover:text-amber-400"
                                        )}
                                    >
                                        {label}{p === 0.2 && " (MAX)"}
                                    </Button>
                                );
                            })}
                        </div>
                    </div>

                </div>

                {/* 📊 Refactored Reward Structure Guide */}
                <div className="mx-3 mt-0.5 p-2 rounded-xl bg-black/40 border border-white/10 space-y-1.5 relative overflow-visible">
                    {/* Reward Cases */}
                    <div className="px-1 py-0.5 border-t border-white/5 bg-white/[0.01]">
                        {/* Label Row */}
                        <div className="text-[9px] font-black text-amber-500/80 uppercase tracking-[0.15em] mb-0.5 flex items-center gap-1.5">
                            <Sparkles className="w-2.5 h-2.5" />
                            Expected Reward
                        </div>

                        {/* Values Row */}
                        <div className="flex items-center justify-between text-[11px] font-bold">
                            <div className="text-gray-400 font-medium">
                                {userStreak || 0} streaks
                            </div>
                            <div className="flex items-center gap-4">
                                <div className="flex items-center gap-1.5 text-white">
                                    <span className="text-emerald-400 text-[10px] font-black">WIN</span>
                                    <span className="font-mono text-emerald-400">+{rewards.min}~{rewards.max}pts</span>
                                </div>
                                <div className="flex items-center gap-1.5 text-white">
                                    <span className="text-rose-400 text-[10px] font-black">LOSS</span>
                                    <span className="font-mono text-rose-400">-{betAmount}pts</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Bullet Points & Toggle Container */}
                    <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 space-y-1.5 px-0.5 text-gray-400">
                            <div className="flex items-center gap-2 text-[10px]">
                                <span className="text-xs">⏱</span>
                                <p className="font-medium">Longer time = Bigger rewards</p>
                            </div>
                            <div className="flex items-center gap-2 text-[10px]">
                                <span className="text-xs">📈</span>
                                <p className="font-medium">Bigger % target = Bigger bonus</p>
                            </div>
                            <div className="flex items-center gap-2 text-[10px]">
                                <span className="text-xs">🔥</span>
                                <p className="font-medium">Perfect streaks = Extra boost</p>
                            </div>
                        </div>

                        <div className="shrink-0 flex items-center h-full pt-1">
                            <Popover open={isDetailsOpen} onOpenChange={setIsDetailsOpen}>
                                <PopoverTrigger asChild>
                                    <div
                                        onMouseEnter={() => setIsDetailsOpen(true)}
                                        onMouseLeave={() => setIsDetailsOpen(false)}
                                        className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-white/5 border border-white/10 text-[9px] font-bold text-primary hover:bg-white/10 cursor-help transition-all whitespace-nowrap"
                                    >
                                        <Activity className="w-3 h-3" />
                                        Details
                                    </div>
                                </PopoverTrigger>
                                <PopoverContent
                                    side="top"
                                    align="center"
                                    sideOffset={8}
                                    onMouseEnter={() => setIsDetailsOpen(true)}
                                    onMouseLeave={() => setIsDetailsOpen(false)}
                                    className="w-80 p-0 bg-transparent border-none shadow-none z-[100]"
                                >
                                    <div className="bg-[#0f0f15] border border-primary/40 rounded-xl p-4 shadow-[0_20px_50px_rgba(0,0,0,0.9)] backdrop-blur-2xl animate-in fade-in zoom-in-95 duration-200">
                                        <div className="text-[11px] font-black text-primary mb-3 uppercase tracking-widest flex items-center gap-2 border-b border-primary/20 pb-2">
                                            <Trophy className="w-3 h-3" /> Reward System
                                        </div>

                                        <div className="space-y-3.5 text-left">
                                            <div className="space-y-1">
                                                <div className="text-[10px] font-bold text-white uppercase tracking-tighter">Direction Win</div>
                                                <div className="text-[10px] text-muted-foreground leading-relaxed pl-1">
                                                    80% of bet × <span className="text-primary">Zone multiplier</span>
                                                </div>
                                            </div>

                                            <div className="space-y-2 py-2 border-y border-white/5">
                                                <div className="text-[9px] font-bold text-muted-foreground uppercase tracking-widest text-center mb-1">Reward Decay Zones</div>

                                                {/* Visual Zone Bar */}
                                                <div className="h-6 w-full flex rounded-md overflow-hidden border border-white/10 mb-1">
                                                    <div className="h-full bg-emerald-500/30 border-r border-white/10 flex items-center justify-center relative group" style={{ width: '33.33%' }}>
                                                        <span className="text-[9px] font-black text-emerald-400">1.0x</span>
                                                        <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-emerald-500 text-black text-[7px] font-black px-1.5 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">GREEN ZONE</div>
                                                    </div>
                                                    <div className="h-full bg-amber-500/30 border-r border-white/10 flex items-center justify-center relative group" style={{ width: '33.33%' }}>
                                                        <span className="text-[9px] font-black text-amber-400">0.6x</span>
                                                        <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-amber-500 text-black text-[7px] font-black px-1.5 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">YELLOW ZONE</div>
                                                    </div>
                                                    <div className="h-full bg-rose-500/20 border-r border-white/10 flex items-center justify-center relative group" style={{ width: '23.34%' }}>
                                                        <span className="text-[9px] font-black text-rose-400">0.3x</span>
                                                        <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-rose-500 text-black text-[7px] font-black px-1.5 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">RED ZONE</div>
                                                    </div>
                                                    <div className="h-full bg-gray-900 flex items-center justify-center relative group" style={{ width: '10%' }}>
                                                        <Lock className="w-2.5 h-2.5 text-gray-600" />
                                                        <div className="absolute -top-7 left-1/2 -translate-x-1/2 bg-gray-700 text-white text-[7px] font-black px-1.5 py-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">LOCKED</div>
                                                    </div>
                                                </div>

                                                {/* Scale Labels - Precisely centered on dividers */}
                                                <div className="relative h-2.5 w-full text-[7px] text-muted-foreground font-mono font-bold leading-none">
                                                    <span className="absolute left-0">0%</span>
                                                    <span className="absolute left-[33.33%] -translate-x-1/2">33%</span>
                                                    <span className="absolute left-[66.66%] -translate-x-1/2">66%</span>
                                                    <span className="absolute left-[90%] -translate-x-1/2">90%</span>
                                                    <span className="absolute right-0 text-gray-500 font-black">100%</span>
                                                </div>
                                            </div>

                                            <div className="grid grid-cols-2 gap-4">
                                                <div className="space-y-1">
                                                    <div className="text-[10px] font-bold text-white uppercase tracking-tighter">Target Hit</div>
                                                    <div className="text-[10px] text-muted-foreground leading-relaxed pl-1">
                                                        Extra fixed Target Bonus paid
                                                    </div>
                                                </div>

                                                <div className="space-y-1">
                                                    <div className="text-[10px] font-bold text-white uppercase tracking-tighter">Loss</div>
                                                    <div className="text-[10px] text-rose-400/80 leading-relaxed pl-1">
                                                        ```
                                                        Max loss is the full bet amount
                                                    </div>
                                                </div>
                                            </div>

                                            <div className="pt-1.5 space-y-1.5 border-t border-white/5">
                                                <div className="flex items-center gap-1.5 text-[10px] font-bold text-amber-500 uppercase tracking-tighter">
                                                    <Sparkles className="w-3 h-3 animate-pulse" /> Win Streak Bonus 🔥
                                                </div>
                                                <div className="text-[10px] text-muted-foreground leading-relaxed italic pl-3 border-l-2 border-amber-500/20">
                                                    Bonus increases on consecutive wins.<br />
                                                    <span className="text-emerald-400/90 font-bold">Only GREEN zone bets count toward streaks.</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </PopoverContent>
                            </Popover>
                        </div>
                    </div>

                </div>

                {/* Locked Betting Area */}
                <CardContent className={cn(
                    "space-y-1 p-2 pt-0 flex-1 flex flex-col justify-center transition-opacity duration-300",
                    (isLocked || isAlreadyBet) && "opacity-50 pointer-events-none grayscale"
                )}>
                    {/* Direction */}
                    {/* 📈 UP/DOWN Buttons - Enhanced Design */}
                    <div id="tutorial-direction" className="grid grid-cols-2 gap-2 h-9 mt-1">
                        <Button
                            data-testid="btn-up"
                            onClick={() => setSelectedDirection("UP")}
                            className={cn(
                                "h-full text-sm font-bold border-2 transition-all relative overflow-hidden group",
                                selectedDirection === "UP"
                                    ? "bg-emerald-500/20 border-emerald-500 text-emerald-400 shadow-[0_0_20px_rgba(16,185,129,0.3)]"
                                    : "bg-black/40 text-emerald-500 border-emerald-500/30 hover:border-emerald-500/50 hover:bg-emerald-500/5"
                            )}
                        >
                            <span className="relative z-10 flex items-center gap-1">
                                <ArrowUp className="w-4 h-4" /> UP
                            </span>
                            {selectedDirection === "UP" && <div className="absolute inset-0 bg-emerald-500/10 animate-pulse" />}
                        </Button>
                        <Button
                            data-testid="btn-down"
                            onClick={() => setSelectedDirection("DOWN")}
                            className={cn(
                                "h-full text-sm font-bold border-2 transition-all relative overflow-hidden group",
                                selectedDirection === "DOWN"
                                    ? "bg-red-500/20 border-red-500 text-red-400 shadow-[0_0_20px_rgba(239,68,68,0.3)]"
                                    : "bg-black/40 text-red-500 border-red-500/30 hover:border-red-500/50 hover:bg-red-500/5"
                            )}
                        >
                            <span className="relative z-10 flex items-center gap-1">
                                <ArrowDown className="w-4 h-4" /> DOWN
                            </span>
                            {selectedDirection === "DOWN" && <div className="absolute inset-0 bg-red-500/10 animate-pulse" />}
                        </Button>
                    </div>

                    {!user && (
                        <div className="mb-2.5 flex justify-center">
                            <span className="text-[10px] font-bold text-primary/80 bg-primary/10 border border-primary/20 px-2.5 py-0.5 rounded-full flex items-center gap-1.5 shadow-[0_0_10px_rgba(var(--primary),0.1)]">
                                <Sparkles className="w-3 h-3" />
                                Sign up later to keep your points & history!
                            </span>
                        </div>
                    )}

                    <Button
                        id="tutorial-submit"
                        data-testid="submit-prediction"
                        onClick={handleSubmitPrediction}
                        disabled={isSubmitting || !selectedDirection || !selectedPercent || !marketStatus.isOpen || isLocked || isAlreadyBet}
                        className={cn(
                            "w-full h-8 text-xs font-bold transition-all mt-0",
                            (!marketStatus.isOpen || isAlreadyBet || isLocked)
                                ? "bg-gray-800 text-gray-400 border border-white/10 cursor-not-allowed"
                                : "bg-primary hover:bg-primary/90 shadow-[0_0_20px_rgba(var(--primary),0.4)] hover:scale-[1.02] text-black"
                        )}
                    >
                        {isSubmitting ? (
                            <Loader2 className="animate-spin w-3 h-3" />
                        ) : !marketStatus.isOpen ? (
                            <span className="flex items-center gap-2">
                                MARKET CLOSED <span className="text-[9px] opacity-70 font-normal">({marketStatus.reason?.replace('Market Closed ', '')})</span>
                            </span>
                        ) : isLocked ? (
                            <span className="flex items-center gap-2">
                                ROUND LOCKED <Timer className="w-3 h-3" />
                            </span>
                        ) : !user ? (
                            <span className="flex items-center gap-2">
                                TRY GUEST FORECAST <ArrowRight className="w-3 h-3" />
                            </span>
                        ) : isAlreadyBet ? (
                            <span className="flex items-center gap-2">
                                ALREADY PARTICIPATED <Trophy className="w-3 h-3 text-yellow-500" />
                            </span>
                        ) : (
                            `FORECAST (-${betAmount} pts)`
                        )}


                    </Button>
                </CardContent>
            </div>
        </Card >
    );
}
