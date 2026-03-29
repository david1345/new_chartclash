"use client";

import Link from "next/link";
import { ArrowDown, ArrowUp, History } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { cn } from "@/lib/utils";

interface Prediction {
    id: string | number;
    created_at: string;
    asset_symbol: string;
    direction: "UP" | "DOWN";
    status: "pending" | "WIN" | "LOSS" | "REFUND" | "ND";
    timeframe: string;
    candle_close_at: string;
    bet_amount: number;
    profit?: number | null;
}

interface PredictionTabsProps {
    predictions: Prediction[];
    user: any;
}

function formatTime(date: string) {
    return new Date(date).toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
    });
}

function formatStatus(status: Prediction["status"]) {
    if (status === "ND" || status === "REFUND") return "REFUND";
    return status;
}

function Row({ prediction }: { prediction: Prediction }) {
    const isUp = prediction.direction === "UP";
    const normalizedStatus = formatStatus(prediction.status);
    const profit = Number(prediction.profit || 0);

    return (
        <div className="grid grid-cols-[78px_1fr_70px_76px_86px] items-center gap-2 p-3 text-xs border-b border-white/5">
            <div className="font-mono text-[10px] text-[#7A90AB]">{formatTime(prediction.created_at)}</div>
            <div>
                <div className="font-bold text-white">{prediction.asset_symbol}</div>
                <div className="text-[10px] text-[#6E839C]">{prediction.timeframe}</div>
            </div>
            <div className="flex justify-center">
                <Badge
                    variant="outline"
                    className={cn(
                        "h-5 px-2 text-[10px] font-bold",
                        isUp
                            ? "border-[#00E5B4]/30 bg-[#00E5B4]/10 text-[#00E5B4]"
                            : "border-[#FF6B6B]/30 bg-[#FF6B6B]/10 text-[#FF8C8C]"
                    )}
                >
                    {isUp ? <ArrowUp className="w-3 h-3 mr-1" /> : <ArrowDown className="w-3 h-3 mr-1" />}
                    {isUp ? "LONG" : "SHORT"}
                </Badge>
            </div>
            <div className="text-right font-mono text-white">{prediction.bet_amount} USDT</div>
            <div className="text-right">
                {prediction.status === "pending" ? (
                    <span className="text-[10px] font-bold text-[#F5A623]">LIVE</span>
                ) : (
                    <div className="space-y-0.5">
                        <div
                            className={cn(
                                "text-[10px] font-bold",
                                normalizedStatus === "WIN"
                                    ? "text-[#00E5B4]"
                                    : normalizedStatus === "REFUND"
                                        ? "text-[#F5A623]"
                                        : "text-[#FF8C8C]"
                            )}
                        >
                            {normalizedStatus}
                        </div>
                        <div className="font-mono text-[10px] text-[#9CB1C9]">
                            {normalizedStatus === "REFUND"
                                ? "0 USDT"
                                : `${profit > 0 ? "+" : ""}${profit} USDT`}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

export function PredictionTabs({ predictions, user }: PredictionTabsProps) {
    const pendingPredictions = predictions.filter((prediction) => prediction.status === "pending");
    const historyPredictions = predictions
        .filter((prediction) => prediction.status !== "pending")
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    return (
        <Card className="h-[340px] mt-auto bg-[#0F1623] border-[#1E2D45] overflow-hidden flex flex-col shrink-0 flex-1">
            <CardHeader className="py-1 px-3 bg-[#141D2E] border-b border-[#1E2D45] shrink-0 min-h-[36px] flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-xs font-bold flex items-center gap-2 uppercase tracking-wider text-white">
                    <History className="w-3 h-3 text-primary" /> Bet Ledger
                </CardTitle>
                {user ? (
                    <Button variant="ghost" size="sm" className="h-5 text-[10px] px-2 text-muted-foreground hover:text-white hover:bg-white/10" asChild>
                        <Link href="/match-history">
                            Full History
                        </Link>
                    </Button>
                ) : (
                    <Button variant="ghost" size="sm" className="h-5 text-[10px] px-2 text-muted-foreground hover:text-white hover:bg-white/10" asChild>
                        <Link href="/login">
                            Sign In
                        </Link>
                    </Button>
                )}
            </CardHeader>

            <CardContent className="p-0 flex-1 min-h-0 bg-[#0F1623]">
                <Tabs defaultValue="active" className="w-full h-full flex flex-col">
                    <div className="px-3 border-b border-[#1E2D45] bg-[#141D2E] pt-1 shrink-0">
                        <TabsList className="h-7 bg-[#0F1623] border border-[#1E2D45]">
                            <TabsTrigger value="active" className="h-6 text-[10px]">
                                Active
                                {pendingPredictions.length > 0 && (
                                    <Badge className="ml-1.5 h-4 px-1 min-w-[16px] bg-primary/20 text-primary border-0">
                                        {pendingPredictions.length}
                                    </Badge>
                                )}
                            </TabsTrigger>
                            <TabsTrigger value="history" className="h-6 text-[10px]">History</TabsTrigger>
                        </TabsList>
                    </div>

                    <div className="grid grid-cols-[78px_1fr_70px_76px_86px] gap-2 px-3 py-2 bg-[#141D2E] border-b border-[#1E2D45] text-[9px] font-bold text-[#5A7090] uppercase tracking-widest">
                        <span>Time</span>
                        <span>Market</span>
                        <span className="text-center">Side</span>
                        <span className="text-right">Stake</span>
                        <span className="text-right">Status</span>
                    </div>

                    <div className="flex-1 min-h-0">
                        <ScrollArea className="h-full">
                            <TabsContent value="active" className="m-0">
                                {pendingPredictions.length === 0 ? (
                                    <div className="flex h-[220px] flex-col items-center justify-center px-6 text-center">
                                        <div className="text-sm font-black uppercase tracking-[0.18em] text-white">
                                            No Open USDT Bets
                                        </div>
                                        <p className="mt-2 max-w-[240px] text-[11px] leading-5 text-[#7A90AB]">
                                            {user
                                                ? "Connect your wallet, fund the contract balance, and place a live thesis bet."
                                                : "Sign in to mirror on-chain bets into your portfolio and resolution history."}
                                        </p>
                                    </div>
                                ) : (
                                    pendingPredictions.map((prediction) => (
                                        <Row key={prediction.id} prediction={prediction} />
                                    ))
                                )}
                            </TabsContent>

                            <TabsContent value="history" className="m-0">
                                {historyPredictions.length === 0 ? (
                                    <div className="flex h-[220px] flex-col items-center justify-center px-6 text-center">
                                        <div className="text-sm font-black uppercase tracking-[0.18em] text-white">
                                            No Settled Bets Yet
                                        </div>
                                        <p className="mt-2 max-w-[240px] text-[11px] leading-5 text-[#7A90AB]">
                                            Closed rounds will land here with mirrored win, loss, or refund status.
                                        </p>
                                    </div>
                                ) : (
                                    historyPredictions.map((prediction) => (
                                        <Row key={prediction.id} prediction={prediction} />
                                    ))
                                )}
                            </TabsContent>
                        </ScrollArea>
                    </div>
                </Tabs>
            </CardContent>
        </Card>
    );
}
