"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Target, TrendingUp, Trophy, AlertTriangle, Info, Clock, BarChart2, Home, Flame, Check, Minus, Globe } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

export default function HowItWorksPage() {
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

                {/* Intro */}
                <div className="space-y-4">
                    <h2 className="text-3xl font-bold text-white flex items-center gap-2">
                        <Target className="w-8 h-8 text-indigo-500" /> What is ChartClash?
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1">
                        <p className="text-lg text-gray-300 leading-relaxed">
                            ChartClash is a skill-based prediction game where players forecast short-term market movements of financial assets. Correct predictions earn points. Incorrect ones lose points. Clash with the market and win seasonal rewards.
                        </p>
                    </div>
                </div>

                {/* Steps (Restored) */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                    <StepCard
                        step={1}
                        title="Select Your Market"
                        desc="Choose a crypto/stock/commodity asset and a timeframe (e.g. BTC · 15m). Analyze the chart yourself or follow the market sentiment."
                        icon={TrendingUp}
                        color="text-blue-500"
                    />
                    <StepCard
                        step={2}
                        title="Make Your Prediction"
                        desc="Pick a direction: UP or DOWN. Set your volatility target (e.g. 0.5% price move). Higher targets mean higher risk and higher rewards."
                        icon={Target}
                        color="text-red-500"
                    />
                    <StepCard
                        step={3}
                        title="Earn Points & Climb"
                        desc="If the candle closes in your predicted direction and reaches your target, you earn points. Consistent accuracy moves you up the leaderboard rankings."
                        icon={Trophy}
                        color="text-yellow-500"
                    />
                </div>

                {/* Risk vs Reward */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Flame className="w-6 h-6 text-orange-500" /> RISK vs REWARD
                    </h2>
                    <p className="text-gray-400 pl-1">
                        Choose your target wisely. Bigger moves are harder to hit — but pay more points.
                    </p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        {/* Low Risk */}
                        <Card className="bg-emerald-500/5 border-emerald-500/20">
                            <CardHeader className="pb-2">
                                <Badge variant="outline" className="w-fit border-emerald-500/50 text-emerald-500 mb-2">LOW RISK</Badge>
                                <CardTitle className="text-emerald-400">Target Move: 0.5%</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <ul className="space-y-2 text-sm">
                                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-emerald-500" /> Easier to reach</li>
                                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-emerald-500" /> More frequent wins</li>
                                    <li className="flex items-center gap-2"><Minus className="w-4 h-4 text-gray-500" /> Lower point reward</li>
                                </ul>
                                <div className="bg-black/20 p-3 rounded text-sm space-y-1 border border-white/5">
                                    <div className="text-muted-foreground text-xs font-bold uppercase">Example Outcome</div>
                                    <div className="flex justify-between"><span>Stake:</span> <span>100 pts</span></div>
                                    <div className="flex justify-between font-bold text-emerald-500"><span>Win Reward:</span> <span>+120 pts</span></div>
                                </div>
                                <p className="text-xs text-emerald-500/80 italic">Best for: Beginners, steady point growth</p>
                            </CardContent>
                        </Card>

                        {/* High Risk */}
                        <Card className="bg-red-500/5 border-red-500/20">
                            <CardHeader className="pb-2">
                                <Badge variant="outline" className="w-fit border-red-500/50 text-red-500 mb-2">HIGH RISK</Badge>
                                <CardTitle className="text-red-400">Target Move: 2.0%</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                <ul className="space-y-2 text-sm">
                                    <li className="flex items-center gap-2"><Minus className="w-4 h-4 text-gray-500" /> Harder to reach</li>
                                    <li className="flex items-center gap-2"><Minus className="w-4 h-4 text-gray-500" /> Less frequent wins</li>
                                    <li className="flex items-center gap-2"><Check className="w-4 h-4 text-red-500" /> Much higher point reward</li>
                                </ul>
                                <div className="bg-black/20 p-3 rounded text-sm space-y-1 border border-white/5">
                                    <div className="text-muted-foreground text-xs font-bold uppercase">Example Outcome</div>
                                    <div className="flex justify-between"><span>Stake:</span> <span>100 pts</span></div>
                                    <div className="flex justify-between font-bold text-red-500"><span>Win Reward:</span> <span>+300 pts</span></div>
                                </div>
                                <p className="text-xs text-red-500/80 italic">Best for: Experienced players, leaderboard climbers</p>
                            </CardContent>
                        </Card>
                    </div>
                    <p className="text-center text-sm text-muted-foreground">
                        Higher targets mean fewer wins, but bigger jumps in the rankings.
                    </p>
                </div>

                {/* Prediction Rounds */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Clock className="w-6 h-6 text-blue-500" /> Prediction Rounds
                    </h2>
                    <div className="space-y-4 text-gray-300 pl-6 border-l-2 border-white/10 ml-1">
                        <p>Each asset and timeframe runs in repeating rounds based on candle duration.</p>
                        <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                            <span className="font-bold text-white">Example:</span> <span className="text-yellow-400">BTC • 15m</span> → A new round begins every 15 minutes.
                        </div>
                        <p>You can submit predictions during the <strong className="text-green-400">Open Phase</strong> (first 1/3 of the candle).<br />After that, predictions are locked until the next round.</p>
                    </div>
                </div>

                {/* Resolution */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <BarChart2 className="w-6 h-6 text-green-500" /> How Predictions Are Resolved
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1 space-y-4">
                        <p className="text-gray-300">Predictions are evaluated using the <strong className="text-white">CLOSE price</strong> of the selected candle.</p>

                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse border border-white/10 rounded-lg overflow-hidden">
                                <thead>
                                    <tr className="bg-white/10 text-white text-sm uppercase">
                                        <th className="p-3 border-b border-white/10 w-24">Result</th>
                                        <th className="p-3 border-b border-white/10">Condition</th>
                                        <th className="p-3 border-b border-white/10 text-right">Outcome</th>
                                    </tr>
                                </thead>
                                <tbody className="text-gray-300 text-sm">
                                    <tr className="bg-emerald-500/5">
                                        <td className="p-3 border-b border-white/5 font-bold text-emerald-500">WIN</td>
                                        <td className="p-3 border-b border-white/5">Price moves in predicted direction <strong className="text-white">(Target % is Bonus)</strong></td>
                                        <td className="p-3 border-b border-white/5 text-right text-emerald-400 font-bold">Earn Points</td>
                                    </tr>
                                    <tr className="bg-red-500/5">
                                        <td className="p-3 border-b border-white/5 font-bold text-red-500">LOSS</td>
                                        <td className="p-3 border-b border-white/5">Price moves in opposite direction</td>
                                        <td className="p-3 border-b border-white/5 text-right text-red-400 font-bold">Lose Points</td>
                                    </tr>
                                    <tr className="bg-white/5">
                                        <td className="p-3 font-bold text-gray-400">ND</td>
                                        <td className="p-3 space-y-1">
                                            <div className="flex items-center gap-2"><span className="text-gray-500">-</span> Close price = Open price (No move)</div>
                                        </td>
                                        <td className="p-3 text-right text-gray-400 font-bold">Return Points</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                {/* Scoring */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <TrendingUp className="w-6 h-6 text-purple-500" /> Scoring Mechanics (Final Formula)
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1">
                        <p className="text-gray-300 mb-4">
                            Your final score is calculated using a compound multiplier system designed to reward skill, consistency, and reasonable risk-taking.
                        </p>

                        <div className="space-y-4">
                            <RuleItem icon="⏱" text="Longer timeframes = Higher rewards" sub="Bigger moves over longer periods offer greater point payouts." />
                            <RuleItem icon="📊" text="Larger target % moves = Higher rewards" sub="Higher risk predictions earn bigger rewards." />
                            <RuleItem icon="🔥" text="Winning streaks (3+ wins) activate combo multipliers" sub="Consistent performance unlocks bonus point boosts." />
                        </div>
                    </div>
                </div>

                {/* Real Data Notice */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Globe className="w-6 h-6 text-cyan-500" /> Real-Time Market Data
                    </h2>
                    <div className="pl-6 border-l-2 border-white/10 ml-1">
                        <p className="text-gray-300">
                            ChartClash uses <strong>Institutional Grade Data</strong> for all resolutions.
                        </p>
                        <ul className="mt-4 space-y-2 text-sm text-gray-400">
                            <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-yellow-400" /> Crypto: <strong>Binance Spot API</strong></li>
                            <li className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-blue-400" /> Stocks & Commodities: <strong>Yahoo Finance API</strong></li>
                        </ul>
                    </div>
                </div>

                {/* Leaderboards */}
                <div className="space-y-6">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        <Trophy className="w-6 h-6 text-yellow-500" /> Leaderboards
                    </h2>
                    <div className="text-gray-300 space-y-2 pl-6 border-l-2 border-white/10 ml-1">
                        <p>Players are ranked based on:</p>
                        <ul className="list-disc pl-5 space-y-1">
                            <li>Total points</li>
                            <li>Consistency</li>
                            <li>Performance across different assets and timeframes</li>
                        </ul>
                        <p className="pt-2 text-yellow-500 font-semibold">Top players earn Season Rewards.</p>
                    </div>
                </div>

                {/* Fair Play */}
                <Card className="bg-red-500/10 border-red-500/20">
                    <CardContent className="p-6">
                        <h3 className="text-xl font-bold text-red-500 flex items-center gap-2 mb-3">
                            <AlertTriangle className="w-5 h-5" /> Fair Play Notice
                        </h3>
                        <p className="text-gray-300">
                            Using bots, scripts, automation tools, or multiple accounts to gain advantage is strictly prohibited and may lead to penalties or permanent bans.
                            <Link href="/legal/anti-abuse" className="text-red-400 hover:text-red-300 ml-1 underline underline-offset-4">
                                See Anti-Abuse Policy for details.
                            </Link>
                        </p>
                    </CardContent>
                </Card>

                {/* Start CTA */}
                <div className="text-center pt-8">
                    <Link href="/">
                        <Button size="lg" className="w-[200px] text-lg font-bold bg-indigo-600 hover:bg-indigo-700">Start Playing</Button>
                    </Link>
                </div>

            </div>
        </div>
    );
}

function StepCard({ step, title, desc, icon: Icon, color }: any) {
    return (
        <Card className="bg-card/10 border-white/5 relative overflow-hidden group hover:bg-white/5 transition-colors">
            <CardContent className="p-6 pt-8 text-center space-y-4">
                <div className={cn("absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-current to-transparent opacity-50", color)} />
                <div className="mx-auto w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                    <Icon className={cn("w-8 h-8", color)} />
                </div>
                <div className="space-y-2">
                    <div className="text-sm font-bold text-muted-foreground uppercase tracking-widest">Step 0{step}</div>
                    <h3 className="text-xl font-bold text-white">{title}</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">{desc}</p>
                </div>
            </CardContent>
        </Card>
    )
}

function ResultRow({ situation, result }: { situation: string, result: string }) {
    return (
        <div className="flex items-center justify-between p-3 rounded bg-white/5 border border-white/5 text-sm md:text-base">
            <span className="text-gray-300">{situation}</span>
            <span className="font-bold text-white">{result}</span>
        </div>
    );
}

function RuleItem({ icon, text, sub }: { icon: string, text: string, sub?: string }) {
    return (
        <div className="flex items-start gap-3 p-3 rounded-lg border border-white/5 bg-black/20">
            <span className="text-xl">{icon}</span>
            <div className="flex-1 space-y-1">
                <p className="font-bold text-gray-200">{text}</p>
                {sub && <p className="text-xs text-gray-400">{sub}</p>}
            </div>
        </div>
    );
}
