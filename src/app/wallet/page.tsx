"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { ArrowDownCircle, ArrowUpCircle, Wallet, RefreshCw, Loader2, Zap, Trophy } from "lucide-react";
import { connectWallet, getContractBalance } from "@/lib/contract";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

type Prediction = {
    id: number;
    direction: "UP" | "DOWN";
    bet_amount: number;
    status: "pending" | "WIN" | "LOSS" | "ND";
    profit: number | null;
    created_at: string;
    asset_symbol: string;
    timeframe: string;
};

export default function WalletPage() {
    const [address, setAddress] = useState<string | null>(null);
    const [balance, setBalance] = useState<number | null>(null);
    const [loading, setLoading] = useState(false);
    const [refreshing, setRefreshing] = useState(false);
    const [predictions, setPredictions] = useState<Prediction[]>([]);
    const supabase = createClient();

    const fetchBalance = useCallback(async (addr: string) => {
        try {
            const bal = await getContractBalance(addr);
            setBalance(bal);
        } catch {
            setBalance(0);
        }
    }, []);

    const fetchHistory = useCallback(async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;
        const { data } = await supabase
            .from("predictions")
            .select("id, direction, bet_amount, status, profit, created_at, asset_symbol, timeframe")
            .eq("user_id", user.id)
            .order("created_at", { ascending: false })
            .limit(10);
        if (data) setPredictions(data as Prediction[]);
    }, [supabase]);

    // Auto-connect if MetaMask already approved
    useEffect(() => {
        if (typeof window === "undefined" || !window.ethereum) return;
        window.ethereum.request({ method: "eth_accounts" }).then(async (accounts: string[]) => {
            if (accounts[0]) {
                setAddress(accounts[0]);
                fetchBalance(accounts[0]);
            }
        });
        fetchHistory();
    }, [fetchBalance, fetchHistory]);

    async function handleConnect() {
        setLoading(true);
        try {
            const addr = await connectWallet();
            setAddress(addr);
            await fetchBalance(addr);
            toast.success("Wallet connected!");
        } catch (err: any) {
            toast.error(err.message || "Failed to connect");
        } finally {
            setLoading(false);
        }
    }

    async function handleRefresh() {
        if (!address) return;
        setRefreshing(true);
        await fetchBalance(address);
        await fetchHistory();
        setRefreshing(false);
    }

    const displayBalance = balance !== null ? balance.toFixed(2) : "—";

    function timeAgo(dateStr: string) {
        const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
        if (diff < 60) return `${diff}s ago`;
        if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
        if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
        return `${Math.floor(diff / 86400)}d ago`;
    }

    return (
        <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 flex flex-col pb-24 lg:pb-0">
            <div className="max-w-md mx-auto w-full flex-1">
                {/* Header */}
                <header className="flex items-center justify-between p-4 pt-6">
                    <div className="text-xl font-black tracking-tight">
                        CHART<span className="text-[#00E5B4]">CLASH</span>
                    </div>
                    <button
                        onClick={handleRefresh}
                        disabled={refreshing || !address}
                        className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#8BA3BF] hover:text-white transition-colors disabled:opacity-40"
                    >
                        <RefreshCw className={`w-4 h-4 ${refreshing ? "animate-spin" : ""}`} />
                    </button>
                </header>

                {/* Balance Hero */}
                <div className="m-4 mt-2 bg-gradient-to-br from-[#0F1E35] to-[#0A1628] border border-[#1E2D45] rounded-[20px] py-5 px-6 relative overflow-hidden">
                    <div className="absolute -top-10 -right-10 w-32 h-32 rounded-full bg-[#00E5B4]/10 blur-[40px]" />

                    <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-1 uppercase">Contract Balance</div>

                    {!address ? (
                        <div className="mb-2">
                            <div className="text-4xl font-mono font-medium tracking-tight mb-1 text-[#5A7090]">—</div>
                            <div className="text-xs text-[#5A7090] font-mono mb-4">Connect wallet to view balance</div>
                            <button
                                onClick={handleConnect}
                                disabled={loading}
                                className="flex items-center gap-2 px-5 py-2.5 bg-[#00E5B4] hover:bg-[#00E5B4]/90 text-black font-bold text-sm rounded-xl transition-all active:scale-[0.98] disabled:opacity-50"
                            >
                                {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Wallet className="w-4 h-4" />}
                                {loading ? "Connecting..." : "Connect MetaMask"}
                            </button>
                        </div>
                    ) : (
                        <>
                            <div className="text-4xl font-mono font-medium tracking-tight mb-1">
                                {displayBalance}<span className="text-xl text-[#8BA3BF] ml-1.5">USDT</span>
                            </div>
                            <div className="text-xs text-[#5A7090] font-mono mb-4">
                                {address.slice(0, 6)}...{address.slice(-4)} · Polygon Network
                            </div>
                            <div className="flex gap-3">
                                <Link href="/deposit" className="flex-1">
                                    <button className="w-full px-4 bg-[#00E5B4] hover:bg-[#00E5B4]/90 text-black font-bold h-10 rounded-xl text-sm flex items-center justify-center gap-1.5 transition-all active:scale-[0.98]">
                                        <ArrowDownCircle className="w-4 h-4" /> Deposit
                                    </button>
                                </Link>
                                <Link href="/withdraw" className="flex-1">
                                    <button className="w-full px-4 bg-[#141D2E] border border-[#1E2D45] hover:border-[#5A7090] text-[#8BA3BF] hover:text-white font-bold h-10 rounded-xl text-sm flex items-center justify-center gap-1.5 transition-all active:scale-[0.98]">
                                        <ArrowUpCircle className="w-4 h-4" /> Withdraw
                                    </button>
                                </Link>
                            </div>
                        </>
                    )}
                </div>

                {/* Transaction History */}
                <div className="mx-4 mt-2">
                    <div className="flex justify-between items-center mb-3">
                        <h2 className="text-[11px] text-[#5A7090] font-bold tracking-widest uppercase">Recent Activity</h2>
                    </div>

                    {predictions.length === 0 ? (
                        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-6 text-center text-[#5A7090] text-sm">
                            No bets yet
                        </div>
                    ) : (
                        <div className="space-y-2">
                            {predictions.map((p) => {
                                const isPending = p.status === "pending";
                                const isWin = p.status === "WIN";
                                const isRefund = p.status === "ND";
                                const profit = p.profit ?? null;

                                return (
                                    <div key={p.id} className={`bg-[#141D2E] border rounded-xl p-3 flex items-center gap-3 relative overflow-hidden ${isPending ? "border-[#00E5B4]/30" : "border-[#1E2D45]"}`}>
                                        {isPending && <div className="absolute top-0 left-0 w-1 h-full bg-[#00E5B4]" />}
                                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${isPending ? "bg-[#00E5B4]/10" : isWin ? "bg-[#F5A623]/10" : "bg-[#FF4560]/10"}`}>
                                            {isPending
                                                ? <Zap className="w-5 h-5 text-[#00E5B4] animate-pulse" />
                                                : isWin
                                                    ? <Trophy className="w-5 h-5 text-[#F5A623]" />
                                                    : <span className="text-lg">💀</span>
                                            }
                                        </div>
                                        <div className="flex-1 overflow-hidden">
                                            <div className="font-bold text-sm truncate mb-0.5">
                                                {isPending ? "Live Battle" : isWin ? "Battle Won" : isRefund ? "Battle Refunded" : "Battle Lost"}
                                            </div>
                                            <div className="text-[11px] text-[#5A7090] font-mono truncate">
                                                {p.direction} · {p.timeframe} · {p.asset_symbol}
                                            </div>
                                        </div>
                                        <div className="text-right shrink-0">
                                            {isPending ? (
                                                <>
                                                    <div className="font-mono font-medium text-[#00E5B4] animate-pulse text-sm">PENDING</div>
                                                    <div className="text-[10px] text-[#5A7090] mt-0.5">{p.bet_amount} USDT</div>
                                                </>
                                            ) : (
                                                <>
                                                    <div className={`font-mono font-medium text-sm ${isWin ? "text-[#00E5B4]" : isRefund ? "text-[#F5A623]" : "text-[#FF4560]"}`}>
                                                        {profit !== null ? `${profit > 0 ? "+" : ""}${profit.toFixed(2)}` : `${p.bet_amount} USDT`}
                                                    </div>
                                                    <div className="text-[10px] text-[#5A7090] mt-0.5">{timeAgo(p.created_at)}</div>
                                                </>
                                            )}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    )}
                </div>
            </div>
        </main>
    );
}
