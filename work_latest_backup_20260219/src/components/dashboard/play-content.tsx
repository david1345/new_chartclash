"use client";

import dynamic from "next/dynamic";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import dayjs from "dayjs";
import "dayjs/locale/en";
dayjs.locale("en");
import { Card } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";
import { ASSETS, Asset } from "@/lib/constants";
import { isMarketOpen } from "@/lib/market-hours";

// Refactored Components
import { MarketHeader, MarketHero } from "@/components/dashboard/market-header";
import { PredictionTabs } from "@/components/dashboard/prediction-tabs";

// Custom Hooks
import { usePredictionLock } from "@/hooks/dashboard/use-prediction-lock";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";
import { usePredictionHistory } from "@/hooks/dashboard/use-prediction-history";
import { useRoomFeed } from "@/hooks/dashboard/use-room-feed";

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

interface User {
    id: string;
    email?: string;
    user_metadata?: {
        avatar_url?: string;
        full_name?: string;
        display_name?: string;
    };
}

export function PlayContent() {
    const params = useParams();
    const router = useRouter();
    const symbolParam = params.symbol as string;
    const timeframeParam = params.timeframe as string;

    const allAssets = Object.values(ASSETS).flat();
    const initialAsset = allAssets.find(a => a.symbol === symbolParam) || ASSETS.CRYPTO[0];

    const [user, setUser] = useState<User | null>(null);
    const [isGhostMode, setIsGhostMode] = useState(false);

    // Local UI State - Lifted for Orchestration
    const [selectedAsset, setSelectedAsset] = useState<Asset>(initialAsset);
    const [selectedTimeframe, setSelectedTimeframe] = useState(timeframeParam || "1h");
    const [isEntertainmentHubOpen, setIsEntertainmentHubOpen] = useState(false);
    const [mounted, setMounted] = useState(false);

    const supabase = createClient();

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

    useEffect(() => {
        setMounted(true);
        supabase.auth.getUser().then(({ data }) => {
            const realUser = data.user as User;

            // Admin Impersonation (Ghost Mode)
            const searchParams = new URLSearchParams(typeof window !== 'undefined' ? window.location.search : '');
            const impersonateId = searchParams.get('impersonate') || (typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null);

            if (impersonateId && realUser?.email === 'sjustone000@gmail.com') {
                console.log("👻 DASHBOARD: GHOST MODE ACTIVE FOR", impersonateId);
                setIsGhostMode(true);
                if (typeof window !== 'undefined') {
                    sessionStorage.setItem('ghost_target_id', impersonateId);
                }

                const fetchTargetUser = async () => {
                    const { data: profile, error: pError } = await supabase
                        .from('profiles')
                        .select('username, email')
                        .eq('id', impersonateId)
                        .maybeSingle();

                    if (pError) console.error("❌ Profile fetch error:", pError);

                    setUser({
                        id: impersonateId,
                        email: profile?.email || "No Email Found",
                        user_metadata: {
                            display_name: profile?.username || "Ghost Target"
                        }
                    } as User);
                };
                fetchTargetUser();
            } else {
                if (typeof window !== 'undefined' && !searchParams.get('impersonate')) {
                    sessionStorage.removeItem('ghost_target_id');
                }
                setIsGhostMode(false);
                setUser(realUser);
            }
        });
    }, []);

    // --- HOOKS INTEGRATION ---
    const { isLocked } = usePredictionLock({
        timeframe: selectedTimeframe,
        selectedAssetSymbol: selectedAsset.symbol
    });

    const { userPoints, setUserPoints, userStreak, username, userRank, fetchUserStats, isLoaded } = useUserStats(user);
    const { predictions, fetchPredictions } = usePredictionHistory(user);
    const { feed, fetchFeed } = useRoomFeed({
        assetSymbol: selectedAsset.symbol,
        timeframe: selectedTimeframe,
        currentUserId: user?.id
    });

    const marketStatus = isMarketOpen(selectedAsset.symbol, selectedAsset.type);

    const isAlreadyBet = predictions.some(p =>
        p.status === 'pending' &&
        p.asset_symbol === selectedAsset.symbol &&
        p.timeframe === selectedTimeframe &&
        new Date(p.candle_close_at).getTime() > Date.now()
    );

    const isAIBeatEnabled = process.env.NEXT_PUBLIC_ENABLE_AI_BEAT === 'true';

    return (
        <main className="min-h-screen bg-[#060609] text-white selection:bg-primary/30">
            <MarketHeader
                user={user}
                username={username}
                userPoints={userPoints}
                userRank={userRank}
                mounted={mounted}
                isGhostMode={isGhostMode}
            />

            <div className="container mx-auto px-4 py-8 space-y-8 max-w-6xl">
                <MarketHero />

                <section className="grid grid-cols-1 md:grid-cols-12 gap-4 items-stretch min-h-[850px]">
                    <div className="md:col-span-4 h-full flex flex-col gap-3 min-h-0">
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
                            refreshPredictions={fetchPredictions}
                            fetchUserStats={fetchUserStats}
                            isLoaded={isLoaded}
                            onBetSuccess={() => setIsEntertainmentHubOpen(true)}
                        />
                        <PredictionTabs predictions={predictions} user={user} />
                    </div>

                    <div className="md:col-span-8 h-full flex flex-col gap-3 min-h-0">
                        <Card className="h-[480px] shrink-0 border-white/10 bg-card/40 overflow-hidden flex flex-col relative group">
                            <div className="flex-1 w-full h-full bg-black/40 relative">
                                <TradingViewWidget
                                    symbol={selectedAsset.symbol}
                                    interval={selectedTimeframe}
                                    theme="dark"
                                />
                                <div className="absolute inset-0 pointer-events-none shadow-[inset_0_0_40px_rgba(0,0,0,0.5)]" />
                            </div>
                        </Card>

                        <div className="h-[340px] mt-auto grid grid-cols-1 md:grid-cols-2 gap-3 shrink-0">
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
            </div>
        </main>
    );
}
