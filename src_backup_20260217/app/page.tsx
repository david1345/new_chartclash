"use client";
// Deployment Trigger: 2026-02-13 18:22

import { useEffect, useState } from "react";
import dayjs from "dayjs";
import "dayjs/locale/en";
dayjs.locale("en");
import TradingViewWidget from "@/components/chart/tradingview-widget";
import { StatsPanel } from "@/components/dashboard/stats-panel";
import { Card } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";
import { ASSETS } from "@/lib/constants";
import { isMarketOpen } from "@/lib/market-hours";

// Refactored Components
import { MarketHeader, MarketHero } from "@/components/dashboard/market-header";
import { OrderPanel } from "@/components/dashboard/order-panel";
import { PredictionTabs } from "@/components/dashboard/prediction-tabs";
import { SocialFeed } from "@/components/dashboard/social-feed";
import { EntertainmentHub } from "@/components/dashboard/entertainment-hub";

// Custom Hooks
import { usePredictionLock } from "@/hooks/dashboard/use-prediction-lock";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";
import { usePredictionHistory } from "@/hooks/dashboard/use-prediction-history";
import { useRoomFeed } from "@/hooks/dashboard/use-room-feed";

import { TutorialOverlay } from "@/components/tutorial/tutorial-overlay";

export default function Dashboard() {
  interface User {
    id: string;
    email?: string;
    user_metadata?: {
      avatar_url?: string;
      full_name?: string;
    };
  }

  const [user, setUser] = useState<User | null>(null);
  const [isGhostMode, setIsGhostMode] = useState(false);

  // Local UI State - Lifted for Orchestration
  const [selectedAsset, setSelectedAsset] = useState(ASSETS.CRYPTO[0]);
  const [selectedTimeframe, setSelectedTimeframe] = useState("1h");
  const [isEntertainmentHubOpen, setIsEntertainmentHubOpen] = useState(false);
  const [mounted, setMounted] = useState(false);

  const supabase = createClient();

  useEffect(() => {
    setMounted(true);
    supabase.auth.getUser().then(({ data }) => {
      const realUser = data.user as User;

      // Admin Impersonation (Ghost Mode)
      const searchParams = new URLSearchParams(typeof window !== 'undefined' ? window.location.search : '');
      // 3. Ghost Mode (Impersonation) logic for Admin
      const impersonateId = searchParams.get('impersonate') || (typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null);

      if (impersonateId && realUser?.email === 'sjustone000@gmail.com') {
        console.log("👻 DASHBOARD: GHOST MODE ACTIVE FOR", impersonateId);
        setIsGhostMode(true);
        if (typeof window !== 'undefined') {
          sessionStorage.setItem('ghost_target_id', impersonateId);
        }

        // Fetch target user details for admin visibility
        const fetchTargetUser = async () => {
          console.log("🔍 GHOST_DEBUG: Fetching details for", impersonateId);
          const { data: profile, error: pError } = await supabase
            .from('profiles')
            .select('username, email')
            .eq('id', impersonateId)
            .maybeSingle();

          if (pError) console.error("❌ GHOST_DEBUG: Profile fetch error:", pError);
          console.log("🔍 GHOST_DEBUG: Results - Profile:", profile);

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
        // Clear ghost mode if not explicitly impersonating or not admin
        if (typeof window !== 'undefined' && !searchParams.get('impersonate')) {
          sessionStorage.removeItem('ghost_target_id');
        }
        setIsGhostMode(false);
        setUser(realUser);
      }
    });
  }, []);

  // Safety check for 1m timeframe restriction
  useEffect(() => {
    if (selectedTimeframe === '1m' && user?.email !== 'sjustone000@gmail.com') {
      setSelectedTimeframe('15m');
    }
  }, [selectedTimeframe, user]);

  // --- HOOKS INTEGRATION ---

  // 1. Timer & Lock (with Server Sync)
  const { isLocked } = usePredictionLock({
    timeframe: selectedTimeframe,
    selectedAssetSymbol: selectedAsset.symbol
  });

  // 2. User Stats (Points, Rank, Realtime)
  const { userPoints, setUserPoints, userStreak, username, userRank, fetchUserStats, isLoaded } = useUserStats(user);

  // 3. Prediction History
  const { predictions, fetchPredictions } = usePredictionHistory(user);

  // 4. Room Feed
  const { feed, fetchFeed } = useRoomFeed({
    assetSymbol: selectedAsset.symbol,
    timeframe: selectedTimeframe,
    currentUserId: user?.id
  });

  // 5. Market Status Check
  const marketStatus = isMarketOpen(selectedAsset.symbol, selectedAsset.type);

  // 6. Check if Already Bet in Current Round
  const isAlreadyBet = predictions.some(p =>
    p.status === 'pending' &&
    p.asset_symbol === selectedAsset.symbol &&
    p.timeframe === selectedTimeframe &&
    // Approximate match with candle_close_at (could use usePredictionLock's end time)
    new Date(p.candle_close_at).getTime() > Date.now()
  );

  const isAIBeatEnabled = process.env.NEXT_PUBLIC_ENABLE_AI_BEAT === 'true';

  return (
    <main className="min-h-screen bg-[#060609] text-white selection:bg-primary/30">
      {/* 1. Header */}
      <MarketHeader
        user={user}
        username={username}
        userPoints={userPoints}
        userRank={userRank}
        mounted={mounted}
        isGhostMode={isGhostMode}
      />

      <div className="container mx-auto px-4 py-8 space-y-8 max-w-6xl">

        {/* 2. Game Explanation Banner */}
        <MarketHero />

        {/* 4. Prediction Panel (Split Column) & Chart */}
        <section className="grid grid-cols-1 md:grid-cols-12 gap-4 items-stretch min-h-[850px]">
          {/* Left Column (Input + History) */}
          <div className="md:col-span-4 h-full flex flex-col gap-3 min-h-0">

            {/* Top Half: Input (Fixed Height) */}
            <OrderPanel
              user={user}
              userPoints={userPoints}
              userStreak={userStreak}
              setUserPoints={setUserPoints}
              selectedAsset={selectedAsset}
              setSelectedAsset={setSelectedAsset}
              selectedTimeframe={selectedTimeframe}
              setSelectedTimeframe={setSelectedTimeframe}
              marketStatus={marketStatus}
              isLocked={isLocked}
              isAlreadyBet={isAlreadyBet}
              refreshPredictions={fetchPredictions}
              fetchUserStats={fetchUserStats}
              isLoaded={isLoaded}
              onBetSuccess={() => setIsEntertainmentHubOpen(true)}
            />

            {/* Bottom Half: Active Predictions (Strict Height 6 items approx) */}
            <PredictionTabs predictions={predictions} user={user} />

          </div>

          {/* Right Column (Chart + Feed) */}
          <div className="md:col-span-8 h-full flex flex-col gap-3 min-h-0">
            {/* Chart Card */}
            <Card className="h-[480px] shrink-0 border-white/10 bg-card/40 overflow-hidden flex flex-col relative group">
              {/* Chart Component */}
              <div className="flex-1 w-full h-full bg-black/40 relative">
                <TradingViewWidget
                  symbol={selectedAsset.symbol}
                  interval={selectedTimeframe}
                  theme="dark"
                />
                {/* Overlay Gradient for seamless look */}
                <div className="absolute inset-0 pointer-events-none shadow-[inset_0_0_40px_rgba(0,0,0,0.5)]" />
              </div>
            </Card>

            {/* Bottom: Stats & Feed */}
            <div className="h-[340px] mt-auto grid grid-cols-1 md:grid-cols-2 gap-3 shrink-0">
              {/* Stats Panel */}
              <StatsPanel
                assetSymbol={selectedAsset.symbol}
                timeframe={selectedTimeframe}
              />

              {/* Social Feed */}
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
        {/* Helper Components / Hidden Triggers */}
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
