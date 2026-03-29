"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import dayjs from "dayjs";
import { ArrowLeft, History, ScrollText } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { isAllowedAdminEmail } from "@/lib/admin-client";

dayjs.locale("en");

export default function MatchHistoryPage() {
    const [predictions, setPredictions] = useState<any[]>([]);
    const supabase = createClient();

    const fetchHistory = useCallback(async () => {
        const {
            data: { user: realUser },
        } = await supabase.auth.getUser();

        if (!realUser) {
            setPredictions([]);
            return;
        }

        const ghostId = typeof window !== "undefined" ? sessionStorage.getItem("ghost_target_id") : null;
        const isImpersonating = ghostId && isAllowedAdminEmail(realUser.email);
        const targetId = isImpersonating ? ghostId : realUser.id;

        const { data } = await supabase
            .from("predictions")
            .select("*")
            .eq("user_id", targetId)
            .order("created_at", { ascending: false })
            .limit(100);

        setPredictions(data || []);
    }, [supabase]);

    useEffect(() => {
        fetchHistory();
    }, [fetchHistory]);

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <ScrollText className="w-5 h-5 text-muted-foreground" /> Bet History
                    </h1>
                    <Button variant="ghost" size="icon" onClick={fetchHistory} className="ml-auto text-muted-foreground hover:text-white">
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
                                <p className="text-lg font-medium">No bets yet</p>
                                <p className="text-sm">Your live and settled contract bets will appear here.</p>
                                <Link href="/" className="mt-4">
                                    <Button variant="outline">Open Markets</Button>
                                </Link>
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full text-sm text-left">
                                    <thead className="text-xs text-muted-foreground uppercase bg-white/5 border-b border-white/5">
                                        <tr>
                                            <th className="px-6 py-3">Time</th>
                                            <th className="px-6 py-3">Market</th>
                                            <th className="px-6 py-3">Side</th>
                                            <th className="px-6 py-3 text-right">Stake</th>
                                            <th className="px-6 py-3 text-right">Status</th>
                                            <th className="px-6 py-3 text-right">P&amp;L</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5">
                                        {predictions.map((prediction) => (
                                            <HistoryRow key={prediction.id} pred={prediction} />
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

    const entry = Number(pred.entry_price || 0);
    const actualPrice = Number(pred.actual_price || 0);
    const profitValue = Number(pred.profit || 0);
    const betAmount = Number(pred.bet_amount || 0);
    const movePct = entry > 0 && actualPrice > 0 ? ((actualPrice - entry) / entry) * 100 : 0;
    const normalizedStatus = pred.status === "ND" ? "REFUND" : pred.status;

    return (
        <>
            <tr
                onClick={() => setIsOpen(!isOpen)}
                className={cn("hover:bg-white/5 transition-colors cursor-pointer group", isOpen && "bg-white/5")}
            >
                <td className="px-6 py-4 text-muted-foreground whitespace-nowrap">
                    {dayjs(pred.created_at).format("MM/DD h:mm A")}
                </td>
                <td className="px-6 py-4 font-bold">
                    <div className="flex items-center gap-2 whitespace-nowrap">
                        <Badge variant="outline" className="text-[10px] min-w-[35px] justify-center border-2 border-white/10 bg-white/5">
                            {pred.timeframe}
                        </Badge>
                        <span>{pred.asset_symbol}</span>
                    </div>
                </td>
                <td className="px-6 py-4">
                    <Badge
                        variant="outline"
                        className={cn(
                            "border-none font-bold",
                            pred.direction === "UP" ? "bg-emerald-500/20 text-emerald-500" : "bg-red-500/20 text-red-500"
                        )}
                    >
                        {pred.direction === "UP" ? "LONG" : "SHORT"}
                    </Badge>
                </td>
                <td className="px-6 py-4 text-right font-mono text-white">
                    {betAmount.toFixed(2)} USDT
                </td>
                <td className="px-6 py-4 text-right">
                    <Badge
                        variant="outline"
                        className={cn(
                            "text-[10px] px-2 py-0.5 h-5 uppercase inline-flex",
                            normalizedStatus === "WIN"
                                ? "border-[#00E5B4]/50 text-[#00E5B4] bg-[#00E5B4]/10"
                                : normalizedStatus === "LOSS"
                                    ? "border-[#FF4560]/50 text-[#FF4560] bg-[#FF4560]/10"
                                    : normalizedStatus === "pending"
                                        ? "border-[#F5A623]/50 text-[#F5A623] bg-[#F5A623]/10"
                                        : "border-white/20 text-white bg-white/5"
                        )}
                    >
                        {normalizedStatus === "pending" ? "LIVE" : normalizedStatus}
                    </Badge>
                </td>
                <td className="px-6 py-4 text-right font-mono font-bold">
                    {pred.status === "pending" ? (
                        <span className="text-[#F5A623]">Open</span>
                    ) : (
                        <span className={cn(
                            profitValue > 0 ? "text-[#00E5B4]" : profitValue < 0 ? "text-[#FF4560]" : "text-[#5A7090]"
                        )}>
                            {profitValue > 0 ? "+" : ""}{profitValue.toFixed(2)} USDT
                        </span>
                    )}
                </td>
            </tr>
            {isOpen && (
                <tr className="bg-white/[0.02]">
                    <td colSpan={6} className="px-6 py-4 border-t border-white/5 shadow-inner">
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-sm">
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Entry Price</div>
                                <div className="font-mono text-white">{entry > 0 ? `$${entry.toLocaleString(undefined, { minimumFractionDigits: 2 })}` : "Pending"}</div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Close Price</div>
                                <div className={cn(
                                    "font-mono font-bold",
                                    actualPrice > entry ? "text-emerald-400" : actualPrice < entry ? "text-red-400" : "text-white"
                                )}>
                                    {actualPrice > 0 ? `$${actualPrice.toLocaleString(undefined, { minimumFractionDigits: 2 })}` : "Pending"}
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Move</div>
                                <div className={cn("font-bold", movePct > 0 ? "text-emerald-400" : movePct < 0 ? "text-red-400" : "text-gray-400")}>
                                    {actualPrice > 0 ? `${movePct > 0 ? "+" : ""}${movePct.toFixed(2)}%` : "Pending"}
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Resolution</div>
                                <div className="space-y-1 text-xs">
                                    <div className="flex justify-between w-36 border-b border-white/10 pb-1 mb-1">
                                        <span className="text-[#5A7090]">Source:</span>
                                        <span className="text-white">Binance close</span>
                                    </div>
                                    <div className="flex justify-between w-36">
                                        <span className="text-[#5A7090]">Round Close:</span>
                                        <span className="font-mono text-white">{dayjs(pred.candle_close_at).format("h:mm A")}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </td>
                </tr>
            )}
        </>
    );
}
