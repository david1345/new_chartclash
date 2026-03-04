"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Hourglass } from "lucide-react";
import { cn } from "@/lib/utils";

export default function WithdrawPage() {
    const [amount, setAmount] = useState<string>("20.00");
    const [address, setAddress] = useState<string>("0x742d35Cc6634C0532...");

    const quickAmounts = [5, 10, 20, 50];

    return (
        <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 flex flex-col pb-24 lg:pb-0">
            <div className="max-w-md mx-auto w-full flex-1">
                {/* Header */}
                <header className="flex items-center justify-between p-4 pt-6">
                    <Link href="/wallet" className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#8BA3BF] hover:text-white transition-colors">
                        <ArrowLeft className="w-5 h-5" />
                    </Link>
                    <div className="text-lg font-bold tracking-tight">Withdraw USDT</div>
                    <div className="w-10" /> {/* Spacer */}
                </header>

                <div className="px-5 mt-2">

                    {/* Available Hero */}
                    <div className="bg-gradient-to-br from-[#0F1E35] to-[#0A1628] border border-[#1E2D45] rounded-[14px] p-4 flex justify-between items-center mb-5">
                        <div>
                            <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-1 uppercase">Available to Withdraw</div>
                            <div className="text-3xl font-mono font-medium">48.50 <span className="text-sm text-[#8BA3BF]">USDT</span></div>
                        </div>
                        <div className="text-right">
                            <div className="text-[10px] text-[#5A7090] mb-1">Min withdraw</div>
                            <div className="text-[13px] text-[#8BA3BF] font-mono">$5.00</div>
                        </div>
                    </div>

                    {/* Amount Input */}
                    <div className="mb-4">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-2 uppercase">Amount (USDT)</div>
                        <div className="relative mb-3">
                            <input
                                type="text"
                                value={amount}
                                onChange={(e) => setAmount(e.target.value)}
                                className="w-full bg-[#080C14] border border-[#1E2D45] rounded-xl px-4 py-3.5 pr-20 font-mono text-[15px] outline-none focus:border-[#00E5B4] transition-colors"
                            />
                            <button
                                onClick={() => setAmount("48.50")}
                                className="absolute right-2 top-1/2 -translate-y-1/2 bg-[#00E5B4]/10 border border-[#00E5B4]/30 px-3 py-1.5 rounded-lg text-[11px] font-bold text-[#00E5B4] active:scale-95 transition-transform"
                            >
                                MAX
                            </button>
                        </div>
                        <div className="flex gap-2">
                            {quickAmounts.map(val => (
                                <button
                                    key={val}
                                    onClick={() => setAmount(val.toFixed(2))}
                                    className={cn(
                                        "flex-1 py-2 text-center border rounded-lg text-xs font-bold transition-colors",
                                        amount === val.toFixed(2)
                                            ? "bg-[#00E5B4]/10 border-[#00E5B4] text-[#00E5B4]"
                                            : "bg-[#141D2E] border-[#1E2D45] text-[#8BA3BF] hover:text-white"
                                    )}
                                >
                                    ${val}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Address Input */}
                    <div className="mb-5">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-2 uppercase">Destination Address (Polygon USDT)</div>
                        <input
                            type="text"
                            value={address}
                            onChange={(e) => setAddress(e.target.value)}
                            className="w-full bg-[#080C14] border border-[#1E2D45] rounded-xl px-4 py-3.5 font-mono text-[15px] outline-none transition-colors mb-2 text-[#8BA3BF]"
                            readOnly
                        />
                        <div className="text-[11px] text-[#5A7090]">Make sure this is a Polygon-compatible USDT address</div>
                    </div>

                    {/* Fee Summary */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-4 mb-4">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-3 uppercase">Transaction Summary</div>

                        <div className="flex justify-between text-xs py-2 border-b border-[#1E2D45]">
                            <span className="text-[#5A7090]">Withdraw amount</span>
                            <span className="font-mono text-white">{amount || "0.00"} USDT</span>
                        </div>
                        <div className="flex justify-between text-xs py-2 border-b border-[#1E2D45]">
                            <span className="text-[#5A7090]">Network fee</span>
                            <span className="font-mono text-white">~0.01 USDT</span>
                        </div>
                        <div className="flex justify-between text-xs py-2 border-b border-[#1E2D45]">
                            <span className="text-[#5A7090]">Processing time</span>
                            <span className="font-mono text-white">1–24 hours</span>
                        </div>
                        <div className="flex justify-between text-[13px] pt-4 mt-1 font-bold">
                            <span>You receive</span>
                            <span className="font-mono text-[#00E5B4] text-[15px]">{Math.max(0, parseFloat(amount || "0") - 0.01).toFixed(2)} USDT</span>
                        </div>
                    </div>

                    {/* Pending State */}
                    <div className="bg-[#F5A623]/10 border border-[#F5A623]/20 rounded-xl p-3 flex gap-3 text-[11px] text-[#FF4560] leading-relaxed mb-6 items-center">
                        <div className="text-xl">⏳</div>
                        <div className="flex-1">
                            <div className="font-bold text-[#F5A623] text-xs mb-0.5">Previous withdrawal pending</div>
                            <div className="text-[11px] text-[#8BA3BF]">$15.00 &middot; Submitted 2h ago &middot; Under review</div>
                        </div>
                        <div className="bg-[#F5A623]/10 border border-[#F5A623]/30 px-2.5 py-1 rounded-full flex items-center gap-1.5 shrink-0">
                            <div className="w-1.5 h-1.5 rounded-full bg-[#F5A623] animate-pulse" />
                            <span className="text-[10px] text-[#F5A623] font-bold">Pending</span>
                        </div>
                    </div>

                    {/* Actions */}
                    <button className="w-full bg-[#00E5B4] text-black font-black text-base h-14 rounded-xl mb-3 shadow-[0_0_20px_rgba(0,229,180,0.2)] active:scale-95 transition-all">
                        ⬆ Confirm Withdrawal
                    </button>
                    <Link href="/wallet" className="block">
                        <button className="w-full bg-transparent border border-[#1E2D45] text-[#8BA3BF] font-bold text-sm h-[52px] rounded-xl hover:text-white transition-colors active:scale-95">
                            Cancel
                        </button>
                    </Link>

                </div>
            </div>
        </main>
    );
}
