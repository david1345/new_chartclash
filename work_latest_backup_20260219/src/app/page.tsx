"use client";

import { useEffect, useState, useMemo } from "react";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";
import { ASSETS, Asset } from "@/lib/constants";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { MarketHeader } from "@/components/dashboard/market-header";
import { TrendingSection } from "@/components/dashboard/trending-section";
import { MarketCard } from "@/components/dashboard/market-card";
import {
  Flame, TrendingUp, Zap, Clock, Users, ArrowRight,
  Search, MousePointerClick, Target, Trophy, ChevronDown,
  LineChart, Coins
} from "lucide-react";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";

export default function LandingHub() {
  const [user, setUser] = useState<any>(null);
  const [mounted, setMounted] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("ALL");

  const supabase = createClient();

  useEffect(() => {
    setMounted(true);
    supabase.auth.getUser().then(({ data }) => setUser(data.user));
  }, []);

  const { userPoints, userRank, username } = useUserStats(user);

  const allAssets = useMemo(() => {
    return Object.entries(ASSETS).flatMap(([category, assets]) =>
      assets.map(a => ({ ...a, category }))
    );
  }, []);

  const filteredAssets = useMemo(() => {
    return allAssets.filter(asset => {
      const matchesSearch = asset.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        asset.symbol.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = selectedCategory === "ALL" || asset.category === selectedCategory;
      return matchesSearch && matchesCategory;
    });
  }, [allAssets, searchQuery, selectedCategory]);

  const featuredAssets = allAssets.filter(a => ['BTCUSDT', 'AAPL', 'XAUUSD'].includes(a.symbol));

  const categories = ["ALL", "CRYPTO", "STOCKS", "COMMODITIES"];

  return (
    <main className="min-h-screen bg-[#060609] text-white selection:bg-primary/30 overflow-x-hidden">
      <MarketHeader
        user={user}
        username={username}
        userPoints={userPoints}
        userRank={userRank}
        mounted={mounted}
      />

      <div className="container mx-auto px-4 py-8 max-w-7xl space-y-12">
        {/* --- HERO SECTION --- */}
        <section className="relative min-h-[45vh] flex flex-col items-center justify-center pt-4 text-center overflow-hidden">
          {/* Background Elements */}
          <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary/10 blur-[150px] rounded-full" />

            {/* Animated Chart Line Background */}
            <motion.svg
              initial={{ pathLength: 0, opacity: 0 }}
              animate={{ pathLength: 1, opacity: 0.1 }}
              transition={{ duration: 3, ease: "easeInOut", repeat: Infinity, repeatType: "reverse" }}
              className="absolute inset-0 w-full h-full stroke-primary/30 fill-none stroke-[2]"
              viewBox="0 0 1440 800"
            >
              <path d="M0,400 Q360,200 720,400 T1440,400" />
            </motion.svg>
          </div>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="relative z-10 space-y-4"
          >
            <Badge className="bg-blue-500/10 text-blue-400 border-blue-500/20 px-6 py-2 text-xs font-black tracking-[0.2em] uppercase rounded-full">
              The Ultimate Prediction Arena
            </Badge>

            <h1 className="text-5xl md:text-8xl font-black tracking-tighter leading-[0.8] italic uppercase max-w-5xl mx-auto">
              MASTER THE <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-500 via-orange-500 to-purple-500">MARKETS</span>
            </h1>

            <p className="text-base md:text-lg text-muted-foreground max-w-3xl mx-auto font-medium leading-relaxed opacity-80">
              Join our growing community predicting the future of <span className="text-white font-bold">Crypto, Stocks, and Commodities.</span><br />
              AI-powered insights, real-time competition.
            </p>

            {/* --- 3-STEP GUIDE --- */}
            <div className="max-w-5xl mx-auto w-full pt-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                {[
                  {
                    step: "01",
                    title: "PICK ASSET",
                    desc: "Choose from 30+ markets.",
                    icon: Search,
                    color: "text-blue-500",
                    bg: "bg-blue-500/10"
                  },
                  {
                    step: "02",
                    title: "PREDICT MOVE",
                    desc: "UP or DOWN? AI insights help.",
                    icon: Target,
                    color: "text-orange-500",
                    bg: "bg-orange-500/10"
                  },
                  {
                    step: "03",
                    title: "WIN REWARDS",
                    desc: "Climb the leaderboard.",
                    icon: Trophy,
                    color: "text-purple-500",
                    bg: "bg-purple-500/10"
                  }
                ].map((item, idx) => (
                  <motion.div
                    key={idx}
                    initial={{ opacity: 0, scale: 0.95 }}
                    whileInView={{ opacity: 1, scale: 1 }}
                    whileHover={{
                      scale: 1.02,
                      borderColor: "rgba(255,255,255,0.4)",
                      backgroundColor: "rgba(255,255,255,0.04)"
                    }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.3 }}
                    className="relative p-6 rounded-2xl border border-white/20 bg-white/[0.02] transition-all group overflow-hidden h-[147px] flex flex-col justify-center items-center text-center"
                  >
                    <div className="flex justify-between items-center absolute top-4 w-full px-6">
                      <div className={`p-2 rounded-lg ${item.bg} ${item.color}`}>
                        <item.icon className="w-5 h-5" />
                      </div>
                      <span className="text-xl font-black text-yellow-500/30 italic">{item.step}</span>
                    </div>
                    <div className="space-y-2 mt-4">
                      <h3 className="text-2xl font-black uppercase tracking-tighter leading-tight">{item.title}</h3>
                      <p className="text-sm text-muted-foreground leading-tight font-medium mx-auto max-w-[280px]">{item.desc}</p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>

            <div className="flex flex-col items-center gap-2 pt-4">
              <Link href={`/play/BTCUSDT/1h`}>
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="bg-primary hover:bg-primary/90 text-white font-black w-72 h-16 rounded-full text-xl shadow-[0_0_40px_rgba(59,130,246,0.5)] transition-all flex items-center justify-center gap-3 group"
                >
                  START CLASHING NOW
                  <ArrowRight className="w-6 h-6 group-hover:translate-x-2 transition-transform" />
                </motion.button>
              </Link>

              <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-bold opacity-60">
                100% Virtual Points • No Financial Risk
              </p>
            </div>
          </motion.div>

          <motion.div
            animate={{ y: [0, 8, 0] }}
            transition={{ duration: 2, repeat: Infinity }}
            className="absolute bottom-6 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1 text-muted-foreground/30"
          >
            <span className="text-[10px] font-black tracking-widest uppercase">Explore markets</span>
            <ChevronDown className="w-4 h-4" />
          </motion.div>
        </section>


        {/* --- MARKETS HUB --- */}
        <div id="markets-hub" className="space-y-8 pt-0">
          {/* Search & Filter Bar */}
          <div className="flex flex-col md:flex-row gap-4 items-center justify-between sticky top-20 z-40 bg-background/80 backdrop-blur-md p-4 rounded-2xl border border-white/5 shadow-2xl">
            <div className="relative w-full md:w-96">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <input
                type="text"
                placeholder="Search assets (BTC, AAPL, Gold...)"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-white/5 border-white/10 rounded-xl pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all"
              />
            </div>
            <div className="flex gap-2 overflow-x-auto w-full md:w-auto no-scrollbar pb-2 md:pb-0">
              {categories.map(cat => (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={`px-5 py-2.5 rounded-xl text-xs font-black transition-all whitespace-nowrap uppercase tracking-widest ${selectedCategory === cat ? 'bg-primary text-white shadow-[0_0_20px_rgba(59,130,246,0.3)]' : 'bg-white/5 text-muted-foreground hover:bg-white/10'}`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* Trending Section (Replacing Featured Arenas) */}
          {selectedCategory === "ALL" && !searchQuery && (
            <TrendingSection />
          )}

          {/* Discovery Grid */}
          <section className="space-y-8">
            <div className="flex items-center gap-3 text-3xl font-black italic tracking-tighter">
              <Zap className="text-yellow-400 fill-yellow-400 w-8 h-8" />
              <h2 className="uppercase">Market Discovery</h2>
            </div>

            {filteredAssets.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {filteredAssets.map((asset) => (
                  <MarketCard key={asset.symbol} asset={asset} />
                ))}
              </div>
            ) : (
              <div className="text-center py-20 bg-white/5 rounded-[3rem] border border-white/5 border-dashed">
                <p className="text-muted-foreground text-lg italic">No markets found for "{searchQuery}"</p>
              </div>
            )}
          </section>
        </div>
      </div>

      <footer className="mt-40 border-t border-white/5 pt-20 pb-12 bg-black">
        <div className="container mx-auto px-4 max-w-7xl">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mb-20 items-center">
            <div className="space-y-6 text-center md:text-left">
              <div className="flex items-center justify-center md:justify-start gap-2">
                <img src="/logo-main.png" alt="ChartClash" className="w-10 h-10 object-contain" />
                <span className="text-2xl font-black tracking-tighter uppercase italic">
                  <span className="text-blue-500">Chart</span>Clash
                </span>
              </div>
              <p className="text-muted-foreground max-w-sm mx-auto md:mx-0 text-sm leading-relaxed">
                The world's most engaging prediction marketplace. Built for competitive traders and AI enthusiasts.
              </p>
              <div className="p-4 bg-orange-500/5 border border-orange-500/10 rounded-2xl inline-block">
                <p className="text-[10px] text-orange-400 font-bold uppercase tracking-[0.2em]">
                  ⚠️ Entertainment Only / No Financial Advice
                </p>
              </div>
            </div>
            <div className="flex justify-center md:justify-end gap-12">
              {/* Footer links could go here */}
            </div>
          </div>
          <div className="text-center border-t border-white/5 pt-8">
            <p className="text-[10px] text-muted-foreground/30 font-bold uppercase tracking-widest">
              © 2026 ChartClash. All predictive rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </main>
  );
}


