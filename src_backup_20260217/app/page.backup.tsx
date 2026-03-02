"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { FinancialChart } from "@/components/chart/financial-chart";
import TradingViewWidget from "@/components/chart/tradingview-widget";
import { StatsPanel } from "@/components/dashboard/stats-panel";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { CandleTimer } from "@/components/dashboard/candle-timer";
import { LiveClock } from "@/components/dashboard/live-clock";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { createClient } from "@/lib/supabase/client";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { ArrowUp, ArrowDown, Activity, Trophy, Coins, Timer, Loader2, Sparkles, ChevronDown, Search, History, LayoutDashboard, BarChart3 } from "lucide-react";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import { ASSETS, TIMEFRAMES } from "@/lib/constants";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { User, Settings, Medal, ScrollText } from "lucide-react"
import { AppDrawer } from "@/components/navigation/app-drawer";
import { NotificationBell } from "@/components/notifications/notification-bell";
import { motion } from "framer-motion";

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
  const [userPoints, setUserPoints] = useState(1000); // Default
  const [betAmount, setBetAmount] = useState(10);
  const [selectedDirection, setSelectedDirection] = useState<"UP" | "DOWN" | null>(null);
  const [selectedPercent, setSelectedPercent] = useState<number | null>(0.5);
  const [selectedAsset, setSelectedAsset] = useState(ASSETS.CRYPTO[0]);
  const [selectedTimeframe, setSelectedTimeframe] = useState("1h");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [comment, setComment] = useState("");
  const [assetSearch, setAssetSearch] = useState("");
  const [predictions, setPredictions] = useState<any[]>([]);

  const [isLocked, setIsLocked] = useState(false);
  // Removed explicit currentTime/timeLeft/lockReason states causing re-renders
  const [mounted, setMounted] = useState(false);
  const [isAssetDialogOpen, setIsAssetDialogOpen] = useState(false);
  const [isTimeframeOpen, setIsTimeframeOpen] = useState(false);
  const [feed, setFeed] = useState<any[]>([]);
  const supabase = createClient();

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      setUser(data.user as User); // Casting to our type
      if (data.user) {
        fetchPredictions(data.user.id);
        fetchUserPoints(data.user.id);
      }
    });
    fetchFeed();
  }, []);

  // Subscribe to Realtime Feed (Room Logic)
  useEffect(() => {
    // 1. Initial Load
    fetchFeed(selectedAsset.symbol, selectedTimeframe);

    // 2. Subscribe to Room
    const roomChannel = supabase
      .channel(`room-${selectedAsset.symbol}-${selectedTimeframe}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'predictions',
          filter: `asset_symbol=eq.${selectedAsset.symbol}` // Filter by Asset
        },
        async (payload: any) => {
          const newPred = payload.new;
          // Client-side filter for timeframe (since Supabase filter string is limited)
          if (newPred.timeframe !== selectedTimeframe) return;

          // Only show if it has a comment (as per current feed logic)
          if (!newPred.comment) return;

          // Fetch full details (profile username)
          const { data } = await supabase
            .from('predictions')
            .select(`*, profiles (username)`)
            .eq('id', newPred.id)
            .single();

          if (data) {
            setFeed(prev => [data, ...prev]);
            toast.success("New Alpha Dropped!", { description: `${data.profiles?.username} just posted in this room.` });
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(roomChannel);
    };
  }, [selectedAsset, selectedTimeframe]);

  // Timer logic moved to CandleTimer component
  // Auto-Resolve Poller Removed: Now handled by Vercel Cron (/api/cron/resolve)


  // Auto-Resolve Poller Removed: Now handled by Vercel Cron (/api/cron/resolve)
  // Logic moved to server-side for better reliability.
  const [userRank, setUserRank] = useState<number | null>(null);

  const fetchUserPoints = async (userId: string) => {
    const { data } = await supabase.from('profiles').select('points').eq('id', userId).single();
    if (data) setUserPoints(data.points);

    const { data: rank } = await supabase.rpc('get_user_rank', { p_user_id: userId });
    if (rank) setUserRank(rank);
  };

  // Realtime Data Refresh
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('dashboard-realtime')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'notifications', filter: `user_id=eq.${user.id}` },
        (payload: any) => {
          console.log("🔔 Notification received! Refreshing data...", payload);
          fetchPredictions(user.id);
          fetchUserPoints(user.id);
          fetchFeed();

          const newNotif = payload.new;
          const isWin = newNotif.message?.includes('WIN');
          const title = isWin ? "Prediction Won! 🎉" : "Prediction Resolved";

          toast.info(title, {
            description: newNotif.message || "Your prediction has been resolved."
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user]);

  // Safety Net: Poll every 60 seconds as fallback
  // Primary data source is Realtime; this covers connection drops
  useEffect(() => {
    if (!user) return;
    const interval = setInterval(() => {
      // Only fetch if tab is visible to save resources
      if (document.visibilityState === 'visible') {
        fetchPredictions(user.id);
        fetchUserPoints(user.id);
      }
    }, 60000);
    return () => clearInterval(interval);
  }, [user]);

  const [isLoadingPredictions, setIsLoadingPredictions] = useState(true);

  const fetchPredictions = async (userId: string) => {
    setIsLoadingPredictions(true);
    const { data } = await supabase
      .from('predictions')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(20);
    if (data) setPredictions(data);
    setIsLoadingPredictions(false);
  };

  const fetchFeed = async (asset = selectedAsset.symbol, tf = selectedTimeframe) => {
    // Fetch predictions with comments for specific room
    const { data } = await supabase
      .from('predictions')
      .select(`
            *,
            profiles (username)
        `)
      .not('comment', 'is', null) // Only with comments
      .eq('asset_symbol', asset) // Filter by Room
      .eq('timeframe', tf)       // Filter by Room
      .order('created_at', { ascending: false })
      .limit(50); // Increased limit as requested

    if (data) setFeed(data);
  };

  const handlePostComment = async () => {
    if (!user || !comment.trim()) {
      toast.error("Please write a comment");
      return;
    }

    setIsSubmitting(true);

    try {
      // 1. Find latest prediction
      const { data: latest, error: fetchError } = await supabase
        .from('predictions')
        .select('id')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (fetchError || !latest) {
        toast.error("Please make a prediction first!");
        setIsSubmitting(false);
        return;
      }

      // 2. Update comment
      const { error: updateError } = await supabase
        .from('predictions')
        .update({ comment: comment.trim() })
        .eq('id', latest.id);

      if (updateError) {
        console.error("Comment update error:", updateError);
        toast.error("Failed to post comment");
      } else {
        toast.success("Alpha shared!");
        setComment("");
        fetchFeed(selectedAsset.symbol, selectedTimeframe);
      }
    } catch (err) {
      console.error("Unexpected error:", err);
      toast.error("Something went wrong");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleForceResolve = async () => {
    // Calling Cron API manually for stress test / admin
    const res = await fetch('/api/cron/resolve');
    const json = await res.json();
    if (json.success) {
      if (json.resolved > 0) {
        // toast.success(`Resolved ${json.resolved} rounds!`);
        if (user) {
          fetchPredictions(user.id);
          fetchUserPoints(user.id);
        }
      } else {
        // toast.info("No pending rounds to resolve.");
      }
    } else {
      // toast.info(json.message || "Resolution check complete");
    }
  };

  const fetchCurrentPrice = async (symbol: string) => {
    // 1. Binance (Crypto)
    if (!symbol.includes('AAPL') && !symbol.includes('TSLA')) { // Simple check for crypto
      try {
        const cleanSymbol = symbol.replace('/', '').toUpperCase();
        const res = await fetch(`https://api.binance.com/api/v3/ticker/price?symbol=${cleanSymbol}`);
        const data = await res.json();
        if (data.price) return parseFloat(data.price);
      } catch (e) {
        console.error("Binance fetch failed", e);
      }
    }

    // 2. Mock for Stocks/Other (or failure fallback)
    return symbol === 'BTCUSDT' ? 95000 : 150.00;
  };

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

      return json.data; // { openTime, openPrice, currentPrice }

    } catch (e) {
      console.error("Server price API error", e);
      return null;
    }
  };

  const handleSubmitPrediction = async () => {
    if (!user) {
      toast.error("Please sign in to place a prediction!");
      return;
    }
    if (!selectedDirection || !selectedPercent) {
      toast.warning("Check your vibe! Pick a direction and magnitude.");
      return;
    }

    const maxBet = Math.floor(userPoints * 0.2);
    if (betAmount < 10) {
      toast.warning("Minimum bet is 10 pts.");
      return;
    }
    if (betAmount > maxBet && userPoints > 50) {
      toast.warning(`Max bet is ${maxBet} pts (20% of your holdings)`);
      return;
    }

    if (isLocked) {
      toast.error("Round is locked! Wait for the next candle.");
      return;
    }

    setIsSubmitting(true);

    const candleData = await fetchCandleData(selectedAsset.symbol, selectedTimeframe, selectedAsset.type as any);

    if (!candleData) {
      toast.error("Could not fetch market data. Try again.");
      setIsSubmitting(false);
      return;
    }

    // Ensure Profile Exists (Idempotent)
    await supabase.from('profiles').upsert({
      id: user.id,
      email: user.email,
      username: user.email?.split('@')[0] || 'User',
    }, { onConflict: 'id', ignoreDuplicates: true });

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
      toast.error("Submission failed: " + rpcError.message);
      console.error(rpcError);
    } else {
      toast.success(`Locked: ${selectedAsset.name} @ ${candleData.openPrice}`);
      setSelectedDirection(null);
      setSelectedPercent(0.5);
      fetchPredictions(user.id);

      // Update local points from RPC result
      // @ts-ignore
      if (rpcData && rpcData.new_points !== undefined) {
        // @ts-ignore
        setUserPoints(rpcData.new_points);
      } else {
        fetchUserPoints(user.id);
      }
    }

    setIsSubmitting(false);
  };
  const filteredAssets = (category: any[]) => {
    if (!assetSearch) return category;
    return category.filter(a => a.name.toLowerCase().includes(assetSearch.toLowerCase()) || a.symbol.toLowerCase().includes(assetSearch.toLowerCase()));
  };

  return (
    <main className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20">

      {/* 1. Header */}
      <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl supports-[backdrop-filter]:bg-background/20">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <AppDrawer />
            <Link href="/" className="flex items-center gap-2 group" suppressHydrationWarning>
              <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-primary to-blue-600 flex items-center justify-center shadow-[0_0_15px_rgba(var(--primary),0.5)] group-hover:scale-110 transition-transform">
                <Activity className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold tracking-tighter bg-gradient-to-r from-white to-white/60 bg-clip-text text-transparent group-hover:from-primary group-hover:to-blue-400 transition-all">VIBE MARKET</span>
            </Link>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center gap-3">
              {/* Live Clock (Moved) */}
              <div className="hidden md:flex items-center gap-2 text-amber-500 font-mono font-bold bg-amber-500/10 px-3 py-1 rounded-lg border border-amber-500/20 whitespace-nowrap h-8">
                <Timer className="w-4 h-4 animate-pulse" />
                <span>{mounted ? <LiveClock /> : "00:00:00"}</span>
              </div>

              <Link href="/sentiment">
                <Button variant="ghost" size="sm" className="hidden md:flex gap-2 text-muted-foreground hover:text-blue-400 hover:bg-blue-400/10 h-8">
                  <BarChart3 className="w-4 h-4" /> Sentiment
                </Button>
              </Link>

              <Link href="/leaderboard">
                <Button variant="ghost" size="sm" className="hidden md:flex gap-2 text-muted-foreground hover:text-yellow-400 hover:bg-yellow-400/10 h-8">
                  <Trophy className="w-4 h-4" /> Leaderboard
                </Button>
              </Link>
            </div>

            {/* User Profile Dropdown */}
            <div className="flex items-center gap-3">
              {/* Points Display (Keep it visible outside too?) - User requested Points / Rank */}
              <div className="hidden md:flex flex-col items-end mr-2">
                <div className="flex items-center gap-1.5 text-yellow-500 font-bold font-mono text-sm">
                  <Coins className="w-3.5 h-3.5" />
                  <span>{userPoints.toLocaleString()}</span>
                </div>
                <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-bold">
                  {userRank ? `Rank #${userRank}` : 'Unranked'}
                </span>
              </div>

              <NotificationBell />

              {!user ? (
                <Link href="/login">
                  <Button variant="outline" className="h-8 border-primary/20 bg-primary/10 text-primary hover:bg-primary/20 hover:text-primary">
                    Sign In / Up
                  </Button>
                </Link>
              ) : (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="relative h-8 w-8 rounded-full bg-white/10 hover:bg-white/20 border border-white/5 p-0 overflow-hidden">
                      {/* Placeholder Avatar */}
                      <div className="flex items-center justify-center w-full h-full bg-gradient-to-b from-gray-700 to-gray-800 text-xs font-bold text-white/70">
                        {user?.email?.[0]?.toUpperCase() || "U"}
                      </div>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent className="w-56 bg-[#0b0b0f] border-white/10" align="end" forceMount>
                    <DropdownMenuLabel className="font-normal">
                      <div className="flex flex-col space-y-1">
                        <p className="text-sm font-medium leading-none text-white">{user?.email?.split('@')[0] || 'Trader'}</p>
                        <p className="text-xs leading-none text-muted-foreground truncate">{user?.email || 'guest@vibe.market'}</p>
                      </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator className="bg-white/10" />
                    <DropdownMenuItem asChild>
                      <Link href="/leaderboard" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                        <Trophy className="w-4 h-4 text-yellow-500" /> Leaderboard
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link href="/my-stats" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                        <Activity className="w-4 h-4" /> My Stats
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link href="/match-history" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                        <ScrollText className="w-4 h-4" /> Match History
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link href="/achievements" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                        <Medal className="w-4 h-4" /> Achievements
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuSeparator className="bg-white/10" />
                    <DropdownMenuItem asChild>
                      <Link href="/settings" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                        <Settings className="w-4 h-4" /> Settings
                      </Link>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              )}
            </div>
          </div>
        </div>
      </header>



      <div className="container mx-auto px-4 py-8 space-y-8 max-w-6xl">

        {/* 2. Game Explanation Banner */}
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-900/20 to-purple-900/20 border border-white/5 p-6 md:p-8">
          <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 bg-primary/20 blur-[100px] rounded-full pointer-events-none" />
          <div className="relative z-10 max-w-3xl mx-auto text-center">
            <Badge variant="outline" className="mb-3 border-primary/50 text-primary bg-primary/10 animate-pulse">LIVE SEASON 1</Badge>
            <h1 className="text-3xl md:text-4xl font-bold mb-2">Predict. Compete. Climb the Rankings.</h1>
            <p className="text-muted-foreground text-sm md:text-base mt-3">
              Choose an asset, forecast its next move, and hit your volatility target.<br />
              The more accurate your calls, the higher you rise on the leaderboard.
            </p>
            <HeroCTA />
            <ScrollHintArrow />
          </div>
        </div>


        {/* Selection Bar Removed - Controls moved to Input Card */}

        {/* 4. Prediction Panel (Split Column) & Chart */}
        {/* 4. Prediction Panel (Split Column) & Chart */}
        {/* 4. Prediction Panel (Split Column) & Chart */}
        {/* 4. Prediction Panel (Split Column) & Chart */}
        <section className="grid grid-cols-1 md:grid-cols-12 gap-4 items-start h-[550px]">
          {/* Left Column (Input + History) */}
          <div className="md:col-span-4 h-full flex flex-col gap-3 min-h-0">

            {/* Top Half: Input (Fixed Height) */}
            <Card className="flex-none border-white/60 bg-gradient-to-b from-card/80 to-card/40 shadow-2xl shadow-primary/5 overflow-hidden flex flex-col pb-2">
              <CardHeader className="py-1.5 px-3 pb-0 flex flex-row items-center justify-between min-h-[30px] w-full">
                <CardTitle className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider">
                  <Sparkles className="w-3 h-3 text-primary" /> Make Prediction
                </CardTitle>
                <div className={cn("text-[10px] font-mono font-bold px-1.5 py-0.5 rounded border flex items-center gap-1.5 min-w-[100px] justify-center bg-black/40 border-white/10")}>
                  <CandleTimer timeframe={selectedTimeframe} onLockChange={setIsLocked} />
                </div>

              </CardHeader>
              {/* Unlocked Selector Area */}
              <div className="px-3 pt-1 pb-1">
                <div className="flex items-center gap-2">
                  {/* Asset Selector */}
                  <Dialog open={isAssetDialogOpen} onOpenChange={setIsAssetDialogOpen}>
                    <DialogTrigger asChild>
                      <Button variant="outline" className="flex-1 justify-between border-white/20 bg-primary/5 hover:bg-primary/10 text-sm h-8 hover:border-white/40 transition-colors">
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
                            <TabsTrigger value="CRYPTO">Crypto</TabsTrigger>
                            <TabsTrigger value="STOCKS">Stocks</TabsTrigger>
                            <TabsTrigger value="COMMODITIES">Cmdty</TabsTrigger>
                          </TabsList>
                          <ScrollArea className="h-[300px] mt-2 pr-4">
                            <TabsContent value="CRYPTO" className="space-y-1">
                              {filteredAssets(ASSETS.CRYPTO).map(asset => (
                                <Button key={asset.symbol} variant="ghost" className="w-full justify-start font-mono" onClick={() => { setSelectedAsset(asset); setIsAssetDialogOpen(false); }}>
                                  <span className={cn("mr-2 w-2 h-2 rounded-full", selectedAsset.symbol === asset.symbol ? "bg-primary" : "bg-white/10")} />
                                  {asset.symbol} <span className="ml-auto text-xs text-muted-foreground">{asset.name}</span>
                                </Button>
                              ))}
                            </TabsContent>
                            <TabsContent value="STOCKS" className="space-y-1">
                              {filteredAssets(ASSETS.STOCKS).map(asset => (
                                <Button key={asset.symbol} variant="ghost" className="w-full justify-start font-mono" onClick={() => { setSelectedAsset(asset); setIsAssetDialogOpen(false); }}>
                                  <span className={cn("mr-2 w-2 h-2 rounded-full", selectedAsset.symbol === asset.symbol ? "bg-primary" : "bg-white/10")} />
                                  {asset.symbol} <span className="ml-auto text-xs text-muted-foreground">{asset.name}</span>
                                </Button>
                              ))}
                            </TabsContent>
                            <TabsContent value="COMMODITIES" className="space-y-1">
                              {filteredAssets(ASSETS.COMMODITIES).map(asset => (
                                <Button key={asset.symbol} variant="ghost" className="w-full justify-start font-mono" onClick={() => { setSelectedAsset(asset); setIsAssetDialogOpen(false); }}>
                                  <span className={cn("mr-2 w-2 h-2 rounded-full", selectedAsset.symbol === asset.symbol ? "bg-primary" : "bg-white/10")} />
                                  {asset.symbol} <span className="ml-auto text-xs text-muted-foreground">{asset.name}</span>
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
                      <Button variant="outline" className="w-[80px] justify-between border-white/20 bg-black/20 hover:bg-white/5 text-xs h-8 hover:border-white/40 transition-colors">
                        <span className="font-bold">{selectedTimeframe}</span>
                        <ChevronDown className="w-3 h-3 opacity-50" />
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-[120px] p-1 bg-card border-white/10">
                      <div className="flex flex-col gap-1">
                        {TIMEFRAMES.map((tf) => (
                          <Button
                            key={tf}
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

              {/* Locked Betting Area */}
              <CardContent className={cn("space-y-1 p-2 pt-0 flex-1 flex flex-col justify-center transition-opacity duration-300", isLocked && "opacity-50 pointer-events-none grayscale")}>
                {/* Direction */}
                <div className="grid grid-cols-2 gap-2 h-9">
                  <Button
                    onClick={() => setSelectedDirection("UP")}
                    className={cn(
                      "h-full text-sm font-bold border-2 transition-all relative overflow-hidden group",
                      selectedDirection === "UP"
                        ? "bg-emerald-500/20 border-emerald-500 text-emerald-400 shadow-[0_0_20px_rgba(16,185,129,0.3)]"
                        : "bg-black/40 text-muted-foreground border-white/5 hover:border-emerald-500/50 hover:text-emerald-500"
                    )}
                  >
                    <span className="relative z-10 flex items-center gap-1">
                      <ArrowUp className="w-4 h-4" /> RISE
                    </span>
                    {selectedDirection === "UP" && <div className="absolute inset-0 bg-emerald-500/10 animate-pulse" />}
                  </Button>
                  <Button
                    onClick={() => setSelectedDirection("DOWN")}
                    className={cn(
                      "h-full text-sm font-bold border-2 transition-all relative overflow-hidden group",
                      selectedDirection === "DOWN"
                        ? "bg-red-500/20 border-red-500 text-red-400 shadow-[0_0_20px_rgba(239,68,68,0.3)]"
                        : "bg-black/40 text-muted-foreground border-white/5 hover:border-red-500/50 hover:text-red-500"
                    )}
                  >
                    <span className="relative z-10 flex items-center gap-1">
                      <ArrowDown className="w-4 h-4" /> FALL
                    </span>
                    {selectedDirection === "DOWN" && <div className="absolute inset-0 bg-red-500/10 animate-pulse" />}
                  </Button>
                </div>

                {/* Magnitude */}
                <div className="space-y-1">
                  <div className="grid grid-cols-4 gap-1">
                    {[0.5, 1.0, 1.5, 2.0].map((val) => (
                      <Button
                        key={val}
                        variant="outline"
                        size="sm"
                        onClick={() => setSelectedPercent(val)}
                        className={cn(
                          "h-6 border-2 transition-all font-mono text-[10px]",
                          selectedPercent === val
                            ? "bg-transparent text-amber-500 font-extrabold border-transparent scale-110 z-10 shadow-[0_0_15px_rgba(245,158,11,0.2)]"
                            : "border-white/5 bg-black/20 text-muted-foreground hover:border-amber-500/50 hover:text-amber-400 transition-colors"
                        )}
                      >
                        {val}%
                      </Button>
                    ))}
                  </div>
                </div>

                {/* Bet Amount */}
                <div className="flex items-center gap-2 h-7 mt-1.5 mb-0.5">
                  <div className="flex-1 relative">
                    <span className="absolute left-2 top-1.5 text-[10px] text-muted-foreground font-bold">BET</span>
                    <Input
                      type="number"
                      value={betAmount}
                      onChange={(e) => setBetAmount(Number(e.target.value))}
                      className="h-7 pl-10 pr-2 text-xs font-mono bg-black/40 border-white/5 focus-visible:ring-primary/50 text-right"
                    />
                  </div>
                  <div className="flex gap-1">
                    <Button
                      size="sm" variant="outline"
                      onClick={() => setBetAmount(Math.floor(userPoints * 0.1))}
                      className="h-7 px-2 text-[10px] border-white/5 bg-white/5 hover:bg-white/10"
                    >10%</Button>
                    <Button
                      size="sm" variant="outline"
                      onClick={() => setBetAmount(Math.floor(userPoints * 0.2))}
                      className="h-7 px-2 text-[10px] border-white/5 bg-white/5 hover:bg-white/10 text-amber-500"
                    >MAX</Button>
                  </div>
                </div>

                <Button
                  onClick={handleSubmitPrediction}
                  disabled={isSubmitting || !selectedDirection || !selectedPercent}
                  className="w-full h-8 text-xs font-bold bg-primary hover:bg-primary/90 shadow-[0_0_20px_rgba(var(--primary),0.4)] transition-all hover:scale-[1.02] disabled:hover:scale-100 disabled:opacity-50 text-black mt-0"
                >
                  {isSubmitting ? <Loader2 className="animate-spin w-3 h-3" /> : `LOCK IT IN (-${betAmount} pts)`}
                </Button>
              </CardContent>
            </Card>

            {/* Bottom Half: Active Predictions (Flex Fill) */}
            <Card className="flex-1 min-h-0 bg-card/20 border-white/60 overflow-hidden flex flex-col">
              <CardHeader className="py-1 px-3 bg-black/20 border-b border-white/10 shrink-0 min-h-[36px] flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-xs font-bold flex items-center gap-2 uppercase tracking-wider text-white">
                  <History className="w-3 h-3 text-primary" /> Active Predictions
                </CardTitle>
                <Link href="/match-history">
                  <Button variant="ghost" size="sm" className="h-5 text-[10px] px-2 text-muted-foreground hover:text-white hover:bg-white/10">
                    All History <ArrowUp className="w-3 h-3 rotate-45 ml-1" />
                  </Button>
                </Link>
              </CardHeader>

              <CardContent className="p-0 flex-1 relative min-h-0 flex flex-col">
                <Tabs defaultValue="active" className="w-full h-full flex flex-col">
                  <div className="px-3 border-b border-white/5 bg-black/40 pt-1 shrink-0">
                    <TabsList className="h-7 bg-white/5">
                      <TabsTrigger value="active" className="h-6 text-[10px]">
                        Active
                        {predictions.filter(p => p.status === 'pending').length > 0 && (
                          <Badge className="ml-1.5 h-4 px-1 min-w-[16px] bg-primary/20 text-primary border-0">{predictions.filter(p => p.status === 'pending').length}</Badge>
                        )}
                      </TabsTrigger>
                      <TabsTrigger value="history" className="h-6 text-[10px]">History</TabsTrigger>
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
                          {predictions.filter(p => p.status === 'pending').length === 0 ? (
                            <div className="text-center py-8 space-y-2">
                              <div className="w-10 h-10 mx-auto rounded-full bg-white/5 flex items-center justify-center">
                                <Sparkles className="w-5 h-5 text-white/20" />
                              </div>
                              <p className="text-xs text-muted-foreground">No active predictions</p>
                            </div>
                          ) : (
                            predictions.filter(p => p.status === 'pending').map((pred) => (
                              <div key={pred.id} className="grid grid-cols-5 items-center p-2.5 text-xs hover:bg-white/5 transition-colors text-center border-l-2 border-transparent hover:border-primary/50 relative group">
                                <div className="absolute inset-0 bg-gradient-to-r from-primary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
                                {/* Time */}
                                <span className="text-gray-400 font-mono text-[10px]">{new Date(pred.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>

                                {/* Asset */}
                                <span className="font-bold text-white tracking-tight">{pred.asset_symbol}</span>

                                {/* Timeframe */}
                                <span className="text-muted-foreground text-[10px]">{pred.timeframe || '-'}</span>

                                {/* Pick */}
                                <div className="flex justify-center gap-1">
                                  {pred.direction === 'UP' ? (
                                    <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20 px-1 py-0 h-4 font-mono text-[9px]">
                                      <ArrowUp className="w-2.5 h-2.5 mr-0.5" /> {pred.target_percent}%
                                    </Badge>
                                  ) : (
                                    <Badge variant="outline" className="bg-red-500/10 text-red-500 border-red-500/20 px-1 py-0 h-4 font-mono text-[9px]">
                                      <ArrowDown className="w-2.5 h-2.5 mr-0.5" /> {pred.target_percent}%
                                    </Badge>
                                  )}
                                </div>

                                {/* Status */}
                                <div className="flex justify-center">
                                  <span className="text-[9px] font-bold text-amber-500 animate-pulse bg-amber-500/10 px-1.5 py-0.5 rounded border border-amber-500/20">Active</span>
                                </div>
                              </div>
                            ))
                          )}
                        </div>
                      </TabsContent>
                      <TabsContent value="history" className="m-0 border-0 h-full">
                        <div className="divide-y divide-white/5">
                          {predictions.filter(p => p.status !== 'pending').length === 0 ? (
                            <p className="text-xs text-muted-foreground text-center py-8">No history yet.</p>
                          ) : (
                            predictions.filter(p => p.status !== 'pending').map((pred) => (
                              <div key={pred.id} className="grid grid-cols-5 items-center p-2.5 text-xs hover:bg-white/5 transition-colors text-center text-muted-foreground">
                                <span className="text-[10px] font-mono opacity-50">{new Date(pred.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                <span className="font-bold">{pred.asset_symbol}</span>
                                <span>{pred.timeframe}</span>
                                <div className="flex justify-center">
                                  {pred.direction === 'UP' ? <ArrowUp className="w-3 h-3 text-emerald-500/50" /> : <ArrowDown className="w-3 h-3 text-red-500/50" />}
                                </div>
                                <div className="flex justify-center">
                                  <span className={cn("text-[9px] font-bold px-1.5 py-0.5 rounded border",
                                    pred.status === 'win' ? "bg-emerald-500/10 text-emerald-500 border-emerald-500/20" :
                                      pred.status === 'loss' ? "bg-red-500/10 text-red-500 border-red-500/20" : "bg-white/5 border-white/10"
                                  )}>
                                    {pred.status.toUpperCase()}
                                  </span>
                                </div>
                              </div>
                            ))
                          )}
                        </div>
                      </TabsContent>
                    </ScrollArea>
                  </div>
                </Tabs>
              </CardContent>
            </Card>

          </div>

          {/* Right Column: Chart (Full Height) */}
          <div className="md:col-span-8 h-full">
            <div className="h-full relative group shadow-2xl border border-white/10 rounded-xl overflow-hidden bg-black/40">
              {/* @ts-ignore */}
              <TradingViewWidget
                symbol={selectedAsset.tvSymbol || selectedAsset.symbol}
                interval={selectedTimeframe}
              />
            </div>
          </div>
        </section>

        {/* 5. Live Stats Panel */}
        <section>
          <StatsPanel assetSymbol={selectedAsset.symbol} timeframe={selectedTimeframe} />
        </section>

        {/* 6. Live Feed Section */}
        <section className="pt-8 border-t border-white/5">
          <div className="max-w-2xl mx-auto space-y-6">

            {/* Comment Input Area */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="text-center md:text-left space-y-1">
                  <h3 className="text-xl font-bold">Share Alpha</h3>
                  <p className="text-muted-foreground text-sm">Explain your move to the community.</p>
                </div>
                <Card className="bg-card/20 border-white/5 h-fit">
                  <CardContent className="p-4 space-y-4">
                    <Textarea
                      placeholder="Share your reasoning for your latest pick..."
                      className="bg-black/20 border-white/10 min-h-[120px] resize-none focus:border-primary/50"
                      maxLength={140}
                      value={comment}
                      onChange={(e) => setComment(e.target.value)}
                    />
                    <div className="flex justify-between items-center">
                      <span className="text-xs text-muted-foreground">{comment.length}/140</span>
                      <Button
                        size="sm"
                        variant="secondary"
                        className="bg-white/10 hover:bg-white/20 text-white"
                        onClick={handlePostComment}
                        disabled={isSubmitting || !comment.trim()}
                      >
                        {isSubmitting ? <Loader2 className="w-3 h-3 animate-spin" /> : "Post Comment"}
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Real Feed - Scrollable Big Box */}
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-bold">Live Feed</h3>
                  {/* Force Resolve removed - handled by Server Cron */}
                </div>

                <Card className="bg-card/10 border-white/5 h-[500px] flex flex-col">
                  <CardContent className="p-0 flex-1 min-h-0 relative">
                    <ScrollArea className="h-full w-full p-4">
                      <div className="space-y-3">
                        {feed.length === 0 ? (
                          <div className="text-center text-muted-foreground py-20 flex flex-col items-center gap-2">
                            <div className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center">
                              <History className="w-5 h-5 opacity-50" />
                            </div>
                            <p>No alpha shared yet.</p>
                          </div>
                        ) : (
                          feed.map((item) => (
                            <div key={item.id} className="flex gap-3 p-3 rounded-lg bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-colors">
                              <div className="w-8 h-8 rounded-full bg-gradient-to-b from-gray-700 to-gray-800 flex-shrink-0 flex items-center justify-center font-bold text-xs text-white/50 border border-white/5">
                                {item.profiles?.username?.[0]?.toUpperCase() || 'U'}
                              </div>
                              <div className="space-y-1 w-full min-w-0">
                                <div className="flex items-center justify-between gap-2">
                                  <div className="flex items-center gap-2 min-w-0">
                                    <span className="font-bold text-sm truncate">{item.profiles?.username || 'Anon'}</span>
                                    <span className="text-[10px] text-muted-foreground whitespace-nowrap">{new Date(item.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                  </div>
                                  <Badge variant="outline" className={cn(
                                    "text-[9px] px-1.5 py-0 h-4 whitespace-nowrap shrink-0",
                                    item.direction === 'UP' ? "border-emerald-500/30 text-emerald-500 bg-emerald-500/5" : "border-red-500/30 text-red-500 bg-red-500/5"
                                  )}>
                                    {item.asset_symbol} {item.direction}
                                  </Badge>
                                </div>
                                <p className="text-sm text-gray-300 leading-snug break-words">
                                  {item.comment}
                                </p>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </ScrollArea>
                  </CardContent>
                </Card>
              </div>
            </div>
          </div>
        </section>

      </div >
    </main >
  );
}

export function HeroCTA() {
  return (
    <motion.p
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.4 }}
      className="mt-6 text-sm md:text-base text-muted-foreground font-medium"
    >
      Place your first prediction below.
    </motion.p>
  );
}

export function ScrollHintArrow() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ delay: 1 }}
      className="flex justify-center mt-4"
    >
      <ChevronDown className="w-6 h-6 text-primary animate-bounce" />
    </motion.div>
  );
}
