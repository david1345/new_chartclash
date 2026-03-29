"use client";

import Link from "next/link";
import { ArrowLeft, AlertTriangle, BarChart2, Clock, Globe, Home, ShieldCheck, Target, TrendingUp, Wallet } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function HowItWorksPage() {
    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight">How It Works</h1>
                    <div className="ml-auto">
                        <Link href="/">
                            <Button variant="ghost" size="sm" className="gap-2 text-muted-foreground hover:text-white">
                                <Home className="w-4 h-4" />
                                <span className="hidden sm:inline">Home</span>
                            </Button>
                        </Link>
                    </div>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-12 max-w-4xl pb-20">
                <div className="space-y-4">
                    <h2 className="text-3xl font-bold text-white flex items-center gap-2">
                        <Target className="w-8 h-8 text-indigo-500" /> What is ChartClash?
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1">
                        <p className="text-lg text-gray-300 leading-relaxed">
                            ChartClash is a thesis-driven USDT market where traders take long or short positions on scheduled price rounds.
                            Every round has a fixed open price, a fixed close time, and a fixed resolution source.
                        </p>
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                    <StepCard step={1} title="Sign In" desc="Create an account so your positions, history, and portfolio can be mirrored in-app." icon={ShieldCheck} color="text-blue-500" />
                    <StepCard step={2} title="Fund Wallet" desc="Connect MetaMask and deposit USDT into your contract balance before entering a round." icon={Wallet} color="text-emerald-500" />
                    <StepCard step={3} title="Pick Long / Short" desc="Choose the asset, timeframe, and side you want to back for the live round." icon={TrendingUp} color="text-red-500" />
                    <StepCard step={4} title="Let It Resolve" desc="Once the round closes, the official source settles the outcome as win, loss, or refund." icon={Clock} color="text-yellow-500" />
                </div>

                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Wallet className="w-6 h-6 text-emerald-500" /> Funding & Position Flow
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <Card className="bg-emerald-500/5 border-emerald-500/20">
                            <CardHeader className="pb-2">
                                <Badge variant="outline" className="w-fit border-emerald-500/50 text-emerald-500 mb-2">Capital In</Badge>
                                <CardTitle className="text-emerald-400">Deposit Into Contract Balance</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-3 text-sm text-gray-300">
                                <p>USDT is deposited once into the ChartClash contract and becomes your available staking balance.</p>
                                <ul className="space-y-2">
                                    <li>Supported network only</li>
                                    <li>Visible in header, wallet, and stake composer</li>
                                    <li>Used directly for round participation</li>
                                </ul>
                            </CardContent>
                        </Card>

                        <Card className="bg-blue-500/5 border-blue-500/20">
                            <CardHeader className="pb-2">
                                <Badge variant="outline" className="w-fit border-blue-500/50 text-blue-400 mb-2">Capital Out</Badge>
                                <CardTitle className="text-blue-400">Withdraw Available Balance</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-3 text-sm text-gray-300">
                                <p>Uncommitted balance can be withdrawn back to your wallet after on-chain processing and any configured withdrawal fee.</p>
                                <ul className="space-y-2">
                                    <li>Only free balance is withdrawable</li>
                                    <li>Closed rounds must finish first</li>
                                    <li>Withdrawals settle on-chain</li>
                                </ul>
                            </CardContent>
                        </Card>
                    </div>
                </div>

                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <BarChart2 className="w-6 h-6 text-purple-500" /> Payout Model
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1 space-y-4 text-gray-300">
                        <p>ChartClash uses a pari-mutuel structure. Winners split the losing side's pool pro-rata.</p>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse border border-white/10 rounded-lg overflow-hidden">
                                <thead>
                                    <tr className="bg-white/10 text-white text-sm uppercase">
                                        <th className="p-3 border-b border-white/10">Outcome</th>
                                        <th className="p-3 border-b border-white/10">Condition</th>
                                        <th className="p-3 border-b border-white/10 text-right">Result</th>
                                    </tr>
                                </thead>
                                <tbody className="text-gray-300 text-sm">
                                    <tr className="bg-emerald-500/5">
                                        <td className="p-3 border-b border-white/5 font-bold text-emerald-500">WIN</td>
                                        <td className="p-3 border-b border-white/5">Your side matches the settled direction</td>
                                        <td className="p-3 border-b border-white/5 text-right text-emerald-400 font-bold">Stake + share of losing pool</td>
                                    </tr>
                                    <tr className="bg-red-500/5">
                                        <td className="p-3 border-b border-white/5 font-bold text-red-500">LOSS</td>
                                        <td className="p-3 border-b border-white/5">The opposite side wins the round</td>
                                        <td className="p-3 border-b border-white/5 text-right text-red-400 font-bold">Lose stake</td>
                                    </tr>
                                    <tr className="bg-white/5">
                                        <td className="p-3 font-bold text-gray-400">REFUND</td>
                                        <td className="p-3">One-sided pool or flat close</td>
                                        <td className="p-3 text-right text-gray-300 font-bold">Stake returned</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        <p>Earlier GREEN entries receive a lower fee on winnings than later YELLOW or RED entries.</p>
                    </div>
                </div>

                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Clock className="w-6 h-6 text-blue-500" /> Round Timing
                    </h2>
                    <div className="space-y-4 text-gray-300 pl-6 border-l-2 border-white/10 ml-1">
                        <p>Each asset/timeframe pair runs in repeating rounds. A new round opens, accepts bets for a limited window, then locks and waits for settlement.</p>
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            Example: <span className="font-bold text-white">BTCUSDT · 1H</span> opens on the hourly candle and resolves against the official close.
                        </div>
                        <p>The final 10% of the round is blocked for new bets. This prevents last-second sniping and keeps the market fair.</p>
                    </div>
                </div>

                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Globe className="w-6 h-6 text-cyan-500" /> Data & Resolution
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1">
                        <p className="text-gray-300">Every market resolves against a fixed reference source declared before the round opens.</p>
                        <ul className="mt-4 space-y-2 text-sm text-gray-400">
                            <li>Crypto: Binance spot candle close</li>
                            <li>Fallback: secondary market data with operator clarification log</li>
                            <li>Ties or one-sided rounds: refunded rather than force-settled</li>
                        </ul>
                    </div>
                </div>

                <Card className="bg-red-500/10 border-red-500/20">
                    <CardContent className="p-6">
                        <h3 className="text-xl font-bold text-red-500 flex items-center gap-2 mb-3">
                            <AlertTriangle className="w-5 h-5" /> Risk Notice
                        </h3>
                        <p className="text-gray-300">
                            ChartClash is a real-money risk product. Losses are possible on every round, and nothing on the platform should be treated as financial advice or guaranteed return.
                        </p>
                    </CardContent>
                </Card>

                <div className="text-center pt-8">
                    <Link href="/">
                        <Button size="lg" className="w-[220px] text-lg font-bold bg-indigo-600 hover:bg-indigo-700">Open Markets</Button>
                    </Link>
                </div>
            </div>
        </div>
    );
}

function StepCard({ step, title, desc, icon: Icon, color }: any) {
    return (
        <Card className="bg-card/10 border-white/5">
            <CardContent className="p-5 space-y-3">
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full border border-white/10 bg-white/5 flex items-center justify-center text-xs font-black">{step}</div>
                    <Icon className={`w-5 h-5 ${color}`} />
                </div>
                <div className="text-white font-bold">{title}</div>
                <p className="text-sm text-gray-400 leading-relaxed">{desc}</p>
            </CardContent>
        </Card>
    );
}
