"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { MarketHeader } from "@/components/dashboard/market-header";
import { Zap, Clock, Users, Activity } from "lucide-react";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";
import { Suspense } from "react";

function LandingContent() {
  const [user, setUser] = useState<any>(null);
  const supabase = createClient();

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (data.user) {
        setUser(data.user);

        // Ensure profile exists with initial points
        const { data: profile } = await supabase
          .from('profiles')
          .select('id')
          .eq('id', data.user.id)
          .single();

        if (!profile) {
          // Create profile if it doesn't exist
          await supabase.from('profiles').insert({
            id: data.user.id,
            email: data.user.email,
            username: data.user.email?.split('@')[0] || 'trader',
            points: 1000
          });
        }
      }
    });
  }, []);

  const { userPoints, userRank, username, activeCount } = useUserStats(user);

  return (
    <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 overflow-x-hidden flex flex-col pb-24 lg:pb-0">
      <MarketHeader
        user={user}
        username={username}
        userPoints={userPoints}
        userRank={userRank}
        activeCount={activeCount}
      />

      <div className="flex-1 flex flex-col items-center pt-2 md:pt-6 pb-6 px-4 max-w-lg mx-auto w-full z-10">

        {/* HERO */}
        <div className="text-center mb-4 relative">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[300px] h-[300px] bg-[#00E5B4]/10 blur-[80px] rounded-full -z-10" />



          <h1 className="text-4xl md:text-5xl font-black tracking-tighter leading-[0.9] italic uppercase mt-8 mb-2 text-white">
            CHARTCLASH
          </h1>

          <p className="text-[#8BA3BF] text-[13px] md:text-sm font-medium mb-4 max-w-[280px] mx-auto leading-tight">
            Real USDT &middot; Real Rewards.<br />
            <span className="text-white">Bet on BTC &middot; UP or DOWN</span>
          </p>


        </div>

        {/* LIVE STATS (mock data for now) */}
        <div className="grid grid-cols-3 gap-2 w-full mb-6">
          <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl py-2 px-3 flex flex-col items-center justify-center text-center">
            <Users className="w-4 h-4 text-[#8BA3BF] mb-1.5" />
            <div className="text-[10px] text-[#5A7090] font-bold uppercase tracking-wider mb-0.5">Active</div>
            <div className="text-sm font-black font-mono">{(activeCount || 0) + 1248}</div>
          </div>
          <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl py-2 px-3 flex flex-col items-center justify-center text-center">
            <Activity className="w-4 h-4 text-[#00E5B4] mb-1.5" />
            <div className="text-[10px] text-[#5A7090] font-bold uppercase tracking-wider mb-0.5">Pool</div>
            <div className="text-sm font-black font-mono text-[#00E5B4]">8,540<span className="text-[10px] text-[#00E5B4]/70"> USDT</span></div>
          </div>
          <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl py-2 px-3 flex flex-col items-center justify-center text-center">
            <Clock className="w-4 h-4 text-[#FF4560] mb-1.5" />
            <div className="text-[10px] text-[#5A7090] font-bold uppercase tracking-wider mb-0.5">Next Lock</div>
            <div className="text-sm font-black font-mono text-[#FF4560]">04:12</div>
          </div>
        </div>

        <div className="w-full text-center mt-8 mb-8">
          <Link href="/play/BTCUSDT/1h" className="inline-block">
            <button className="px-10 sm:px-12 w-full xs:w-auto bg-[#00E5B4] hover:bg-[#00E5B4]/90 text-black font-black h-[60px] rounded-xl text-lg flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(0,229,180,0.3)] transition-all active:scale-[0.98]">
              START BATTLE <Zap className="w-5 h-5 fill-black" />
            </button>
          </Link>
        </div>

        {/* HOW IT WORKS */}
        <div className="w-full">
          <div className="text-[11px] font-black text-[#8BA3BF] uppercase tracking-[0.15em] mb-4 text-center">How to play</div>
          <div className="space-y-3">
            <div className="flex items-center gap-4 bg-[#0F1623] border border-[#1E2D45] py-3 px-4 rounded-xl">
              <div className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#FF4560] font-black">1</div>
              <div>
                <div className="text-sm font-black uppercase mb-0.5">Predict Move</div>
                <div className="text-xs text-[#5A7090]">UP or DOWN in 1H timeframe.</div>
              </div>
            </div>
            <div className="flex items-center gap-4 bg-[#0F1623] border border-[#1E2D45] py-3 px-4 rounded-xl">
              <div className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#F5A623] font-black">2</div>
              <div>
                <div className="text-sm font-black uppercase mb-0.5">Battle Others</div>
                <div className="text-xs text-[#5A7090]">Lock your bet. Losers pay winners.</div>
              </div>
            </div>
            <div className="flex items-center gap-4 bg-[#0F1623] border border-[#1E2D45] py-3 px-4 rounded-xl">
              <div className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#00E5B4] font-black">3</div>
              <div>
                <div className="text-sm font-black uppercase mb-0.5">Win Rewards</div>
                <div className="text-xs text-[#5A7090]">Claim USDT and climb the ranks.</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

export default function LandingHub() {
  return (
    <Suspense fallback={<div className="min-h-[100dvh] bg-[#080C14] flex items-center justify-center text-[#5A7090]">Loading Arena...</div>}>
      <LandingContent />
    </Suspense>
  );
}
