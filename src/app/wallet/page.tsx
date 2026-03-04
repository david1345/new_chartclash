"use client";

import Link from "next/link";
import { Bell, ArrowDownCircle, ArrowUpCircle, Zap, Trophy, History } from "lucide-react";

export default function WalletPage() {
    return (
        <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 flex flex-col pb-24 lg:pb-0">
            <div className="max-w-md mx-auto w-full flex-1">
                {/* Header */}
                <header className="flex items-center justify-between p-4 pt-6">
                    <div className="text-xl font-black tracking-tight">
                        CHART<span className="text-[#00E5B4]">CLASH</span>
                    </div>
                    <button className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#8BA3BF] hover:text-white transition-colors">
                        <Bell className="w-5 h-5" />
                    </button>
                </header>

                {/* Balance Hero */}
                <div className="m-4 mt-2 bg-gradient-to-br from-[#0F1E35] to-[#0A1628] border border-[#1E2D45] rounded-[20px] py-3 px-6 relative overflow-hidden">
                    <div className="absolute -top-10 -right-10 w-32 h-32 rounded-full bg-[#00E5B4]/10 blur-[40px]" />

                    <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-1 uppercase">TOTAL BALANCE</div>
                    <div className="text-4xl font-mono font-medium tracking-tight mb-1">
                        48.50<span className="text-xl text-[#8BA3BF] ml-1.5">USDT</span>
                    </div>
                    <div className="text-xs text-[#5A7090] font-mono mb-2">≈ $48.50 USD &middot; Polygon Network</div>

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
                </div>

                {/* Stats Row */}
                <div className="flex flex-row gap-2 mx-4 mb-4">
                    <div className="flex-1 bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3">
                        <div className="text-[10px] text-[#5A7090] mb-1">Total Won</div>
                        <div className="font-mono text-[#00E5B4] font-medium">+$92.40</div>
                    </div>
                    <div className="flex-1 bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3">
                        <div className="text-[10px] text-[#5A7090] mb-1">Total Lost</div>
                        <div className="font-mono text-[#FF4560] font-medium">-$43.90</div>
                    </div>
                    <div className="flex-1 bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3">
                        <div className="text-[10px] text-[#5A7090] mb-1">Net P&L</div>
                        <div className="font-mono text-[#00E5B4] font-medium">+$48.50</div>
                    </div>
                </div>

                {/* Transaction History */}
                <div className="mx-4 mt-2">
                    <div className="flex justify-between items-center mb-3">
                        <h2 className="text-[11px] text-[#5A7090] font-bold tracking-widest uppercase">Active & Recent</h2>
                        <button className="text-xs text-[#00E5B4] font-bold hover:underline">View all</button>
                    </div>

                    <div className="space-y-2">
                        {/* Active Position */}
                        <div className="bg-[#141D2E] border border-[#00E5B4]/30 rounded-xl p-3 flex items-center gap-3 relative overflow-hidden">
                            <div className="absolute top-0 left-0 w-1 h-full bg-[#00E5B4]" />
                            <div className="w-10 h-10 rounded-xl bg-[#00E5B4]/10 flex items-center justify-center shrink-0">
                                <Zap className="w-5 h-5 text-[#00E5B4] animate-pulse" />
                            </div>
                            <div className="flex-1 overflow-hidden">
                                <div className="font-bold text-sm truncate mb-0.5">Live Battle &middot; Round #1,247</div>
                                <div className="text-[11px] text-[#5A7090] font-mono truncate">UP &middot; 1H &middot; 0.5% Target</div>
                            </div>
                            <div className="text-right shrink-0">
                                <div className="font-mono font-medium text-white tracking-widest text-[#00E5B4] animate-pulse">PENDING</div>
                                <div className="text-[10px] text-[#5A7090] mt-0.5">10 USDT</div>
                            </div>
                        </div>

                        {/* Win */}
                        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3 flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-[#F5A623]/10 flex items-center justify-center shrink-0">
                                <Trophy className="w-5 h-5 text-[#F5A623]" />
                            </div>
                            <div className="flex-1 overflow-hidden">
                                <div className="font-bold text-sm truncate mb-0.5">Battle Won &middot; Round #1,246</div>
                                <div className="text-[11px] text-[#5A7090] font-mono truncate">UP &middot; 1H &middot; GREEN zone</div>
                            </div>
                            <div className="text-right shrink-0">
                                <div className="font-mono font-medium text-[#00E5B4]">+$18.40</div>
                                <div className="text-[10px] text-[#5A7090] mt-0.5">2h ago</div>
                            </div>
                        </div>

                        {/* Loss */}
                        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3 flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-[#FF4560]/10 flex items-center justify-center shrink-0">
                                <div className="text-lg">💀</div>
                            </div>
                            <div className="flex-1 overflow-hidden">
                                <div className="font-bold text-sm truncate mb-0.5">Battle Lost &middot; Round #1,245</div>
                                <div className="text-[11px] text-[#5A7090] font-mono truncate">DOWN &middot; 1H &middot; YELLOW zone</div>
                            </div>
                            <div className="text-right shrink-0">
                                <div className="font-mono font-medium text-[#FF4560]">-$10.00</div>
                                <div className="text-[10px] text-[#5A7090] mt-0.5">3h ago</div>
                            </div>
                        </div>

                        {/* Deposit */}
                        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3 flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-[#00E5B4]/10 flex items-center justify-center shrink-0">
                                <ArrowDownCircle className="w-5 h-5 text-[#00E5B4]" />
                            </div>
                            <div className="flex-1 overflow-hidden">
                                <div className="font-bold text-sm truncate mb-0.5">Deposit USDT</div>
                                <div className="text-[11px] text-[#5A7090] font-mono truncate">Polygon &middot; Confirmed</div>
                            </div>
                            <div className="text-right shrink-0">
                                <div className="font-mono font-medium text-[#00E5B4]">+$50.00</div>
                                <div className="text-[10px] text-[#5A7090] mt-0.5">1d ago</div>
                            </div>
                        </div>

                        {/* Withdrawal */}
                        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-3 flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-[#FF4560]/10 flex items-center justify-center shrink-0">
                                <ArrowUpCircle className="w-5 h-5 text-[#FF4560]" />
                            </div>
                            <div className="flex-1 overflow-hidden">
                                <div className="font-bold text-sm truncate mb-0.5">Withdrawal USDT</div>
                                <div className="text-[11px] text-[#5A7090] font-mono truncate">Polygon &middot; Completed</div>
                            </div>
                            <div className="text-right shrink-0">
                                <div className="font-mono font-medium text-[#8BA3BF]">-$20.00</div>
                                <div className="text-[10px] text-[#5A7090] mt-0.5">2d ago</div>
                            </div>
                        </div>

                    </div>
                </div>
            </div>
        </main>
    );
}
