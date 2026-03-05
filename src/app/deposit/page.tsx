"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Check, Copy, AlertTriangle, Zap, Wallet, CheckCircle2, Loader2 } from "lucide-react";
import { connectWallet, depositUSDT, getContractBalance } from "@/lib/contract";
import { toast } from "sonner";

export default function DepositPage() {
    const [walletAddress, setWalletAddress] = useState<string | null>(null);
    const [amount, setAmount] = useState<string>("10");
    const [loading, setLoading] = useState(false);
    const [txHash, setTxHash] = useState<string | null>(null);
    const [contractBalance, setContractBalance] = useState<number | null>(null);

    const quickAmounts = [5, 10, 25, 50];

    async function handleConnect() {
        try {
            const addr = await connectWallet();
            setWalletAddress(addr);
            const bal = await getContractBalance(addr);
            setContractBalance(bal);
            toast.success("Wallet connected!");
        } catch (err: any) {
            toast.error(err.message || "Failed to connect wallet");
        }
    }

    async function handleDeposit() {
        const amt = parseFloat(amount);
        if (!amt || amt <= 0) { toast.error("Enter a valid amount"); return; }
        if (!walletAddress) { toast.error("Connect wallet first"); return; }

        setLoading(true);
        try {
            const hash = await depositUSDT(amt);
            setTxHash(hash);
            const bal = await getContractBalance(walletAddress);
            setContractBalance(bal);
            toast.success(`Deposited ${amt} USDT!`);
        } catch (err: any) {
            toast.error(err.reason || err.message || "Deposit failed");
        } finally {
            setLoading(false);
        }
    }

    async function copyAddress() {
        if (walletAddress) {
            await navigator.clipboard.writeText(walletAddress);
            toast.success("Address copied!");
        }
    }

    return (
        <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 flex flex-col pb-24 lg:pb-0">
            <div className="max-w-md mx-auto w-full flex-1">
                {/* Header */}
                <header className="flex items-center justify-between p-4 pt-6">
                    <Link href="/wallet" className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#8BA3BF] hover:text-white transition-colors">
                        <ArrowLeft className="w-5 h-5" />
                    </Link>
                    <div className="text-lg font-bold tracking-tight">Deposit USDT</div>
                    <div className="w-10" />
                </header>

                <div className="px-5 mt-2">
                    {/* Network Badge */}
                    <div className="inline-flex items-center gap-2 bg-[#F5A623]/10 border border-[#F5A623]/30 rounded-full px-3 py-1 mb-4">
                        <Zap className="w-3.5 h-3.5 fill-[#F5A623] text-[#F5A623]" />
                        <span className="text-[11px] font-bold text-[#F5A623]">Polygon (MATIC) — Low fees</span>
                    </div>

                    {/* Step 1: Connect Wallet */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-2xl p-4 mb-4">
                        <div className="flex items-center justify-between mb-3">
                            <div className="flex items-center gap-2">
                                <div className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${walletAddress ? 'bg-[#00E5B4] text-black' : 'bg-[#1E2D45] text-[#5A7090]'}`}>
                                    {walletAddress ? <Check className="w-3.5 h-3.5" /> : '1'}
                                </div>
                                <span className="text-sm font-bold">Connect MetaMask</span>
                            </div>
                            {!walletAddress && (
                                <button
                                    onClick={handleConnect}
                                    className="flex items-center gap-1.5 bg-[#00E5B4]/10 border border-[#00E5B4]/30 px-3 py-1.5 rounded-lg text-[11px] font-bold text-[#00E5B4] hover:bg-[#00E5B4]/20 transition-colors"
                                >
                                    <Wallet className="w-3.5 h-3.5" /> Connect
                                </button>
                            )}
                        </div>
                        {walletAddress && (
                            <div className="bg-[#080C14] border border-[#1E2D45] rounded-xl p-2 flex items-center justify-between gap-2">
                                <span className="font-mono text-[11px] text-[#8BA3BF] truncate">{walletAddress}</span>
                                <button onClick={copyAddress} className="shrink-0">
                                    <Copy className="w-3.5 h-3.5 text-[#5A7090] hover:text-white transition-colors" />
                                </button>
                            </div>
                        )}
                        {contractBalance !== null && (
                            <div className="mt-2 text-[11px] text-[#5A7090]">
                                Contract balance: <span className="text-[#00E5B4] font-bold">{contractBalance.toFixed(2)} USDT</span>
                            </div>
                        )}
                    </div>

                    {/* Step 2: Amount */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-2xl p-4 mb-4">
                        <div className="flex items-center gap-2 mb-3">
                            <div className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${walletAddress ? 'bg-[#00E5B4] text-black' : 'bg-[#1E2D45] text-[#5A7090]'}`}>
                                2
                            </div>
                            <span className="text-sm font-bold">Select Amount</span>
                        </div>

                        <div className="flex gap-2 mb-3">
                            {quickAmounts.map(val => (
                                <button
                                    key={val}
                                    onClick={() => setAmount(val.toString())}
                                    className={`flex-1 py-2 text-center border rounded-lg text-xs font-bold transition-colors ${amount === val.toString()
                                            ? "bg-[#00E5B4]/10 border-[#00E5B4] text-[#00E5B4]"
                                            : "bg-[#0F1623] border-[#1E2D45] text-[#8BA3BF] hover:text-white"
                                        }`}
                                >
                                    ${val}
                                </button>
                            ))}
                        </div>

                        <input
                            type="number"
                            value={amount}
                            onChange={e => setAmount(e.target.value)}
                            placeholder="Custom amount"
                            className="w-full bg-[#080C14] border border-[#1E2D45] rounded-xl px-4 py-3 font-mono text-sm outline-none focus:border-[#00E5B4] transition-colors"
                        />
                    </div>

                    {/* Step 3: Deposit */}
                    <button
                        onClick={handleDeposit}
                        disabled={loading || !walletAddress}
                        className="w-full bg-[#00E5B4] text-black font-black text-base h-14 rounded-xl mb-3 shadow-[0_0_20px_rgba(0,229,180,0.2)] active:scale-95 transition-all disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                    >
                        {loading ? (
                            <><Loader2 className="w-5 h-5 animate-spin" /> Confirming...</>
                        ) : (
                            <>⬇ Deposit {amount || '0'} USDT</>
                        )}
                    </button>

                    {/* TX Success */}
                    {txHash && (
                        <div className="bg-[#00E5B4]/10 border border-[#00E5B4]/20 rounded-xl p-3 flex gap-3 items-start mb-4">
                            <CheckCircle2 className="w-4 h-4 text-[#00E5B4] shrink-0 mt-0.5" />
                            <div>
                                <div className="text-xs font-bold text-[#00E5B4] mb-0.5">Deposit confirmed!</div>
                                <a
                                    href={`https://amoy.polygonscan.com/tx/${txHash}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="text-[10px] text-[#8BA3BF] hover:text-[#00E5B4] underline font-mono break-all"
                                >
                                    {txHash.slice(0, 20)}...{txHash.slice(-8)} ↗
                                </a>
                            </div>
                        </div>
                    )}

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
