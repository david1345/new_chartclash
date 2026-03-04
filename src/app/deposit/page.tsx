"use client";

import Link from "next/link";
import { ArrowLeft, Check, Copy, AlertTriangle, Zap } from "lucide-react";

export default function DepositPage() {
    return (
        <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 flex flex-col pb-24 lg:pb-0">
            <div className="max-w-md mx-auto w-full flex-1">
                {/* Header */}
                <header className="flex items-center justify-between p-4 pt-6">
                    <Link href="/wallet" className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#8BA3BF] hover:text-white transition-colors">
                        <ArrowLeft className="w-5 h-5" />
                    </Link>
                    <div className="text-lg font-bold tracking-tight">Deposit USDT</div>
                    <div className="w-10" /> {/* Spacer */}
                </header>

                <div className="px-5 mt-2">
                    {/* Progress Steps */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-2xl p-4 mb-4">
                        <div className="flex items-center gap-3 py-3 border-b border-[#1E2D45]">
                            <div className="w-7 h-7 rounded-full bg-[#00E5B4]/20 text-[#00E5B4] flex items-center justify-center shrink-0">
                                <Check className="w-4 h-4" />
                            </div>
                            <div className="text-sm text-[#8BA3BF]">
                                <strong className="text-white">Select network</strong> — Polygon (MATIC)
                            </div>
                        </div>
                        <div className="flex items-center gap-3 py-3 border-b border-[#1E2D45]">
                            <div className="w-7 h-7 rounded-full bg-[#00E5B4] text-black font-bold text-xs flex items-center justify-center shrink-0">
                                2
                            </div>
                            <div className="text-sm text-[#8BA3BF]">
                                <strong className="text-white">Send USDT</strong> to your address below
                            </div>
                        </div>
                        <div className="flex items-center gap-3 py-3">
                            <div className="w-7 h-7 rounded-full bg-[#1E2D45] text-[#5A7090] font-bold text-xs flex items-center justify-center shrink-0">
                                3
                            </div>
                            <div className="text-sm text-[#5A7090]">
                                Balance auto-updates on confirmation
                            </div>
                        </div>
                    </div>

                    {/* Network Selection */}
                    <div className="mb-3">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-1.5 uppercase">Network</div>
                        <div className="inline-flex items-center gap-2 bg-[#F5A623]/10 border border-[#F5A623]/30 rounded-full px-3 py-1 mb-3">
                            <Zap className="w-3.5 h-3.5 fill-[#F5A623] text-[#F5A623]" />
                            <span className="text-[11px] font-bold text-[#F5A623]">Polygon (MATIC) — Low fees</span>
                        </div>
                    </div>

                    {/* QR Code */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-2xl p-5 mb-4 flex flex-col items-center">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest uppercase mb-4">Scan to Deposit</div>
                        <div className="bg-white p-3 rounded-xl mb-3">
                            {/* Fake QR pattern matching the mockup */}
                            <div className="w-[140px] h-[140px] bg-[url('https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=0x7F3a9B2c4E1d8f6A0b5C5E6eEa3aBc4243D9e')] bg-center bg-contain" />
                        </div>
                        <div className="text-[11px] text-[#5A7090]">USDT only &middot; Polygon network only</div>
                    </div>

                    {/* Address */}
                    <div className="mb-4">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-1.5 uppercase">Your Deposit Address</div>
                        <div className="bg-[#080C14] border border-[#1E2D45] rounded-xl p-3 flex items-center justify-between gap-3">
                            <div className="font-mono text-[11px] text-[#8BA3BF] break-all">0x7F3a9B2c4E1d8f6A0b5C5E6eEa3aBc4243D9e</div>
                            <button className="bg-[#00E5B4]/10 border border-[#00E5B4]/30 px-3 py-1.5 rounded-lg text-[11px] font-bold text-[#00E5B4] shrink-0 active:scale-95 transition-transform flex items-center gap-1.5">
                                <Copy className="w-3.5 h-3.5" /> Copy
                            </button>
                        </div>
                    </div>

                    {/* Details */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-4 mb-3 space-y-3">
                        <div className="flex justify-between items-center text-xs">
                            <span className="text-[#5A7090]">Minimum deposit</span>
                            <span className="font-mono">$1.00 USDT</span>
                        </div>
                        <div className="flex justify-between items-center text-xs">
                            <span className="text-[#5A7090]">Network fee</span>
                            <span className="font-mono text-[#00E5B4]">~$0.01</span>
                        </div>
                        <div className="flex justify-between items-center text-xs">
                            <span className="text-[#5A7090]">Confirmation time</span>
                            <span className="font-mono">~1 min</span>
                        </div>
                    </div>

                    {/* Warning */}
                    <div className="bg-[#FF4560]/10 border border-[#FF4560]/20 rounded-xl p-3 flex gap-3 text-[11px] text-[#FF4560] leading-relaxed mb-6">
                        <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                        <p>Only send USDT on Polygon network. Sending other tokens or using a different network will result in permanent loss of funds.</p>
                    </div>

                </div>
            </div>
        </main>
    );
}
