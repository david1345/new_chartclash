"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, History, ScrollText } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";
import dayjs from "dayjs";
dayjs.locale("en");
import { useGuestPrediction } from "@/hooks/dashboard/use-guest-prediction";

// 🛡️ Helper to get Zone status from a prediction record
const getZoneInfo = (pred: { timeframe: string; created_at: string; candle_close_at: string }) => {
    let tfSeconds = 900;
    const tf = pred.timeframe;
    if (tf === '1m') tfSeconds = 60;
    else if (tf === '5m') tfSeconds = 300;
    else if (tf === '15m') tfSeconds = 900;
    else if (tf === '30m') tfSeconds = 1800;
    else if (tf.includes('h')) tfSeconds = parseInt(tf) * 3600;
    else if (tf.includes('d')) tfSeconds = 86400;

    const created = new Date(pred.created_at).getTime() / 1000;
    const closed = new Date(pred.candle_close_at).getTime() / 1000;
    const ratio = (created - (closed - tfSeconds)) / tfSeconds;

    if (ratio < 0.33) return { label: "GREEN", color: "text-emerald-400", border: "border-emerald-500/50", bg: "bg-emerald-500/5" };
    if (ratio < 0.66) return { label: "YELLOW", color: "text-amber-400", border: "border-amber-500/50", bg: "bg-amber-500/5" };
    return { label: "RED", color: "text-rose-400", border: "border-rose-500/50", bg: "bg-rose-500/5" };
};

export default function MatchHistoryPage() {
    const [predictions, setPredictions] = useState<any[]>([]);
    const { guestPredictions } = useGuestPrediction();
    const supabase = createClient();

    // Extracted streak calculation logic for reuse
    const calculateStreaks = useCallback((data: any[]) => {
        // Calculate running streaks for the UI display
        // Sort by created_at ascending to calculate correctly
        const sorted = [...data].sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

        let currentStreak = 0;
        const historyWithStreaks = sorted.map(pred => {
            // Determine if it was a "Perfect Streak" candidate
            const entry = pred.entry_price || 0;
            const actualPrice = pred.actual_price || 0;
            const changePct = entry > 0 && actualPrice > 0 ? ((actualPrice - entry) / entry) * 100 : 0;
            const isTargetHit = Math.abs(changePct) >= (pred.target_percent || 0.5);
            const isGreenZone = getZoneInfo(pred).label === "GREEN";

            if (pred.status === 'WIN') {
                if (isGreenZone && isTargetHit) {
                    currentStreak++;
                    const displayStreak = currentStreak;
                    if (currentStreak >= 5) currentStreak = 0;
                    return { ...pred, displayStreak };
                } else {
                    currentStreak = 0;
                    return { ...pred, displayStreak: 0 };
                }
            } else if (pred.status === 'LOSS') {
                currentStreak = 0;
                return { ...pred, displayStreak: 0 };
            }
            return { ...pred, displayStreak: currentStreak };
        });

        // Set back to descending for display
        return historyWithStreaks.reverse();
    }, []);

    const fetchHistory = useCallback(async () => {
        const { data: { user: realUser } } = await supabase.auth.getUser();

        if (!realUser) {
            // Point 1: If no user, show guest predictions from local storage via hook
            if (guestPredictions && guestPredictions.length > 0) {
                const historyWithStreaks = calculateStreaks([...guestPredictions]);
                setPredictions(historyWithStreaks);
            } else {
                setPredictions([]);
            }
            return;
        }

        // Ghost Mode logic
        const ghostId = typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null;
        const isImpersonating = ghostId && realUser.email === 'sjustone000@gmail.com';
        const targetId = isImpersonating ? ghostId : realUser.id;

        const { data } = await supabase
            .from('predictions')
            .select('*')
            .eq('user_id', targetId)
            .order('created_at', { ascending: false })
            .limit(100);

        if (data) {
            const historyWithStreaks = calculateStreaks(data);
            setPredictions(historyWithStreaks);
        }
    }, [guestPredictions, calculateStreaks, supabase]);

    useEffect(() => {
        fetchHistory();
    }, [fetchHistory]);

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            {/* Header */}
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <ScrollText className="w-5 h-5 text-muted-foreground" /> Match History
                    </h1>
                    <Button variant="ghost" size="icon" onClick={() => fetchHistory()} className="ml-auto text-muted-foreground hover:text-white">
                        <History className="w-4 h-4" />
                    </Button>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 max-w-5xl pb-20">
                <Card className="bg-card/10 border-white/5">
                    <CardContent className="p-0">
                        {predictions.length === 0 ? (
                            <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
                                <History className="w-12 h-12 mb-4 opacity-20" />
                                <p className="text-lg font-medium">No predictions yet</p>
                                <p className="text-sm">Your match history will appear here.</p>
                                <Link href="/" className="mt-4">
                                    <Button variant="outline">Start Trading</Button>
                                </Link>
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full text-sm text-left">
                                    <thead className="text-xs text-muted-foreground uppercase bg-white/5 border-b border-white/5">
                                        <tr>
                                            <th className="px-6 py-3">Time</th>
                                            <th className="px-6 py-3">Asset</th>
                                            <th className="px-6 py-3 text-center">Streak</th>
                                            <th className="px-6 py-3">Pick</th>
                                            <th className="px-6 py-3 text-right">Bet</th>
                                            <th className="px-6 py-3 text-right">Result</th>
                                            <th className="px-6 py-3 text-right">P&L</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5">
                                        {predictions.map((pred) => (
                                            <HistoryRow key={pred.id} pred={pred} />
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}

function HistoryRow({ pred }: { pred: any }) {
    const [isOpen, setIsOpen] = useState(false);

    // Standard Base Schema naming
    const entry = pred.entry_price || 0;
    const actualPrice = pred.actual_price || 0;
    const profitValue = pred.profit ?? 0;
    const betAmount = pred.bet_amount ?? 0;

    // Odds calculation: if win, odds = (profit + bet) / bet.
    // If we only have profit, and it's a win, the total returned was bet + profit.
    const odds = (betAmount > 0 && pred.status === 'WIN') ? ((betAmount + profitValue) / betAmount).toFixed(2) : "0.00";

    // Use actual_change_percent if available, or calculate locally
    const changePct = pred.actual_change_percent ?? (entry > 0 && actualPrice > 0 ? ((actualPrice - entry) / entry) * 100 : 0);

    // Target Hit check
    const isTargetHit = pred.is_target_hit ?? (Math.abs(changePct) >= pred.target_percent);

    // Direction check
    const directionCorrect = (pred.direction === 'UP' && actualPrice > entry) || (pred.direction === 'DOWN' && actualPrice < entry);

    return (
        <>
            <tr
                data-testid={`prediction-${pred.id}`}
                onClick={() => setIsOpen(!isOpen)}
                className={cn(
                    "hover:bg-white/5 transition-colors cursor-pointer group",
                    isOpen ? "bg-white/5" : ""
                )}
            >
                <td className="px-6 py-4 text-muted-foreground whitespace-nowrap">
                    {dayjs(pred.created_at).format('MM/DD h:mm A')}
                </td>
                <td className="px-6 py-4 font-bold">
                    <div className="flex items-center gap-2 whitespace-nowrap">
                        <Badge variant="outline" className={cn(
                            "text-[10px] min-w-[35px] justify-center border-2",
                            getZoneInfo(pred).color,
                            getZoneInfo(pred).border,
                            getZoneInfo(pred).bg
                        )}>{pred.timeframe}</Badge>
                        <span>{pred.asset_symbol}</span>
                    </div>
                </td>
                <td className="px-6 py-4 text-center">
                    {pred.displayStreak > 0 ? (
                        <div className="flex items-center justify-center gap-1 text-orange-500 font-bold">
                            <span>🔥</span>
                            <span>{pred.displayStreak}</span>
                        </div>
                    ) : (
                        <span className="text-muted-foreground/30 font-mono">-</span>
                    )}
                </td>
                <td className="px-6 py-4">
                    <Badge variant="outline" className={cn(
                        "border-none font-bold",
                        pred.direction === 'UP' ? "bg-emerald-500/20 text-emerald-500" : "bg-red-500/20 text-red-500"
                    )}>
                        {pred.direction}
                    </Badge>
                </td>
                <td className="px-6 py-4 text-right font-mono">
                    <span className="text-white">${betAmount.toFixed(2)}</span>
                </td>
                <td className="px-6 py-4 text-right">
                    <Badge variant="outline" className={cn(
                        "text-[10px] px-2 py-0.5 h-5 uppercase inline-flex",
                        pred.status === 'WIN' ? "border-[#00E5B4]/50 text-[#00E5B4] bg-[#00E5B4]/10" :
                            pred.status === 'LOSS' ? "border-[#FF4560]/50 text-[#FF4560] bg-[#FF4560]/10" :
                                "border-[#F5A623]/50 text-[#F5A623] bg-[#F5A623]/10"
                    )}>
                        {pred.status}
                    </Badge>
                </td>
                <td className="px-6 py-4 text-right font-mono font-bold">
                    <span className={cn(
                        profitValue > 0 ? "text-[#00E5B4]" :
                            profitValue < 0 ? "text-[#FF4560]" : "text-[#5A7090]"
                    )}>
                        {profitValue > 0 ? `+$${profitValue.toFixed(2)}` : profitValue < 0 ? `-$${Math.abs(profitValue).toFixed(2)}` : '-'}
                    </span>
                </td>
            </tr>
            {isOpen && (
                <tr className="bg-white/[0.02]">
                    <td colSpan={7} className="px-6 py-4 border-t border-white/5 shadow-inner">
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-sm">
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Entry Price</div>
                                <div className="font-mono text-white">${Number(entry).toLocaleString(undefined, { minimumFractionDigits: 2 })}</div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Actual Price</div>
                                <div className={cn("font-mono font-bold", actualPrice > entry ? "text-emerald-400" : actualPrice < entry ? "text-red-400" : "text-white")}>
                                    ${Number(actualPrice).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Actual Move</div>
                                <div className={cn("font-bold", changePct > 0 ? "text-emerald-400" : changePct < 0 ? "text-red-400" : "text-gray-400")}>
                                    {changePct > 0 ? "+" : ""}{changePct.toFixed(2)}%
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Details</div>
                                <div className="space-y-1 text-xs">
                                    <div className="flex justify-between w-32 border-b border-white/10 pb-1 mb-1">
                                        <span className="text-[#5A7090]">Direction:</span>
                                        {directionCorrect ? <span className="text-[#00E5B4]">Correct</span> : <span className="text-[#FF4560]">Wrong</span>}
                                    </div>
                                    <div className="flex justify-between w-32 border-b border-white/10 pb-1 mb-1">
                                        <span className="text-[#5A7090]">Target Hit:</span>
                                        {isTargetHit ? <span className="text-[#00E5B4]">Yes ({pred.target_percent}%)</span> : <span className="text-[#FF4560]">No ({pred.target_percent}%)</span>}
                                    </div>
                                    <div className="flex justify-between w-32">
                                        <span className="text-[#5A7090]">Final Odds:</span>
                                        <span className="font-mono text-white">{odds}x</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="mt-4 pt-3 border-t border-white/5 flex items-center justify-between">
                            <div className="text-[10px] text-muted-foreground flex items-center gap-1">
                                <span className="inline-block w-1.5 h-1.5 rounded-full bg-blue-500/50"></span>
                                Resolved using Binance {pred.timeframe} candle close price
                            </div>
                            <div className="text-[10px] text-muted-foreground">
                                Candle Time: {dayjs(new Date(new Date(pred.candle_close_at).getTime() - (pred.timeframe.includes('m') ? parseInt(pred.timeframe) * 60 : pred.timeframe.includes('h') ? parseInt(pred.timeframe) * 3600 : 86400) * 1000)).format('h:mm A')} – {dayjs(pred.candle_close_at).format('h:mm A')}
                            </div>
                        </div>
                    </td>
                </tr>
            )}
        </>
    );
}
