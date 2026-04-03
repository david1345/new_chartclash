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
import {
    ArrowUpRight,
    BarChart3,
    BrainCircuit,
    CandlestickChart,
    Clock3,
    Gavel,
    Scale,
    ShieldCheck,
    Target,
    TrendingDown,
    TrendingUp,
    Wallet2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { User } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/client";
import { ASSETS, Asset } from "@/lib/constants";
import { isMarketOpen } from "@/lib/market-hours";
import { isAllowedAdminEmail } from "@/lib/admin-client";

// Refactored Components
import { MarketHeader } from "@/components/dashboard/market-header";
import { PredictionTabs } from "@/components/dashboard/prediction-tabs";
import { DesktopActivePosition } from "@/components/battle/desktop-active-position";

// Custom Hooks
import { usePredictionLock } from "@/hooks/dashboard/use-prediction-lock";
import { useUserStats } from "@/hooks/dashboard/use-user-stats";
import { usePredictionHistory } from "@/hooks/dashboard/use-prediction-history";
import { useRoomFeed } from "@/hooks/dashboard/use-room-feed";
import { useMounted } from "@/hooks/use-mounted";

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
}

interface ThesisCardData {
    label: string;
    title: string;
    summary: string;
    catalyst: string;
    invalidation: string;
    stake: string;
}

interface RoundCadence {
    openWindow: string;
    lockWindow: string;
    resolveWindow: string;
    integrityNote: string;
}

interface ThesisLevel {
    label: string;
    value: string;
    tone: "bull" | "bear" | "neutral";
}

function formatDisplaySymbol(symbol: string) {
    return symbol.endsWith("USDT") ? `${symbol.slice(0, -4)}/USDT` : symbol;
}

function formatReferencePrice(value?: number | null) {
    if (!value) return "Loading...";
    return value >= 1000
        ? `$${value.toLocaleString(undefined, { maximumFractionDigits: 0 })}`
        : `$${value.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
}

function getResolutionSource(asset: Asset) {
    if (asset.type === "CRYPTO") return "Binance candle close";
    if (asset.type === "STOCK") return "Primary US cash session close";
    return "Primary commodity session settlement";
}

function getReferenceShiftPercent(timeframe: string) {
    if (timeframe.endsWith("m")) {
        const minutes = parseInt(timeframe.replace("m", ""), 10);
        return Math.max(0.2, minutes / 45);
    }

    if (timeframe.endsWith("h")) {
        const hours = parseInt(timeframe.replace("h", ""), 10);
        return Math.max(0.35, hours * 0.28);
    }

    if (timeframe.endsWith("d")) {
        const days = parseInt(timeframe.replace("d", ""), 10);
        return Math.max(1, days * 0.9);
    }

    return 0.5;
}

function buildThesisLevels(referencePrice: number | null, timeframe: string): ThesisLevel[] {
    if (!referencePrice) {
        return [
            { label: "Reference", value: "Syncing...", tone: "neutral" },
            { label: "Long trigger", value: "Waiting for open", tone: "bull" },
            { label: "Short reclaim", value: "Waiting for open", tone: "bear" },
        ];
    }

    const shiftPercent = getReferenceShiftPercent(timeframe);
    const longTrigger = referencePrice * (1 + shiftPercent / 100);
    const shortReclaim = referencePrice * (1 - shiftPercent / 100);

    return [
        { label: "Reference", value: formatReferencePrice(referencePrice), tone: "neutral" },
        { label: "Long trigger", value: formatReferencePrice(longTrigger), tone: "bull" },
        { label: "Short reclaim", value: formatReferencePrice(shortReclaim), tone: "bear" },
    ];
}

function buildRoundCadence(timeframe: string): RoundCadence {
    const upper = timeframe.toUpperCase();

    if (timeframe.endsWith("m")) {
        return {
            openWindow: `${upper} rolling round`,
            lockWindow: "Final 10% blocks fresh size",
            resolveWindow: "Settles on the close print",
            integrityNote: "Short rounds reward timing discipline and punish late chase.",
        };
    }

    if (timeframe.endsWith("h")) {
        return {
            openWindow: `${upper} decision window`,
            lockWindow: "Final 10% becomes no-snipe zone",
            resolveWindow: "Resolves against the hourly close",
            integrityNote: "Use the chart to judge acceptance versus failed breakout before the lock.",
        };
    }

    return {
        openWindow: `${upper} thesis window`,
        lockWindow: "Late entries shut off before settlement",
        resolveWindow: "Resolves against the scheduled closing print",
        integrityNote: "Longer windows reward cleaner scenario building over pure reaction speed.",
    };
}

function buildCampCards(asset: Asset, timeframe: string) {
    const horizon = timeframe.toUpperCase();
    const displaySymbol = formatDisplaySymbol(asset.symbol);

    const bullCards: ThesisCardData[] = [
        {
            label: "Momentum Thesis",
            title: `${asset.name} keeps initiative into the next ${horizon}`,
            summary: `${displaySymbol} holds its higher-low structure and forces late shorts to chase confirmation.`,
            catalyst: asset.type === "CRYPTO" ? "Spot inflows stay firm and liquidations cluster above local resistance." : "Risk appetite improves and buyers defend the opening drive.",
            invalidation: `Immediate rejection back below the opening range of this ${horizon} market.`,
            stake: "$42k aligned",
        },
        {
            label: "Catalyst Thesis",
            title: `Narrative flow rotates toward ${asset.name}`,
            summary: `A clean catalyst window can turn passive interest into directional follow-through instead of another fade.`,
            catalyst: asset.type === "CRYPTO" ? "Funding cools while spot-led bids remain sticky." : "Macro data lands benign and sellers lose control of the tape.",
            invalidation: "Catalyst passes without expansion in volume or follow-through candles.",
            stake: "$28k aligned",
        },
    ];

    const bearCards: ThesisCardData[] = [
        {
            label: "Fade Thesis",
            title: `${asset.name} stalls before acceptance`,
            summary: `The move looks more like squeeze exhaustion than durable demand, inviting a sharp retrace.`,
            catalyst: asset.type === "CRYPTO" ? "Perp leverage leads while spot confirmation stays weak." : "Sellers reassert after the first impulse and reclaim VWAP.",
            invalidation: "Buyers hold above resistance-turned-support through the next reaction test.",
            stake: "$39k aligned",
        },
        {
            label: "Macro Risk Thesis",
            title: `Cross-asset pressure caps ${displaySymbol}`,
            summary: `A hostile macro tape can overpower chart setups and force traders back into defense.`,
            catalyst: asset.type === "CRYPTO" ? "Dollar strength and risk-off positioning unwind speculative longs." : "Rates, macro headlines, or sector weakness overwhelm standalone strength.",
            invalidation: "Broader risk stays calm while this market keeps absorbing supply on every dip.",
            stake: "$31k aligned",
        },
    ];

    return { bullCards, bearCards };
}

function ThesisCampPanel({
    tone,
    title,
    description,
    cards,
}: {
    tone: "bull" | "bear";
    title: string;
    description: string;
    cards: ThesisCardData[];
}) {
    const isBull = tone === "bull";

    return (
        <Card className={cn(
            "rounded-[24px] border p-4 shadow-[0_18px_48px_rgba(0,0,0,0.28)]",
            isBull ? "border-[#00E5B4]/20 bg-[#091622]" : "border-[#FF6B6B]/20 bg-[#17111B]"
        )}>
            <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em]">
                {isBull ? (
                    <TrendingUp className="h-4 w-4 text-[#00E5B4]" />
                ) : (
                    <TrendingDown className="h-4 w-4 text-[#FF8C8C]" />
                )}
                <span className={isBull ? "text-[#9FF8E2]" : "text-[#FFC2C2]"}>{title}</span>
            </div>
            <p className="mt-3 text-sm leading-6 text-[#96ABBF]">{description}</p>

            <div className="mt-4 space-y-3">
                {cards.map((card) => (
                    <div key={card.title} className="rounded-2xl border border-white/10 bg-black/20 p-4">
                        <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6E839C]">
                            {card.label}
                        </div>
                        <div className="mt-2 text-sm font-black text-white">{card.title}</div>
                        <p className="mt-2 text-xs leading-5 text-[#9CB1C9]">{card.summary}</p>
                        <div className="mt-3 space-y-2 rounded-xl border border-white/10 bg-white/[0.03] p-3 text-[11px]">
                            <div>
                                <span className="font-black uppercase tracking-[0.16em] text-[#6E839C]">Catalyst</span>
                                <p className="mt-1 leading-5 text-[#D8E3EE]">{card.catalyst}</p>
                            </div>
                            <div>
                                <span className="font-black uppercase tracking-[0.16em] text-[#6E839C]">Invalidation</span>
                                <p className="mt-1 leading-5 text-[#D8E3EE]">{card.invalidation}</p>
                            </div>
                        </div>
                        <div className="mt-3 flex items-center justify-between text-[11px]">
                            <span className="font-black uppercase tracking-[0.16em] text-[#6E839C]">Aligned stake</span>
                            <span className={isBull ? "font-black text-[#00E5B4]" : "font-black text-[#FF9A9A]"}>{card.stake}</span>
                        </div>
                    </div>
                ))}
            </div>
        </Card>
    );
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

    // Global Market Data
    const [roundOpenPrice, setRoundOpenPrice] = useState<number | null>(null);

    const mounted = useMounted();

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

            if (impersonateId && isAllowedAdminEmail(realUser?.email)) {
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
                if (typeof window !== 'undefined' && !searchParams.get('impersonate')) {
                    sessionStorage.removeItem('ghost_target_id');
                }
                setIsGhostMode(false);
                setUser(null);
            }
        });
    }, [supabase]);

    // --- HOOKS INTEGRATION ---
    const { isLocked, serverTimeOffset } = usePredictionLock({
        timeframe: selectedTimeframe,
        selectedAssetSymbol: selectedAsset.symbol
    });

    const { userPoints, username, userRank, fetchUserStats, isLoaded, activeCount } = useUserStats(user);
    const { predictions, fetchPredictions } = usePredictionHistory(user);
    const { feed, fetchFeed } = useRoomFeed({
        assetSymbol: selectedAsset.symbol,
        timeframe: selectedTimeframe,
        currentUserId: user?.id
    });

    const marketStatus = isMarketOpen(selectedAsset.symbol, selectedAsset.type);
    const displaySymbol = formatDisplaySymbol(selectedAsset.symbol);
    const thesisLevels = buildThesisLevels(roundOpenPrice, selectedTimeframe);
    const roundCadence = buildRoundCadence(selectedTimeframe);

    const adjustedNow = Date.now() + serverTimeOffset;
    const { bullCards, bearCards } = buildCampCards(selectedAsset, selectedTimeframe);
    const signalCount = feed.length > 0 ? feed.length : 12;
    const battleQuestion = `Will the next ${selectedTimeframe.toUpperCase()} confirm the ${selectedAsset.name} thesis?`;
    const battleSubtitle = `${displaySymbol} becomes a structured market here: stake the bull or bear case, publish your catalyst, and let the market resolve the debate on a fixed source.`;
    const catalystChips = selectedAsset.type === "CRYPTO"
        ? ["ETF flow", "Funding reset", "Liquidation map", "Rotation"]
        : selectedAsset.type === "STOCK"
            ? ["Macro tape", "Sector bid", "Opening range", "Earnings spillover"]
            : ["Dollar move", "Session settlement", "Risk appetite", "Carry unwind"];
    const marketMetrics = [
        { label: "Reference", value: formatReferencePrice(roundOpenPrice), icon: CandlestickChart },
        { label: "Resolution", value: getResolutionSource(selectedAsset), icon: Gavel },
        { label: "Signal Board", value: `${signalCount} active theses`, icon: BrainCircuit },
        { label: "Wallet", value: user ? `${userPoints.toFixed(2)} USDT ready` : "Sign in + connect wallet", icon: Wallet2 },
    ];

    const isAlreadyBet = mounted && (
        predictions.some(p =>
            p.status === 'pending' &&
            p.asset_symbol === selectedAsset.symbol &&
            p.timeframe === selectedTimeframe &&
            new Date(p.candle_close_at).getTime() > adjustedNow - 1000 // Buffer for clock jitter
        )
    );

    const activePrediction = mounted ? (
        predictions.find(p =>
            p.status === 'pending' &&
            p.asset_symbol === selectedAsset.symbol &&
            p.timeframe === selectedTimeframe &&
            new Date(p.candle_close_at).getTime() > adjustedNow - 1000
        ) || null
    ) : null;

    const isAIBeatEnabled = process.env.NEXT_PUBLIC_ENABLE_AI_BEAT === 'true';

    return (
        <main className="min-h-screen bg-[#060609] text-white selection:bg-primary/30">
            <MarketHeader
                user={user}
                username={username}
                userPoints={userPoints}
                userRank={userRank}
                activeCount={activeCount}
                isGhostMode={isGhostMode}
            />

            <div className="relative">
                <div className="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(circle_at_top_left,_rgba(0,229,180,0.12),_transparent_26%),radial-gradient(circle_at_top_right,_rgba(255,104,104,0.10),_transparent_24%)]" />

                <div className="container mx-auto max-w-7xl px-4 py-3 lg:px-6 lg:py-7">
                    <section className="overflow-hidden rounded-[30px] border border-white/10 bg-[#091120]/90 shadow-[0_30px_100px_rgba(0,0,0,0.5)]">
                        <div className="grid gap-0 lg:grid-cols-[1.15fr_0.85fr]">
                            <div className="border-b border-white/10 p-5 lg:border-b-0 lg:border-r lg:p-7">
                                <div className="flex flex-wrap items-center gap-2">
                                    <div className="inline-flex items-center gap-2 rounded-full border border-[#00E5B4]/20 bg-[#00E5B4]/10 px-3 py-1 text-[11px] font-black uppercase tracking-[0.2em] text-[#9FF8E2]">
                                        <Target className="h-3.5 w-3.5" />
                                        Decision Board
                                    </div>
                                    <div className={cn(
                                        "inline-flex items-center gap-2 rounded-full border px-3 py-1 text-[11px] font-black uppercase tracking-[0.18em]",
                                        marketStatus.isOpen
                                            ? "border-[#00E5B4]/20 bg-[#00E5B4]/10 text-[#9FF8E2]"
                                            : "border-[#FF6B6B]/20 bg-[#FF6B6B]/10 text-[#FFC2C2]"
                                    )}>
                                        <Clock3 className="h-3.5 w-3.5" />
                                        {marketStatus.isOpen ? "Open Market" : "Closed Market"}
                                    </div>
                                    <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[11px] font-black uppercase tracking-[0.18em] text-[#AFC3D9]">
                                        <Scale className="h-3.5 w-3.5" />
                                        {selectedTimeframe.toUpperCase()} / {displaySymbol}
                                    </div>
                                </div>

                                <div className="mt-5 space-y-3">
                                    <h1 className="max-w-3xl text-3xl font-black tracking-[-0.04em] text-white lg:text-5xl">
                                        {battleQuestion}
                                    </h1>
                                    <p className="max-w-3xl text-sm leading-6 text-[#9CB1C9] lg:text-base">
                                        {battleSubtitle}
                                    </p>
                                </div>

                                <div className="mt-5 flex flex-wrap gap-2">
                                    {catalystChips.map((chip) => (
                                        <div
                                            key={chip}
                                            className="rounded-full border border-white/10 bg-black/20 px-3 py-1.5 text-[11px] font-bold text-[#D9E6F3]"
                                        >
                                            {chip}
                                        </div>
                                    ))}
                                </div>

                                <div className="mt-6 grid gap-3 sm:grid-cols-3">
                                    <div className="rounded-2xl border border-[#00E5B4]/20 bg-[#00E5B4]/8 p-4">
                                        <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#9FF8E2]">
                                            <TrendingUp className="h-3.5 w-3.5" />
                                            Long Desk
                                        </div>
                                        <div className="mt-2 text-lg font-black text-white">Trend continuation</div>
                                        <p className="mt-2 text-xs leading-5 text-[#A7BDD6]">
                                            Buyers want follow-through, clean acceptance, and no failed breakout.
                                        </p>
                                    </div>
                                    <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
                                        <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#7E92AB]">
                                            <CandlestickChart className="h-3.5 w-3.5 text-[#00E5B4]" />
                                            Market Frame
                                        </div>
                                        <div className="mt-2 text-lg font-black text-white">{formatReferencePrice(roundOpenPrice)}</div>
                                        <p className="mt-2 text-xs leading-5 text-[#A7BDD6]">
                                            Reference price anchors the current thesis battle and resolution window.
                                        </p>
                                    </div>
                                    <div className="rounded-2xl border border-[#FF6B6B]/20 bg-[#FF6B6B]/8 p-4">
                                        <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#FFC2C2]">
                                            <TrendingDown className="h-3.5 w-3.5" />
                                            Short Desk
                                        </div>
                                        <div className="mt-2 text-lg font-black text-white">Fade and rejection</div>
                                        <p className="mt-2 text-xs leading-5 text-[#A7BDD6]">
                                            Sellers want failed acceptance, weak breadth, and a fast reclaim of supply.
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div className="p-5 lg:p-7">
                                <div className="text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                                    Market Structure
                                </div>
                                <div className="mt-4 grid gap-3 sm:grid-cols-2">
                                    {marketMetrics.map(({ label, value, icon: Icon }) => (
                                        <div key={label} className="rounded-2xl border border-white/10 bg-black/20 p-4">
                                            <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#637790]">
                                                <Icon className="h-3.5 w-3.5 text-[#00E5B4]" />
                                                {label}
                                            </div>
                                            <div className="mt-2 text-sm font-black text-white">{value}</div>
                                        </div>
                                    ))}
                                </div>

                                <div className="mt-5 rounded-[24px] border border-white/10 bg-[#0B1624] p-4">
                                    <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#9FF8E2]">
                                        <ShieldCheck className="h-4 w-4" />
                                        Fixed Rules Before Stake
                                    </div>
                                    <div className="mt-4 space-y-3 text-sm text-[#C9D7E4]">
                                        <div className="flex items-start justify-between gap-3 rounded-2xl border border-white/10 bg-black/20 px-4 py-3">
                                            <span className="text-[#7E92AB]">Resolution source</span>
                                            <span className="text-right font-bold text-white">{getResolutionSource(selectedAsset)}</span>
                                        </div>
                                        <div className="flex items-start justify-between gap-3 rounded-2xl border border-white/10 bg-black/20 px-4 py-3">
                                            <span className="text-[#7E92AB]">Fallback policy</span>
                                            <span className="text-right font-bold text-white">Secondary market data with manual clarification log</span>
                                        </div>
                                        <div className="flex items-start justify-between gap-3 rounded-2xl border border-white/10 bg-black/20 px-4 py-3">
                                            <span className="text-[#7E92AB]">Beta preview</span>
                                            <span className="text-right font-bold text-white">Camp cards are curated seed thesis until live community depth fills in</span>
                                        </div>
                                    </div>

                                    <div className="mt-5 flex flex-col gap-3 sm:flex-row">
                                        <Link href="/wallet" className="flex-1">
                                            <Button className="w-full bg-[#00E5B4] text-black hover:bg-[#00E5B4]/90">
                                                Open Wallet
                                                <ArrowUpRight className="ml-2 h-4 w-4" />
                                            </Button>
                                        </Link>
                                        {!user && (
                                            <Link href="/login" className="flex-1">
                                                <Button variant="outline" className="w-full border-white/10 bg-white/5 hover:bg-white/10">
                                                    Sign in to unlock live betting
                                                </Button>
                                            </Link>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>

                    <section className="mt-4 grid gap-4 lg:grid-cols-12">
                        <div className="order-2 space-y-4 lg:order-1 lg:col-span-3">
                            <ThesisCampPanel
                                tone="bull"
                                title="Long Desk"
                                description="This side is underwriting follow-through, accepting higher prices, and defending the scenario under pressure."
                                cards={bullCards}
                            />
                        </div>

                        <div className="order-1 lg:order-2 lg:col-span-6">
                            <Card className="h-[360px] overflow-hidden rounded-[28px] border border-white/10 bg-[#0C1624] shadow-[0_20px_70px_rgba(0,0,0,0.35)] lg:h-[560px]">
                                <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
                                    <div>
                                        <div className="flex items-center gap-2 text-sm font-black uppercase tracking-[0.18em] text-[#9FF8E2]">
                                            <BarChart3 className="h-4 w-4" />
                                            {selectedTimeframe.toUpperCase()} Chart Arena
                                        </div>
                                        <div className="mt-1 text-[10px] font-black uppercase tracking-[0.16em] text-[#6F849D]">
                                            Entry anchor, trigger zones, and fixed resolution cadence
                                        </div>
                                    </div>
                                    <div className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-[10px] font-black uppercase tracking-[0.18em] text-[#D7E3EE]">
                                        {displaySymbol}
                                    </div>
                                </div>
                                <div className="relative h-[calc(100%-57px)]">
                                    <TradingViewWidget
                                        symbol={selectedAsset.symbol}
                                        interval={selectedTimeframe}
                                        theme="dark"
                                    />
                                    <div className="pointer-events-none absolute inset-0 bg-[linear-gradient(180deg,rgba(6,9,20,0.08)_0%,rgba(6,9,20,0.34)_100%)]" />
                                    <div className="pointer-events-none absolute left-4 top-4 rounded-2xl border border-white/10 bg-[#111C2B]/85 px-4 py-3 backdrop-blur">
                                        <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6E839C]">Resolution snapshot</div>
                                        <div className="mt-1 text-base font-black text-white">{formatReferencePrice(roundOpenPrice)}</div>
                                        <div className="mt-1 text-xs text-[#A7BDD6]">
                                            Source fixed to {getResolutionSource(selectedAsset)}
                                        </div>
                                    </div>
                                    <div className="pointer-events-none absolute right-4 top-4 hidden w-[220px] rounded-2xl border border-white/10 bg-[#111C2B]/85 p-4 backdrop-blur lg:block">
                                        <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6E839C]">Thesis levels</div>
                                        <div className="mt-3 space-y-2">
                                            {thesisLevels.map((level) => (
                                                <div key={level.label} className="flex items-center justify-between gap-3 rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                                    <span className="text-[10px] font-black uppercase tracking-[0.16em] text-[#7D92AA]">{level.label}</span>
                                                    <span
                                                        className={cn(
                                                            "text-[11px] font-black",
                                                            level.tone === "bull" && "text-[#8FF6D6]",
                                                            level.tone === "bear" && "text-[#FFB0B0]",
                                                            level.tone === "neutral" && "text-white"
                                                        )}
                                                    >
                                                        {level.value}
                                                    </span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                    <div className="pointer-events-none absolute inset-x-4 bottom-4 hidden rounded-2xl border border-white/10 bg-[#111C2B]/88 p-3 backdrop-blur md:block">
                                        <div className="grid gap-3 lg:grid-cols-[0.9fr_0.9fr_1.2fr]">
                                            <div className="rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                                <div className="text-[9px] font-black uppercase tracking-[0.16em] text-[#6E839C]">Open window</div>
                                                <div className="mt-1 text-[11px] font-black text-white">{roundCadence.openWindow}</div>
                                            </div>
                                            <div className="rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                                <div className="text-[9px] font-black uppercase tracking-[0.16em] text-[#6E839C]">Lock discipline</div>
                                                <div className="mt-1 text-[11px] font-black text-white">{roundCadence.lockWindow}</div>
                                            </div>
                                            <div className="rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                                <div className="text-[9px] font-black uppercase tracking-[0.16em] text-[#6E839C]">Resolve + read</div>
                                                <div className="mt-1 text-[11px] font-black text-white">{roundCadence.resolveWindow}</div>
                                                <div className="mt-1 text-[10px] leading-4 text-[#9CB1C9]">{roundCadence.integrityNote}</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </Card>
                            <div className="mt-3 grid gap-3 md:hidden">
                                <div className="rounded-[22px] border border-white/10 bg-[#0B1624] p-4">
                                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6E839C]">Thesis levels</div>
                                    <div className="mt-3 grid gap-2">
                                        {thesisLevels.map((level) => (
                                            <div key={level.label} className="flex items-center justify-between rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                                <span className="text-[10px] font-black uppercase tracking-[0.16em] text-[#7D92AA]">{level.label}</span>
                                                <span
                                                    className={cn(
                                                        "text-[11px] font-black",
                                                        level.tone === "bull" && "text-[#8FF6D6]",
                                                        level.tone === "bear" && "text-[#FFB0B0]",
                                                        level.tone === "neutral" && "text-white"
                                                    )}
                                                >
                                                    {level.value}
                                                </span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                                <div className="rounded-[22px] border border-white/10 bg-[#0B1624] p-4">
                                    <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#6E839C]">Round cadence</div>
                                    <div className="mt-3 grid gap-2">
                                        <div className="rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                            <div className="text-[9px] font-black uppercase tracking-[0.16em] text-[#6E839C]">Open window</div>
                                            <div className="mt-1 text-[11px] font-black text-white">{roundCadence.openWindow}</div>
                                        </div>
                                        <div className="rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                            <div className="text-[9px] font-black uppercase tracking-[0.16em] text-[#6E839C]">Lock discipline</div>
                                            <div className="mt-1 text-[11px] font-black text-white">{roundCadence.lockWindow}</div>
                                        </div>
                                        <div className="rounded-xl border border-white/10 bg-black/20 px-3 py-2">
                                            <div className="text-[9px] font-black uppercase tracking-[0.16em] text-[#6E839C]">Resolve + read</div>
                                            <div className="mt-1 text-[11px] font-black text-white">{roundCadence.resolveWindow}</div>
                                            <div className="mt-1 text-[10px] leading-4 text-[#9CB1C9]">{roundCadence.integrityNote}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="order-3 space-y-4 lg:col-span-3">
                            <ThesisCampPanel
                                tone="bear"
                                title="Short Desk"
                                description="This side is positioned for rejection, failed acceptance, and a decisive reclaim by sellers."
                                cards={bearCards}
                            />
                        </div>
                    </section>

                    <section className="mt-4 grid gap-4 lg:grid-cols-12">
                        <div className="lg:col-span-4">
                            <div className="space-y-3">
                                <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                                    <Wallet2 className="h-4 w-4 text-[#00E5B4]" />
                                    Stake Composer
                                </div>
                                <OrderPanel
                                    user={user}
                                    userPoints={userPoints}
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
                        </div>

                        <div className="space-y-4 lg:col-span-4">
                            <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                                <BarChart3 className="h-4 w-4 text-[#00E5B4]" />
                                Telemetry
                            </div>
                            {activePrediction && (
                                <DesktopActivePosition
                                    activePrediction={activePrediction}
                                    currentPrice={roundOpenPrice}
                                />
                            )}
                            <StatsPanel
                                assetSymbol={selectedAsset.symbol}
                                timeframe={selectedTimeframe}
                            />
                        </div>

                        <div className="lg:col-span-4">
                            <div className="space-y-3">
                                <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                                    <Scale className="h-4 w-4 text-[#00E5B4]" />
                                    Archive
                                </div>
                                <PredictionTabs predictions={predictions} user={user} />
                            </div>
                        </div>
                    </section>

                    <section className="mt-4">
                        <div className="space-y-3">
                            <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#7A90AB]">
                                <BrainCircuit className="h-4 w-4 text-[#00E5B4]" />
                                Signal Channel
                            </div>
                            <SocialFeed
                                feed={feed}
                                selectedAsset={selectedAsset}
                                user={user}
                                refreshFeed={fetchFeed}
                            />
                        </div>
                    </section>
                </div>
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
