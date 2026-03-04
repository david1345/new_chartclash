"use client";

import dynamic from "next/dynamic";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import dayjs from "dayjs";
import "dayjs/locale/en";
dayjs.locale("en");
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Trophy, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import { User } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/client";
import { useGuestPredictions } from "@/providers/guest-prediction-provider";
import { ASSETS, Asset } from "@/lib/constants";
import { isMarketOpen } from "@/lib/market-hours";
import { calculateReward } from "@/lib/rewards";

// Refactored Components
import { MarketHeader, MarketHero } from "@/components/dashboard/market-header";
import { PredictionTabs } from "@/components/dashboard/prediction-tabs";
import { DesktopActivePosition } from "@/components/battle/desktop-active-position";

// Custom Hooks
import { usePredictionLock } from "@/hooks/dashboard/use-prediction-lock";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";
import { usePredictionHistory } from "@/hooks/dashboard/use-prediction-history";
import { useRoomFeed } from "@/hooks/dashboard/use-room-feed";
import { useMounted } from "@/hooks/use-mounted";
import { useGuestPrediction } from "@/hooks/dashboard/use-guest-prediction";

// Dynamic Imports for Heavy Components
const TradingViewWidget = dynamic(() => import("@/components/chart/tradingview-widget"), {
    ssr: false,
    loading: () => <div className="h-full w-full bg-black/40 animate-pulse flex items-center justify-center text-muted-foreground italic text-sm">Loading Chart...</div>
});

const OrderPanel = dynamic(() => import("@/components/dashboard/order-panel").then(mod => mod.OrderPanel), {
    ssr: false,
    loading: () => <div className="h-[400px] w-full bg-card/40 border border-white/5 rounded-2xl animate-pulse" />
});

const StatsPanel = dynamic(() => import("@/components/dashboard/stats-panel").then(mod => mod.StatsPanel), {
    ssr: false,
    loading: () => <div className="h-full w-full bg-card/40 border border-white/5 rounded-2xl animate-pulse" />
});

const SocialFeed = dynamic(() => import("@/components/dashboard/social-feed").then(mod => mod.SocialFeed), {
    ssr: false,
    loading: () => <div className="h-full w-full bg-card/40 border border-white/5 rounded-2xl animate-pulse" />
});

const EntertainmentHub = dynamic(() => import("@/components/dashboard/entertainment-hub").then(mod => mod.EntertainmentHub), {
    ssr: false
});

const TutorialOverlay = dynamic(() => import("@/components/tutorial/tutorial-overlay").then(mod => mod.TutorialOverlay), {
    ssr: false
});

interface AppUser {
    id: string;
    email?: string;
    user_metadata?: {
        avatar_url?: string;
        full_name?: string;
        display_name?: string;
    };
    is_guest?: boolean;
}

export function PlayContent() {
    const params = useParams();
    const router = useRouter();
    const symbolParam = params.symbol as string;
    const timeframeParam = params.timeframe as string;

    const allAssets = Object.values(ASSETS).flat();
    const initialAsset = allAssets.find(a => a.symbol === symbolParam) || ASSETS.CRYPTO[0];

    const [user, setUser] = useState<AppUser | null>(null);
    const [isGhostMode, setIsGhostMode] = useState(false);

    // Local UI State - Lifted for Orchestration
    const [selectedAsset, setSelectedAsset] = useState<Asset>(initialAsset);
    const [selectedTimeframe, setSelectedTimeframe] = useState(timeframeParam || "1h");
    const [isEntertainmentHubOpen, setIsEntertainmentHubOpen] = useState(false);
    const [isGuestResolutionOpen, setIsGuestResolutionOpen] = useState(false);
    const [resolvedGuestPrediction, setResolvedGuestPrediction] = useState<any | null>(null);

    // Guest Migration State
    const [isGuestMigrationModalOpen, setIsGuestMigrationModalOpen] = useState(false);
    const [migrationPoints, setMigrationPoints] = useState(1000);
    const [migrationPredictions, setMigrationPredictions] = useState<any[]>([]);
    const [transferPoints, setTransferPoints] = useState(true);
    const [transferHistory, setTransferHistory] = useState(true);
    const [isMigrating, setIsMigrating] = useState(false);

    // Global Market Data
    const [roundOpenPrice, setRoundOpenPrice] = useState<number | null>(null);

    const mounted = useMounted();

    const supabase = createClient();

    const { guestPredictions, guestPoints, guestId, resolveGuestPrediction, clearGuestPredictions } = useGuestPredictions();

    // Sync state with URL params if they change externally
    useEffect(() => {
        if (symbolParam && symbolParam !== selectedAsset.symbol) {
            const asset = allAssets.find(a => a.symbol === symbolParam);
            if (asset) setSelectedAsset(asset);
        }
        if (timeframeParam && timeframeParam !== selectedTimeframe) {
            setSelectedTimeframe(timeframeParam);
        }
    }, [symbolParam, timeframeParam]);

    // Handle asset/timeframe changes by updating URL
    const handleAssetChange = (asset: Asset) => {
        setSelectedAsset(asset);
        router.push(`/play/${asset.symbol}/${selectedTimeframe}`);
    };

    const handleTimeframeChange = (tf: string) => {
        setSelectedTimeframe(tf);
        router.push(`/play/${selectedAsset.symbol}/${tf}`);
    };

    // Fetch initial reference price for the layout components
    useEffect(() => {
        const fetchInitialPrice = async () => {
            try {
                const res = await fetch("/api/market/entry-price", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ symbol: selectedAsset.symbol, timeframe: selectedTimeframe, type: selectedAsset.type })
                });
                const json = await res.json();
                if (json.success && json.data) {
                    if (json.data.openPrice !== undefined) setRoundOpenPrice(json.data.openPrice);
                }
            } catch (e) {
                console.error("Server price API error", e);
            }
        };
        fetchInitialPrice();
    }, [selectedAsset.symbol, selectedTimeframe, selectedAsset.type]);

    useEffect(() => {
        supabase.auth.getUser().then(({ data }) => {
            const realUser = data.user as User;

            // Admin Impersonation (Ghost Mode)
            const searchParams = new URLSearchParams(typeof window !== 'undefined' ? window.location.search : '');
            const impersonateId = searchParams.get('impersonate') || (typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null);

            if (impersonateId && realUser?.email === 'sjustone000@gmail.com') {
                console.log("[ADMIN] GHOST MODE ACTIVE FOR", impersonateId);
                setIsGhostMode(true);
                if (typeof window !== 'undefined') {
                    sessionStorage.setItem('ghost_target_id', impersonateId);
                }

                const fetchTargetUser = async () => {
                    const { data: pData, error: pError } = await supabase
                        .from('profiles')
                        .select('*')
                        .eq('id', impersonateId)
                        .maybeSingle();

                    if (pData) {
                        setUser({
                            id: pData.id,
                            email: 'impersonated@chartclash.app',
                            user_metadata: { display_name: pData.username }
                        } as any);
                    }
                    if (pError) console.error("[ADMIN] Profile fetch error:", pError);
                };
                fetchTargetUser();
            } else if (realUser) {
                if (typeof window !== 'undefined' && !searchParams.get('impersonate')) {
                    sessionStorage.removeItem('ghost_target_id');
                }
                setIsGhostMode(false);
                setUser(realUser);
            } else {
                // GUEST MODE
                if (typeof window !== 'undefined' && !searchParams.get('impersonate')) {
                    sessionStorage.removeItem('ghost_target_id');
                }
                setIsGhostMode(false);
                setUser({
                    id: guestId,
                    email: 'guest@chartclash.app',
                    user_metadata: { display_name: `Guest_${guestId.substring(0, 5)}` },
                    is_guest: true
                } as any);
            }
        });
    }, [supabase, guestId]);
    // Check for pending guest data to migrate
    useEffect(() => {
        if (user && !user.is_guest && typeof window !== 'undefined') {
            const hasCompletedMigration = localStorage.getItem("chartclash_migration_completed");
            const isTransitioning = localStorage.getItem("chartclash_is_transitioning") === "true";

            if (hasCompletedMigration !== "true" && isTransitioning) {
                const storedPointsStr = localStorage.getItem("chartclash_guest_points");
                const storedPredsStr = localStorage.getItem("chartclash_guest_predictions");

                if (storedPointsStr || storedPredsStr) {
                    const points = storedPointsStr ? Number(storedPointsStr) : 1000;
                    let preds = [];
                    try { preds = storedPredsStr ? JSON.parse(storedPredsStr) : []; } catch (e) { }

                    if (preds.length > 0 || points !== 1000) {
                        setMigrationPoints(points);
                        setMigrationPredictions(preds);
                        setIsGuestMigrationModalOpen(true);
                    }
                }
            }
        }
    }, [user]);

    // --- HOOKS INTEGRATION ---
    const { isLocked, serverTimeOffset } = usePredictionLock({
        timeframe: selectedTimeframe,
        selectedAssetSymbol: selectedAsset.symbol
    });

    const { userPoints, setUserPoints, userStreak, username, userRank, fetchUserStats, isLoaded, activeCount } = useUserStats(user);
    const { predictions, fetchPredictions } = usePredictionHistory(user);
    const { feed, fetchFeed } = useRoomFeed({
        assetSymbol: selectedAsset.symbol,
        timeframe: selectedTimeframe,
        currentUserId: user?.id
    });

    const marketStatus = isMarketOpen(selectedAsset.symbol, selectedAsset.type);

    const adjustedNow = Date.now() + serverTimeOffset;

    // Debugging active prediction state for guests
    if (!user && mounted && guestPredictions?.length > 0) {
        console.log("Guest Predictions check:", {
            guestPredictionsCount: guestPredictions.length,
            adjustedNow,
            selectedAsset: selectedAsset.symbol,
            selectedTimeframe: selectedTimeframe,
            firstPredClose: guestPredictions[0]?.candle_close_at,
            firstPredCloseTime: new Date(guestPredictions[0]?.candle_close_at).getTime()
        });
    }

    const isAlreadyBet = mounted && (
        predictions.some(p =>
            p.status === 'pending' &&
            p.asset_symbol === selectedAsset.symbol &&
            p.timeframe === selectedTimeframe &&
            new Date(p.candle_close_at).getTime() > adjustedNow - 1000 // Buffer for clock jitter
        ) ||
        (!user && guestPredictions?.some(p => p.status === 'pending' &&
            p.asset_symbol === selectedAsset.symbol &&
            p.timeframe === selectedTimeframe &&
            new Date(p.candle_close_at).getTime() > adjustedNow - 1000 // Buffer for clock jitter
        ))
    );

    const activePrediction = mounted ? (
        predictions.find(p =>
            p.status === 'pending' &&
            p.asset_symbol === selectedAsset.symbol &&
            p.timeframe === selectedTimeframe &&
            new Date(p.candle_close_at).getTime() > adjustedNow - 1000
        ) ||
        (!user && guestPredictions?.find(p => p.status === 'pending' &&
            p.asset_symbol === selectedAsset.symbol &&
            p.timeframe === selectedTimeframe &&
            new Date(p.candle_close_at).getTime() > adjustedNow - 1000 // Buffer for clock jitter
        )) || null
    ) : null;

    const isAIBeatEnabled = process.env.NEXT_PUBLIC_ENABLE_AI_BEAT === 'true';

    // Guest Resolution Effect
    useEffect(() => {
        if (user || !guestPredictions || guestPredictions.length === 0) return;

        const checkResolution = async () => {
            const now = Date.now();

            for (const pred of guestPredictions) {
                if (pred.status !== 'pending') continue;

                const closeTime = new Date(pred.candle_close_at).getTime();

                if (now > closeTime + 10000) { // 10s buffer
                    try {
                        const res = await fetch("/api/market/entry-price", {
                            method: "POST",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify({
                                symbol: pred.asset_symbol,
                                timeframe: pred.timeframe,
                                type: selectedAsset.type // Approximate
                            })
                        });
                        const json = await res.json();
                        if (json.success && json.data?.openPrice) {
                            const resolved = resolveGuestPrediction(pred.id, json.data.openPrice);
                            if (resolved) {
                                setResolvedGuestPrediction(resolved);
                                setIsGuestResolutionOpen(true);
                            }
                        }
                    } catch (e) {
                        console.error("Guest resolution fetch failed", e);
                    }
                }
            }
        };

        const timer = setInterval(checkResolution, 10000);
        return () => clearInterval(timer);
    }, [user, guestPredictions, resolveGuestPrediction, selectedAsset.type]);

    // Migration Handler
    const handleMigrateGuestData = async () => {
        if (!user) return;
        setIsMigrating(true);
        try {
            const { data, error } = await supabase.rpc('migrate_guest_data', {
                p_user_id: user.id,
                p_guest_points: Math.max(1000, migrationPoints), // Round up to 1000 if lost points (Point 1)
                p_guest_predictions: migrationPredictions,
                p_transfer_points: transferPoints,
                p_transfer_history: transferHistory
            });

            if (error) throw error;

            // Clear local cache completely and mark as permanently completed
            localStorage.setItem("chartclash_migration_completed", "true");
            localStorage.removeItem("chartclash_guest_points");
            localStorage.removeItem("chartclash_guest_predictions");
            localStorage.removeItem("chartclash_is_transitioning"); // Clear flag on success
            clearGuestPredictions(); // Provider clear too

            toast.success("Guest progress saved successfully! Good luck.");
            setIsGuestMigrationModalOpen(false);

            // Refresh stats and history so UI updates immediately
            fetchUserStats();
            fetchPredictions();

        } catch (error) {
            console.error(error);
            toast.error("Failed to migrate guest data.");
        } finally {
            setIsMigrating(false);
        }
    };

    // Dismiss Migration (burn guest data without saving)
    const handleDismissMigration = () => {
        localStorage.setItem("chartclash_migration_completed", "true");
        localStorage.removeItem("chartclash_is_transitioning");
        localStorage.removeItem("chartclash_guest_points");
        localStorage.removeItem("chartclash_guest_predictions");
        clearGuestPredictions();
        setIsGuestMigrationModalOpen(false);
    };

    return (
        <main className="min-h-screen bg-[#060609] text-white selection:bg-primary/30">
            <MarketHeader
                user={user}
                username={username}
                userPoints={user ? userPoints : guestPoints}
                userRank={userRank}
                activeCount={user ? activeCount : guestPredictions.filter(p => p.status === 'pending').length}
                isGhostMode={isGhostMode}
            />

            <div className="container mx-auto px-2 lg:px-4 py-2 lg:py-6 space-y-2 lg:space-y-4 max-w-6xl">

                <section className="grid grid-cols-1 lg:grid-cols-12 gap-2 lg:gap-4 items-stretch lg:h-[calc(100vh-80px)] overflow-hidden lg:-mt-2 bg-[#080C14]">
                    {/* LEFT PANEL / Mobile Top (Order Panel) */}
                    <div className="lg:col-span-3 h-full flex flex-col gap-2 lg:gap-3 min-h-0 order-1 lg:order-1 pt-2 lg:pt-0 mb-2 lg:mb-0 pb-safe">
                        <OrderPanel
                            user={user}
                            userPoints={userPoints}
                            userStreak={userStreak}
                            setUserPoints={setUserPoints}
                            selectedAsset={selectedAsset}
                            setSelectedAsset={handleAssetChange}
                            selectedTimeframe={selectedTimeframe}
                            setSelectedTimeframe={handleTimeframeChange}
                            marketStatus={marketStatus}
                            isLocked={isLocked}
                            isAlreadyBet={isAlreadyBet}
                            activePrediction={activePrediction}
                            refreshPredictions={fetchPredictions}
                            fetchUserStats={fetchUserStats}
                            isLoaded={isLoaded}
                            roundOpenPrice={roundOpenPrice}
                            serverTimeOffset={serverTimeOffset}
                            onBetSuccess={() => setIsEntertainmentHubOpen(true)}
                        />
                    </div>

                    {/* CENTER PANEL / Mobile Bottom Chart */}
                    <div className="lg:col-span-6 h-full flex flex-col gap-2 lg:gap-3 min-h-0 order-2 lg:order-2 h-[240px] lg:h-full shrink-0 mb-20 lg:mb-0">
                        <Card className="flex-1 w-full border-[#1E2D45] bg-[#0F1623] overflow-hidden flex flex-col relative group rounded-2xl shadow-xl">
                            <div className="absolute top-4 left-4 z-10 bg-[#141D2E]/80 backdrop-blur-md border border-[#1E2D45] px-3 py-1.5 rounded-xl flex items-center gap-2">
                                <div className="w-2 h-2 rounded-full bg-[#00E5B4] animate-pulse"></div>
                                <span className="text-[#00E5B4] font-bold text-xs">1H &middot; BTC/USDT</span>
                            </div>
                            <div className="flex-1 w-full h-full relative">
                                <TradingViewWidget
                                    symbol={selectedAsset.symbol}
                                    interval={selectedTimeframe}
                                    theme="dark"
                                />
                                <div className="absolute inset-0 pointer-events-none shadow-[inset_0_0_80px_rgba(8,12,20,0.8)]" />
                            </div>
                        </Card>

                        {/* Mobile Only: Order History Box */}
                        <div className="flex lg:hidden flex-col flex-1 shrink-0 mt-2">
                            <PredictionTabs predictions={predictions} user={user} />
                        </div>
                    </div>

                    {/* RIGHT PANEL / Desktop Only Data */}
                    <div className="hidden lg:flex lg:col-span-3 h-full flex-col gap-3 min-h-0 order-3 overflow-y-auto no-scrollbar">
                        {activePrediction && (
                            <DesktopActivePosition
                                activePrediction={activePrediction}
                                currentPrice={roundOpenPrice}
                            />
                        )}
                        <PredictionTabs predictions={predictions} user={user} />
                        <div className="grid grid-cols-1 gap-3 shrink-0 flex-1">
                            <StatsPanel
                                assetSymbol={selectedAsset.symbol}
                                timeframe={selectedTimeframe}
                            />
                            <SocialFeed
                                feed={feed}
                                selectedAsset={selectedAsset}
                                user={user}
                                refreshFeed={fetchFeed}
                            />
                        </div>
                    </div>
                </section>
            </div>

            <div className="fixed bottom-4 right-4 z-50">
                <TutorialOverlay />
                {isAIBeatEnabled && (
                    <EntertainmentHub
                        open={isEntertainmentHubOpen}
                        onOpenChange={setIsEntertainmentHubOpen}
                    />
                )}

                {/* Guest Resolution Modal */}
                {isGuestResolutionOpen && resolvedGuestPrediction && (
                    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300">
                        <Card className="max-w-md w-full border-primary/50 bg-[#0f0f15] shadow-[0_0_50px_rgba(var(--primary),0.2)] p-6 space-y-6">
                            <div className="text-center space-y-2">
                                <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4 border border-primary/40">
                                    <Trophy className={cn("w-8 h-8", resolvedGuestPrediction.status === 'WIN' ? "text-yellow-500" : "text-gray-500")} />
                                </div>
                                <h2 className="text-2xl font-black italic tracking-tighter uppercase text-emerald-400">
                                    {resolvedGuestPrediction.status === 'WIN' ? 'Victory! You Nailed It' : 'Round Finished!'}
                                </h2>
                                <p className="text-muted-foreground text-sm">
                                    Your prediction for {resolvedGuestPrediction.asset_symbol} was {resolvedGuestPrediction.status === 'WIN' ? 'spot on' : 'resolved'}. You&apos;ve experienced the clash – now make it real!
                                </p>
                            </div>

                            <div className="bg-white/5 rounded-xl p-4 border border-white/10 space-y-3">
                                <div className="flex justify-between text-xs">
                                    <span className="text-muted-foreground uppercase font-bold tracking-tighter">Entry Price</span>
                                    <span className="font-mono">${resolvedGuestPrediction.entry_price?.toLocaleString()}</span>
                                </div>
                                <div className="flex justify-between text-xs">
                                    <span className="text-muted-foreground uppercase font-bold tracking-tighter">Exit Price</span>
                                    <span className="font-mono">${resolvedGuestPrediction.actual_price?.toLocaleString()}</span>
                                </div>
                                <div className="flex justify-between border-t border-white/10 pt-2">
                                    <span className="text-xs font-black uppercase tracking-widest">Result</span>
                                    <span className={cn("text-xs font-black", resolvedGuestPrediction.profit! > 0 ? "text-emerald-400" : "text-rose-400")}>
                                        {resolvedGuestPrediction.profit! > 0 ? `+${resolvedGuestPrediction.profit} PTS` : `${resolvedGuestPrediction.profit} PTS`}
                                    </span>
                                </div>
                            </div>

                            <div className="flex flex-col gap-3 pt-2">
                                <Link href="/login" className="w-full">
                                    <Button
                                        onClick={() => {
                                            if (typeof window !== 'undefined') {
                                                localStorage.setItem('chartclash_is_transitioning', 'true');
                                            }
                                        }}
                                        className="w-full bg-primary text-black font-black uppercase tracking-widest hover:scale-[1.02] transition-transform"
                                    >
                                        Sign up to save your progress
                                    </Button>
                                </Link>
                                <Button
                                    variant="ghost"
                                    onClick={() => {
                                        setIsGuestResolutionOpen(false);
                                        setResolvedGuestPrediction(null);
                                    }}
                                    className="text-[10px] text-muted-foreground hover:text-white uppercase font-bold tracking-widest"
                                >
                                    Dismiss and Try Again
                                </Button>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => {
                                        setIsGuestResolutionOpen(false);
                                        setResolvedGuestPrediction(null);
                                        clearGuestPredictions();
                                    }}
                                    className="text-[10px] text-rose-500/50 hover:text-rose-400 -mt-2"
                                >
                                    Reset Guest Data
                                </Button>
                            </div>
                        </Card>
                    </div>
                )}

                {/* Guest Migration Modal (Post Login) */}
                {isGuestMigrationModalOpen && (
                    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300">
                        <Card className="max-w-md w-full border-primary/50 bg-[#0f0f15] shadow-[0_0_50px_rgba(var(--primary),0.2)] p-6 space-y-6">
                            <div className="text-center space-y-2">
                                <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4 border border-primary/40">
                                    <Sparkles className="w-8 h-8 text-primary" />
                                </div>
                                <h2 className="text-2xl font-black italic tracking-tighter uppercase text-white">
                                    Welcome Aboard
                                </h2>
                                <p className="text-muted-foreground text-sm">
                                    We found your guest progress. Would you like to keep your DEMO points and history?
                                </p>
                            </div>

                            <div className="bg-white/5 rounded-xl p-4 border border-white/10 space-y-4">
                                {/* Transfer History Option */}
                                <label className="flex items-start gap-3 cursor-pointer group">
                                    <div className="mt-0.5 flex-shrink-0">
                                        <input
                                            type="checkbox"
                                            checked={transferHistory}
                                            onChange={(e) => setTransferHistory(e.target.checked)}
                                            className="w-4 h-4 rounded border-white/20 bg-black/50 text-primary focus:ring-primary/50"
                                        />
                                    </div>
                                    <div className="space-y-1">
                                        <span className={cn("text-sm font-bold block transition-colors", transferHistory ? "text-white" : "text-muted-foreground")}>
                                            Keep My Predictions ({migrationPredictions.length})
                                        </span>
                                        <span className="text-[10px] text-muted-foreground block leading-tight">
                                            Transfer all your guest bets directly into your permanent History tab.
                                        </span>
                                    </div>
                                </label>

                                {/* Transfer Points Option */}
                                <label className="flex items-start gap-3 cursor-pointer group pt-3 border-t border-white/10">
                                    <div className="mt-0.5 flex-shrink-0">
                                        <input
                                            type="checkbox"
                                            checked={transferPoints}
                                            onChange={(e) => setTransferPoints(e.target.checked)}
                                            className="w-4 h-4 rounded border-white/20 bg-black/50 text-primary focus:ring-primary/50"
                                        />
                                    </div>
                                    <div className="space-y-1">
                                        <span className={cn("text-sm font-bold block transition-colors", transferPoints ? "text-white" : "text-muted-foreground")}>
                                            Keep My DEMO Balance ({migrationPoints} pts)
                                        </span>
                                        <span className="text-[10px] text-muted-foreground block leading-tight">
                                            {migrationPoints <= 1000
                                                ? "Since your balance is below 1,000, we'll generously round it back up to 1,000 pts if you check this!"
                                                : "Start your real journey ahead of the pack with your hard-earned guest points."}
                                        </span>
                                    </div>
                                </label>
                            </div>

                            <div className="flex flex-col gap-3 pt-2">
                                <Button
                                    onClick={handleMigrateGuestData}
                                    disabled={isMigrating}
                                    className="w-full bg-primary text-black font-black uppercase tracking-widest hover:scale-[1.02] transition-transform"
                                >
                                    {isMigrating ? "Saving..." : "Start Trading"}
                                </Button>
                                <Button
                                    variant="ghost"
                                    onClick={handleDismissMigration}
                                    disabled={isMigrating}
                                    className="text-[10px] text-muted-foreground hover:text-white uppercase font-bold tracking-widest"
                                >
                                    No, start entirely fresh
                                </Button>
                            </div>
                        </Card>
                    </div>
                )}
            </div>
        </main>
    );
}
