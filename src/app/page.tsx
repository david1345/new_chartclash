"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import {
  ArrowRight,
  BrainCircuit,
  CandlestickChart,
  Clock3,
  Flame,
  Gavel,
  ShieldCheck,
  Target,
  TrendingDown,
  TrendingUp,
  Trophy,
  Users,
  Zap,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { MarketHeader } from "@/components/dashboard/market-header";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";
import { cn } from "@/lib/utils";

const FEATURED_BATTLE = {
  title: "Will BTC close above $110,000 by next Friday?",
  eyebrow: "Featured Battle",
  closeLabel: "Closes in 4d 12h",
  bull: {
    title: "ETF flows keep the bid alive",
    summary: "Spot demand absorbs dips and momentum traders defend every higher low.",
    accent: "Bull Camp",
  },
  bear: {
    title: "Breakout stalls under heavy overhead supply",
    summary: "Macro hesitation and profit taking reject the move before weekly close.",
    accent: "Bear Camp",
  },
  href: "/play/BTCUSDT/1h",
};

const CATALYSTS = [
  {
    title: "Macro Calendar",
    body: "FOMC, CPI, jobs, and yields create the major timing windows for high-conviction clashes.",
    icon: Clock3,
  },
  {
    title: "Crypto Flow",
    body: "ETF flows, funding resets, liquidations, and stablecoin issuance shape short-term pressure.",
    icon: CandlestickChart,
  },
  {
    title: "Resolution Rules",
    body: "Every market ships with a fixed source, fallback policy, and dispute handling before it opens.",
    icon: Gavel,
  },
];

const TRENDING_BATTLES = [
  {
    title: "ETH vs BTC: Who leads the next 7 days?",
    subtitle: "Outperform Market",
    split: "56 / 44",
    closeLabel: "7d",
    href: "/play/ETHUSDT/4h",
  },
  {
    title: "Will SOL confirm rotation leadership this week?",
    subtitle: "Catalyst Clash",
    split: "61 / 39",
    closeLabel: "4d",
    href: "/play/SOLUSDT/1h",
  },
  {
    title: "Does macro softness unlock a BTC breakout?",
    subtitle: "Event Battle",
    split: "49 / 51",
    closeLabel: "48h",
    href: "/play/BTCUSDT/1h",
  },
];

const MARKET_GRID = [
  {
    category: "BTC",
    title: "Breakout, range, and catalyst-driven BTC thesis markets.",
    href: "/play/BTCUSDT/1h",
  },
  {
    category: "ETH",
    title: "Relative strength, beta trades, and rotation battles around ETH.",
    href: "/play/ETHUSDT/4h",
  },
  {
    category: "SOL",
    title: "Momentum-heavy markets built for leadership shifts and sentiment squeezes.",
    href: "/play/SOLUSDT/1h",
  },
  {
    category: "Macro",
    title: "FOMC, CPI, yields, and risk appetite translated into thesis battles.",
    href: "/community?tab=analyst-hub",
  },
];

const LEADERBOARD_PREVIEW = [
  { name: "MacroNomad", speciality: "Macro Thesis", score: "+18.4%", accuracy: "74%" },
  { name: "ETHFlow", speciality: "Rotation", score: "+15.2%", accuracy: "69%" },
  { name: "SignalMint", speciality: "BTC Reader", score: "+13.7%", accuracy: "71%" },
];

interface HomeLiveRound {
  asset_symbol: string;
  timeframe: string;
  asset_name: string;
  asset_type: string;
  participant_count: number;
  total_volume: number;
}

interface DocketQueueItem {
  title: string;
  subtitle: string;
  status: string;
  supportingNote: string;
  href: string;
}

const UPCOMING_QUEUE: DocketQueueItem[] = [
  {
    title: "BTC breakout battle reopens at the next hourly handoff",
    subtitle: "Queue primed for ETF flow and macro softness",
    status: "Opens in the next 1H cycle",
    supportingNote: "Curated seed docket",
    href: "/play/BTCUSDT/1h",
  },
  {
    title: "ETH vs BTC leadership clash",
    subtitle: "Relative-strength market with a clean weekly framing",
    status: "Next wave in 4H",
    supportingNote: "Rotation surface",
    href: "/play/ETHUSDT/4h",
  },
  {
    title: "SOL momentum continuation window",
    subtitle: "Designed for squeeze-versus-exhaustion debate",
    status: "Queued for the next 1H open",
    supportingNote: "Catalyst lane",
    href: "/play/SOLUSDT/1h",
  },
  {
    title: "Macro spillover radar",
    subtitle: "Analyst-seeded thesis around rates, CPI, and dollar pressure",
    status: "Open via Analyst Hub",
    supportingNote: "Macro surface",
    href: "/community?tab=analyst-hub",
  },
];

function formatCompactVolume(value: number) {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M USDT`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}k USDT`;
  return `${value.toFixed(0)} USDT`;
}

function LandingContent() {
  const [user, setUser] = useState<any>(null);
  const [liveRounds, setLiveRounds] = useState<HomeLiveRound[]>([]);
  const [docketLoading, setDocketLoading] = useState(true);
  const supabase = createClient();

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;

      setUser(data.user);

      const { data: profile } = await supabase
        .from("profiles")
        .select("id")
        .eq("id", data.user.id)
        .maybeSingle();

      if (!profile) {
        await supabase.from("profiles").insert({
          id: data.user.id,
          email: data.user.email,
          username: data.user.email?.split("@")[0] || "trader",
        });
      }
    });
  }, [supabase]);

  useEffect(() => {
    let cancelled = false;

    const fetchLiveRounds = async () => {
      try {
        const response = await fetch("/api/market/live-rounds?category=ALL&limit=8");
        const json = await response.json();

        if (cancelled) return;

        if (json.success && Array.isArray(json.data)) {
          setLiveRounds(json.data);
        } else {
          setLiveRounds([]);
        }
      } catch (error) {
        if (!cancelled) {
          console.error("Failed to fetch home live rounds:", error);
          setLiveRounds([]);
        }
      } finally {
        if (!cancelled) {
          setDocketLoading(false);
        }
      }
    };

    fetchLiveRounds();
    const interval = window.setInterval(fetchLiveRounds, 45000);

    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, []);

  const { userPoints, userRank, username, activeCount } = useUserStats(user);
  const hasLiveRounds = liveRounds.length > 0;
  const docketQueue: DocketQueueItem[] = hasLiveRounds
    ? liveRounds.slice(0, 4).map((round) => ({
      title: `${round.asset_name} ${round.timeframe.toUpperCase()} thesis window`,
      subtitle: `${round.participant_count} traders active on ${round.asset_symbol}`,
      status: round.total_volume > 0 ? formatCompactVolume(Number(round.total_volume)) : "Live now",
      supportingNote: round.asset_type,
      href: `/play/${round.asset_symbol}/${round.timeframe}`,
    }))
    : UPCOMING_QUEUE;
  const liveSignalCount = hasLiveRounds ? liveRounds.length : docketQueue.length;
  const totalDocketVolume = hasLiveRounds
    ? liveRounds.reduce((sum, round) => sum + Number(round.total_volume || 0), 0)
    : 128000;
  const queueStatusLabel = docketLoading
    ? "Syncing live docket"
    : hasLiveRounds
      ? "Live markets across active surfaces"
      : "Seeded queue keeps the docket warm";
  const queueModeLabel = hasLiveRounds ? "Live now" : "Curated queue";

  return (
    <main className="min-h-[100dvh] overflow-x-hidden bg-[#060914] text-white selection:bg-[#00E5B4]/30">
      <div className="relative isolate">
        <div className="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(circle_at_top_left,_rgba(0,229,180,0.18),_transparent_30%),radial-gradient(circle_at_top_right,_rgba(255,91,91,0.14),_transparent_24%),linear-gradient(180deg,_#08101F_0%,_#060914_55%,_#05070F_100%)]" />
        <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-64 bg-[linear-gradient(90deg,rgba(255,255,255,0.06)_1px,transparent_1px),linear-gradient(180deg,rgba(255,255,255,0.05)_1px,transparent_1px)] bg-[size:72px_72px] opacity-[0.06]" />

        <MarketHeader
          user={user}
          username={username}
          userPoints={userPoints}
          userRank={userRank}
          activeCount={activeCount}
        />

        <div className="container mx-auto max-w-7xl px-4 py-4 lg:px-6 lg:py-8">
          <section className="grid gap-4 lg:grid-cols-[1.15fr_0.85fr]">
            <div className="rounded-[30px] border border-white/10 bg-[#091120]/90 p-6 shadow-[0_32px_100px_rgba(0,0,0,0.45)] lg:p-8">
              <div className="flex flex-wrap items-center gap-2">
                <div className="inline-flex items-center gap-2 rounded-full border border-[#00E5B4]/20 bg-[#00E5B4]/10 px-3 py-1 text-[11px] font-black uppercase tracking-[0.2em] text-[#9FF8E2]">
                  <BrainCircuit className="h-3.5 w-3.5" />
                  Signal Deck
                </div>
                <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-black uppercase tracking-[0.18em] text-[#B8C9DA]">
                  <ShieldCheck className="h-3.5 w-3.5 text-[#00E5B4]" />
                  Curated conviction markets
                </div>
              </div>

              <div className="mt-8 grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
                <div>
                  <div className="text-[11px] font-black uppercase tracking-[0.2em] text-[#6F849D]">
                    Conviction over consensus
                  </div>
                  <h1 className="mt-3 max-w-3xl text-4xl font-black uppercase tracking-[-0.05em] text-white sm:text-5xl lg:text-6xl">
                    Markets as
                    <span className="block text-[#00E5B4]">scenario collisions.</span>
                  </h1>
                  <p className="mt-4 max-w-2xl text-sm leading-6 text-[#9CB1C9] sm:text-base">
                    Forget generic up/down cards. ChartClash is a live docket of competing market
                    scenarios, where every clash has a catalyst, a resolution rule, and two sides
                    willing to stake real conviction.
                  </p>

                  <div className="mt-6 flex flex-col gap-3 sm:flex-row">
                    <Link
                      href={FEATURED_BATTLE.href}
                      className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-[#00E5B4] px-5 text-sm font-black uppercase tracking-[0.16em] text-black transition-transform hover:scale-[1.01]"
                    >
                      Open live docket
                      <ArrowRight className="h-4 w-4" />
                    </Link>
                    <Link
                      href="/play/BTCUSDT/1h"
                      className="inline-flex h-12 items-center justify-center gap-2 rounded-xl border border-white/10 bg-white/5 px-5 text-sm font-black uppercase tracking-[0.16em] text-white transition-colors hover:bg-white/10"
                    >
                      Enter arena
                      <Zap className="h-4 w-4 text-[#00E5B4]" />
                    </Link>
                  </div>
                </div>

                <div className="grid gap-3">
                  <div className="rounded-[24px] border border-white/10 bg-black/20 p-4">
                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6C819A]">
                      Active signal board
                    </div>
                    <div className="mt-2 flex items-end justify-between gap-4">
                      <div className="text-4xl font-black text-white">{docketLoading ? "..." : liveSignalCount}</div>
                      <Users className="h-5 w-5 text-[#00E5B4]" />
                    </div>
                    <div className="mt-1 text-xs leading-5 text-[#8CA0B7]">
                      {queueStatusLabel}
                    </div>
                  </div>
                  <div className="rounded-[24px] border border-white/10 bg-black/20 p-4">
                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6C819A]">
                      Current stack
                    </div>
                    <div className="mt-2 text-2xl font-black text-white">
                      {user ? `${userPoints.toFixed(2)} USDT` : "Connect wallet"}
                    </div>
                    <div className="mt-1 text-xs text-[#8CA0B7]">
                      {user ? `${username || "Trader"} · live contract balance` : "Sign in and connect MetaMask to fund your staking balance"}
                    </div>
                  </div>
                  <div className="rounded-[24px] border border-white/10 bg-black/20 p-4">
                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6C819A]">
                      Docket flow
                    </div>
                    <div className="mt-2 text-2xl font-black text-white">
                      {docketLoading ? "Syncing" : formatCompactVolume(totalDocketVolume)}
                    </div>
                    <div className="mt-1 text-xs leading-5 text-[#8CA0B7]">
                      {hasLiveRounds ? "Visible stack across live rounds" : "Fallback queue volume target while live stack forms"}
                    </div>
                  </div>
                  <div className="rounded-[24px] border border-white/10 bg-black/20 p-4">
                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6C819A]">
                      Market grammar
                    </div>
                    <div className="mt-3 flex flex-wrap gap-2">
                      <span className="rounded-full border border-[#00E5B4]/20 bg-[#00E5B4]/10 px-3 py-1 text-[11px] font-bold text-[#9FF8E2]">
                        Thesis
                      </span>
                      <span className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-bold text-white">
                        Binary
                      </span>
                      <span className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-bold text-white">
                        Range
                      </span>
                      <span className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-bold text-white">
                        Outperform
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid gap-4">
              <div className="rounded-[30px] border border-white/10 bg-[#111827]/90 p-5 shadow-[0_24px_70px_rgba(0,0,0,0.4)]">
                <div className="flex items-center justify-between gap-3">
                  <div className="text-[11px] font-black uppercase tracking-[0.18em] text-[#7E92AB]">
                    Live docket
                  </div>
                  <div className="rounded-full border border-[#00E5B4]/20 bg-[#00E5B4]/10 px-3 py-1 text-[10px] font-black uppercase tracking-[0.16em] text-[#9FF8E2]">
                    {queueModeLabel}
                  </div>
                </div>

                <div className="mt-4 rounded-[22px] border border-white/10 bg-black/20 p-4">
                  <h2 className="text-2xl font-black tracking-[-0.03em] text-white">
                    {FEATURED_BATTLE.title}
                  </h2>
                  <div className="mt-4 grid gap-3">
                    <div className="rounded-2xl border border-[#00E5B4]/20 bg-[#00E5B4]/8 p-4">
                      <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.16em] text-[#9FF8E2]">
                        <TrendingUp className="h-3.5 w-3.5" />
                        Bull Signal
                      </div>
                      <div className="mt-2 text-sm font-black text-white">{FEATURED_BATTLE.bull.title}</div>
                      <p className="mt-1 text-xs leading-5 text-[#A7BDD6]">{FEATURED_BATTLE.bull.summary}</p>
                    </div>
                    <div className="rounded-2xl border border-[#FF6B6B]/20 bg-[#FF6B6B]/8 p-4">
                      <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.16em] text-[#FFC2C2]">
                        <TrendingDown className="h-3.5 w-3.5" />
                        Bear Signal
                      </div>
                      <div className="mt-2 text-sm font-black text-white">{FEATURED_BATTLE.bear.title}</div>
                      <p className="mt-1 text-xs leading-5 text-[#A7BDD6]">{FEATURED_BATTLE.bear.summary}</p>
                    </div>
                  </div>
                </div>

                <div className="mt-4 rounded-[22px] border border-white/10 bg-[#07111C] p-4">
                  <div className="flex items-center justify-between gap-3">
                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6F849D]">
                      Queue monitor
                    </div>
                    <div className="text-[10px] font-black uppercase tracking-[0.16em] text-[#9FF8E2]">
                      {hasLiveRounds ? "Routing to live rounds" : "Routing to seeded upcoming clashes"}
                    </div>
                  </div>
                  <div className="mt-3 space-y-2">
                    {docketQueue.map((item) => (
                      <Link
                        key={item.title}
                        href={item.href}
                        className="flex items-start justify-between gap-3 rounded-2xl border border-white/10 bg-black/20 px-4 py-3 transition-colors hover:bg-white/[0.06]"
                      >
                        <div>
                          <div className="text-sm font-black text-white">{item.title}</div>
                          <div className="mt-1 text-xs leading-5 text-[#97ADC5]">{item.subtitle}</div>
                        </div>
                        <div className="shrink-0 text-right">
                          <div className="text-[10px] font-black uppercase tracking-[0.16em] text-white">{item.status}</div>
                          <div className="mt-1 text-[10px] uppercase tracking-[0.16em] text-[#6E839C]">{item.supportingNote}</div>
                        </div>
                      </Link>
                    ))}
                  </div>
                </div>
              </div>

              <div className="grid gap-3 sm:grid-cols-3">
                <div className="rounded-[24px] border border-white/10 bg-[#0E1521]/90 p-4 text-center">
                  <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#637790]">Surface</div>
                  <div className="mt-2 text-sm font-black text-white">Crypto + Macro</div>
                </div>
                <div className="rounded-[24px] border border-white/10 bg-[#0E1521]/90 p-4 text-center">
                  <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#637790]">Rules</div>
                  <div className="mt-2 text-sm font-black text-white">Fixed Source</div>
                </div>
                <div className="rounded-[24px] border border-white/10 bg-[#0E1521]/90 p-4 text-center">
                  <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#637790]">Style</div>
                  <div className="mt-2 text-sm font-black text-white">Scenario Duel</div>
                </div>
              </div>
            </div>
          </section>

          <section className="mt-5 grid gap-4 lg:grid-cols-[0.95fr_1.05fr]">
            <div className="rounded-[28px] border border-white/10 bg-[#0A1320]/85 p-6">
              <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                <CandlestickChart className="h-4 w-4 text-[#00E5B4]" />
                Catalyst radar
              </div>
              <div className="mt-5 space-y-3">
                {CATALYSTS.map(({ title, body, icon: Icon }) => (
                  <div
                    key={title}
                    className="grid gap-3 rounded-[22px] border border-white/10 bg-black/20 p-4 sm:grid-cols-[auto_1fr]"
                  >
                    <div className="inline-flex rounded-xl border border-white/10 bg-white/5 p-2">
                      <Icon className="h-4 w-4 text-[#00E5B4]" />
                    </div>
                    <div>
                      <h3 className="text-lg font-black text-white">{title}</h3>
                      <p className="mt-1 text-sm leading-6 text-[#8FA4BC]">{body}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-[28px] border border-white/10 bg-[#0B111D]/90 p-6">
              <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                <Flame className="h-4 w-4 text-[#FF7A5C]" />
                Battle lanes
              </div>
              <div className="mt-5 grid gap-3">
                {TRENDING_BATTLES.map((battle, index) => (
                  <Link
                    key={battle.title}
                    href={battle.href}
                    className={cn(
                      "rounded-[22px] border p-4 transition-all hover:-translate-y-0.5",
                      index === 0 ? "border-[#00E5B4]/20 bg-[#091522]" : "border-white/10 bg-black/20"
                    )}
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#768AA2]">
                        {battle.subtitle}
                      </div>
                      <div className="rounded-full border border-white/10 bg-white/5 px-2.5 py-1 text-[10px] font-black uppercase tracking-[0.16em] text-white">
                        {battle.closeLabel}
                      </div>
                    </div>
                    <h3 className="mt-3 text-lg font-black tracking-[-0.03em] text-white">{battle.title}</h3>
                    <div className="mt-4 flex items-center justify-between text-xs text-[#97ADC5]">
                      <span>Bull / Bear split</span>
                      <span className="font-black text-white">{battle.split}</span>
                    </div>
                    <div className="mt-2 h-2 rounded-full bg-white/10">
                      <div
                        className="h-2 rounded-full bg-gradient-to-r from-[#00E5B4] to-[#1E8BFF]"
                        style={{ width: `${Number(battle.split.split("/")[0].trim())}%` }}
                      />
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          </section>

          <section className="mt-6 grid gap-4 lg:grid-cols-[1.05fr_0.95fr]">
            <div className="rounded-[28px] border border-white/10 bg-[#0A1020]/90 p-6">
              <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                <Target className="h-4 w-4 text-[#00E5B4]" />
                Launch surfaces
              </div>
              <div className="mt-5 grid gap-3 sm:grid-cols-2">
                {MARKET_GRID.map((item) => (
                  <Link
                    key={item.category}
                    href={item.href}
                    className="rounded-[22px] border border-white/10 bg-black/20 p-4 transition-colors hover:bg-white/[0.07]"
                  >
                    <div className="text-[11px] font-black uppercase tracking-[0.18em] text-[#9FF8E2]">
                      {item.category}
                    </div>
                    <p className="mt-2 text-sm leading-6 text-[#9CB1C9]">{item.title}</p>
                  </Link>
                ))}
              </div>
            </div>

            <div className="grid gap-4">
              <div className="rounded-[28px] border border-white/10 bg-[#111827]/90 p-6">
                <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                  <Trophy className="h-4 w-4 text-[#F6C453]" />
                  Ranking capsules
                </div>
                <div className="mt-4 space-y-3">
                  {LEADERBOARD_PREVIEW.map((entry, index) => (
                    <div
                      key={entry.name}
                      className="flex items-center justify-between rounded-2xl border border-white/10 bg-black/20 px-4 py-3"
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-white/5 text-sm font-black text-white">
                          {index + 1}
                        </div>
                        <div>
                          <div className="text-sm font-black text-white">{entry.name}</div>
                          <div className="text-xs text-[#8FA4BC]">{entry.speciality}</div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-sm font-black text-[#00E5B4]">{entry.score}</div>
                        <div className="text-xs text-[#8FA4BC]">{entry.accuracy} hit rate</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="rounded-[28px] border border-white/10 bg-[#0A1422]/90 p-6">
                <div className="text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                  Why this feels different
                </div>
                <div className="mt-4 grid gap-3">
                  <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
                    <div className="text-sm font-black text-white">A market is a scenario, not a slot machine</div>
                    <p className="mt-2 text-sm leading-6 text-[#90A4BC]">
                      Each clash is framed by a catalyst, a timing window, and a fixed rulebook.
                    </p>
                  </div>
                  <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
                    <div className="text-sm font-black text-white">Your position is a public argument</div>
                    <p className="mt-2 text-sm leading-6 text-[#90A4BC]">
                      Thesis, invalidation, and conviction turn every trade into a readable view.
                    </p>
                  </div>
                  <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
                    <div className="text-sm font-black text-white">Performance becomes a reputation layer</div>
                    <p className="mt-2 text-sm leading-6 text-[#90A4BC]">
                      P&amp;L, hit rate, and category strength matter more than noisy crowd chatter.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </main>
  );
}

export default function LandingHub() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-[100dvh] items-center justify-center bg-[#080C14] text-[#5A7090]">
          Loading Arena...
        </div>
      }
    >
      <LandingContent />
    </Suspense>
  );
}
