"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowLeft, Loader2, CheckCircle2, Wallet } from "lucide-react";
import { cn } from "@/lib/utils";
import { connectWallet, withdrawUSDT, getContractBalance } from "@/lib/contract";
import { toast } from "sonner";

export default function WithdrawPage() {
    const [walletAddress, setWalletAddress] = useState<string | null>(null);
    const [contractBalance, setContractBalance] = useState<number>(0);
    const [amount, setAmount] = useState<string>("20.00");
    const [address, setAddress] = useState<string>("");
    const [loading, setLoading] = useState(false);
    const [txHash, setTxHash] = useState<string | null>(null);

    const quickAmounts = [5, 10, 20, 50];
    const WITHDRAW_FEE = 0.01; // 1%
    const amountNum = parseFloat(amount) || 0;
    const youReceive = Math.max(0, amountNum - amountNum * WITHDRAW_FEE);

    async function handleConnect() {
        try {
            const addr = await connectWallet();
            setWalletAddress(addr);
            setAddress(addr);
            const bal = await getContractBalance(addr);
            setContractBalance(bal);
            toast.success("Wallet connected!");
        } catch (err: any) {
            toast.error(err.message || "Failed to connect wallet");
        }
    }

    async function handleWithdraw() {
        if (!amountNum || amountNum <= 0) { toast.error("Enter valid amount"); return; }
        if (amountNum < 5) { toast.error("Minimum withdrawal is $5"); return; }
        if (amountNum > contractBalance) { toast.error("Insufficient contract balance"); return; }
        if (!walletAddress) { toast.error("Connect wallet first"); return; }

        setLoading(true);
        try {
            const hash = await withdrawUSDT(amountNum);
            setTxHash(hash);
            const bal = await getContractBalance(walletAddress);
            setContractBalance(bal);
            toast.success(`Withdrew ${youReceive.toFixed(2)} USDT!`);
        } catch (err: any) {
            toast.error(err.reason || err.message || "Withdrawal failed");
        } finally {
            setLoading(false);
        }
    }

    return (
        <main className="min-h-[100dvh] bg-[#080C14] text-white selection:bg-[#00E5B4]/30 flex flex-col pb-24 lg:pb-0">
            <div className="max-w-md mx-auto w-full flex-1">
                <header className="flex items-center justify-between p-4 pt-6">
                    <Link href="/wallet" className="w-10 h-10 rounded-full bg-[#141D2E] border border-[#1E2D45] flex items-center justify-center text-[#8BA3BF] hover:text-white transition-colors">
                        <ArrowLeft className="w-5 h-5" />
                    </Link>
                    <div className="text-lg font-bold tracking-tight">Withdraw USDT</div>
                    <div className="w-10" />
                </header>

                <div className="px-5 mt-2">
                    {/* Connect / Balance Hero */}
                    <div className="bg-gradient-to-br from-[#0F1E35] to-[#0A1628] border border-[#1E2D45] rounded-[14px] p-4 flex justify-between items-center mb-5">
                        <div>
                            <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-1 uppercase">Available to Withdraw</div>
                            <div className="text-3xl font-mono font-medium">
                                {contractBalance.toFixed(2)} <span className="text-sm text-[#8BA3BF]">USDT</span>
                            </div>
                        </div>
                        {!walletAddress ? (
                            <button
                                onClick={handleConnect}
                                className="flex items-center gap-1.5 bg-[#00E5B4]/10 border border-[#00E5B4]/30 px-3 py-2 rounded-lg text-[11px] font-bold text-[#00E5B4] hover:bg-[#00E5B4]/20 transition-colors"
                            >
                                <Wallet className="w-3.5 h-3.5" /> Connect
                            </button>
                        ) : (
                            <div className="text-right">
                                <div className="text-[10px] text-[#5A7090] mb-1">Min withdraw</div>
                                <div className="text-[13px] text-[#8BA3BF] font-mono">$5.00</div>
                            </div>
                        )}
                    </div>

                    {/* Amount Input */}
                    <div className="mb-4">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-2 uppercase">Amount (USDT)</div>
                        <div className="relative mb-3">
                            <input
                                type="number"
                                value={amount}
                                onChange={(e) => setAmount(e.target.value)}
                                className="w-full bg-[#080C14] border border-[#1E2D45] rounded-xl px-4 py-3.5 pr-20 font-mono text-[15px] outline-none focus:border-[#00E5B4] transition-colors"
                            />
                            <button
                                onClick={() => setAmount(contractBalance.toFixed(2))}
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

                    {/* Transaction Summary */}
                    <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-4 mb-4">
                        <div className="text-[11px] text-[#5A7090] font-bold tracking-widest mb-3 uppercase">Transaction Summary</div>
                        <div className="flex justify-between text-xs py-2 border-b border-[#1E2D45]">
                            <span className="text-[#5A7090]">Withdraw amount</span>
                            <span className="font-mono text-white">{amountNum.toFixed(2)} USDT</span>
                        </div>
                        <div className="flex justify-between text-xs py-2 border-b border-[#1E2D45]">
                            <span className="text-[#5A7090]">Platform fee (1%)</span>
                            <span className="font-mono text-white">{(amountNum * WITHDRAW_FEE).toFixed(2)} USDT</span>
                        </div>
                        <div className="flex justify-between text-xs py-2 border-b border-[#1E2D45]">
                            <span className="text-[#5A7090]">Processing time</span>
                            <span className="font-mono text-white">~1 min (on-chain)</span>
                        </div>
                        <div className="flex justify-between text-[13px] pt-4 mt-1 font-bold">
                            <span>You receive</span>
                            <span className="font-mono text-[#00E5B4] text-[15px]">{youReceive.toFixed(2)} USDT</span>
                        </div>
                    </div>

                    {/* TX Success */}
                    {txHash && (
                        <div className="bg-[#00E5B4]/10 border border-[#00E5B4]/20 rounded-xl p-3 flex gap-3 items-start mb-4">
                            <CheckCircle2 className="w-4 h-4 text-[#00E5B4] shrink-0 mt-0.5" />
                            <div>
                                <div className="text-xs font-bold text-[#00E5B4] mb-0.5">Withdrawal confirmed!</div>
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

                    {/* Actions */}
                    <button
                        onClick={handleWithdraw}
                        disabled={loading || !walletAddress || amountNum <= 0}
                        className="w-full bg-[#00E5B4] text-black font-black text-base h-14 rounded-xl mb-3 shadow-[0_0_20px_rgba(0,229,180,0.2)] active:scale-95 transition-all disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                    >
                        {loading ? (
                            <><Loader2 className="w-5 h-5 animate-spin" /> Confirming...</>
                        ) : (
                            <>⬆ Confirm Withdrawal</>
                        )}
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
