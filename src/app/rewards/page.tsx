"use client";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

import { Gift, Timer, Trophy, ArrowLeft, Crown, Star, Users, Tag, Home } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

export default function RewardsPage() {
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
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <Gift className="w-5 h-5 text-purple-500" /> Season Rewards
                    </h1>
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

            <div className="flex-1 container mx-auto px-4 py-8 space-y-8 max-w-4xl pb-20">

                {/* 1. Hero / Current Season Info */}
                <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-purple-900/20 to-blue-900/20 border border-purple-500/20 p-8 text-center space-y-4">
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-purple-500 to-transparent opacity-50" />
                    <Badge className="bg-purple-500/20 text-purple-300 hover:bg-purple-500/30 border-none">SEASON 1</Badge>
                    <h2 className="text-4xl font-bold tracking-tighter text-white">The Genesis Season</h2>
                    <p className="text-muted-foreground max-w-lg mx-auto">
                        Compete for the title of Clash Master. Top players earn exclusive badges and in-game point bonuses for the next season.
                    </p>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 pt-6 max-w-2xl mx-auto">
                        <StatBox label="Remaining" value="24 Days" icon={Timer} />
                        <StatBox label="Season Reward Pool" value="1,000,000 Pts" icon={Star} />
                        <StatBox label="Participants" value="1,240" icon={Users} />
                        <StatBox label="Your Rank" value="Unranked" icon={Tag} />
                    </div>

                    <p className="text-[10px] text-gray-500 pt-4">
                        Points are virtual and used only within the game. They have no cash value.
                    </p>
                </div>

                {/* 2. Projected Tier (Mock) */}
                <Card className="bg-card/10 border-white/5">
                    <CardHeader>
                        <CardTitle className="text-lg flex items-center gap-2">
                            <TrendingUpIcon className="w-5 h-5 text-emerald-500" /> Your Projected Tier
                        </CardTitle>
                        <CardDescription>Based on your recent performance trends. This is an estimate and may change as other players compete.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-2">
                            <div className="flex justify-between text-sm font-bold">
                                <span className="text-muted-foreground">Current: Novice</span>
                                <span className="text-emerald-400">Projected: Top 50 (Master)</span>
                            </div>
                            <div className="h-3 w-full bg-white/5 rounded-full overflow-hidden">
                                <div className="h-full bg-emerald-500 w-[65%] animate-pulse" />
                            </div>
                            <p className="text-xs text-muted-foreground pt-2">
                                You need <span className="text-white font-bold">450 more points</span> to secure a spot in the Top 100.
                            </p>
                        </div>
                    </CardContent>
                </Card>

                {/* 3. Rank Reward Table */}
                <div className="space-y-4">
                    <h3 className="text-xl font-bold">Reward Tiers</h3>
                    <div className="grid gap-4">
                        <RewardTier rank="Rank #1" reward="Legendary Badge + 10,000 Pts" color="border-yellow-500/50 bg-yellow-500/5" />
                        <RewardTier rank="Rank #2 - #10" reward="Epic Badge + 5,000 Pts" color="border-purple-500/50 bg-purple-500/5" />
                        <RewardTier rank="Rank #11 - #100" reward="Rare Badge + 1,000 Pts" color="border-blue-500/50 bg-blue-500/5" />
                        <RewardTier rank="Participation" reward="Early Adopter Badge" color="border-white/10 bg-white/5" />
                    </div>
                </div>

                {/* 4. Season Reward Rules */}
                <div className="pt-8 border-t border-white/10 space-y-8">
                    <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                        🎁 SEASON REWARD RULES
                    </h2>

                    <p className="text-gray-400">Each competitive season rewards top performers based on leaderboard standings.</p>

                    <Section title="🗓 Season Structure">
                        <ul className="list-disc pl-5 space-y-1 text-gray-300">
                            <li>Seasons run for a fixed duration (e.g., 30 days)</li>
                            <li>Rankings are locked at season end</li>
                            <li>Rewards are distributed after verification</li>
                        </ul>
                    </Section>

                    <Section title="🏆 Reward Eligibility">
                        <p className="text-gray-300 mb-2">To qualify for rewards, players must:</p>
                        <ul className="list-disc pl-5 space-y-1 text-gray-300">
                            <li>Maintain an active account in good standing</li>
                            <li>Avoid any violation of the Anti-Abuse Policy</li>
                            <li>Meet minimum participation requirements (if applicable)</li>
                        </ul>
                        <p className="text-yellow-500/80 text-sm mt-2">Accounts under investigation may have rewards delayed or revoked.</p>
                    </Section>

                    <Section title="🥇 Ranking Tiers (Example Structure)">
                        <div className="overflow-hidden rounded-lg border border-white/10">
                            <table className="w-full text-sm text-left">
                                <thead className="bg-white/5 text-gray-400 font-bold uppercase text-xs">
                                    <tr>
                                        <th className="p-3">Rank Tier</th>
                                        <th className="p-3">Reward Type</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-white/5 text-gray-300">
                                    <tr><td className="p-3">Rank #1</td><td className="p-3">Legendary Badge + Bonus</td></tr>
                                    <tr><td className="p-3">Rank #2 - #10</td><td className="p-3">Epic Badge + Bonus</td></tr>
                                    <tr><td className="p-3">Rank #11 - #100</td><td className="p-3">Rare Badge + Bonus</td></tr>
                                    <tr><td className="p-3">Participants</td><td className="p-3">Participation Badge</td></tr>
                                </tbody>
                            </table>
                        </div>
                        <p className="text-xs text-gray-500 mt-2 text-center">(Exact rewards may change per season.)</p>
                    </Section>

                    <Section title="🎉 Event & Promotion Terms">
                        <p className="text-gray-300 mb-2">Occasionally, special events or promotions may offer bonus rewards.</p>
                        <ul className="list-disc pl-5 space-y-1 text-gray-300">
                            <li>Event rewards may have separate qualification rules</li>
                            <li>Bonus multipliers may apply during special periods</li>
                            <li>Event rewards do not override Anti-Abuse enforcement</li>
                            <li>ChartClash reserves the right to modify or cancel events</li>
                        </ul>
                    </Section>

                    <Section title="🔒 Reward Integrity">
                        <p className="text-gray-300 mb-2">If fraudulent behavior is discovered after season end:</p>
                        <ul className="list-disc pl-5 space-y-1 text-gray-300">
                            <li>Rewards may be revoked</li>
                            <li>Rankings may be recalculated</li>
                            <li>Future participation may be restricted</li>
                        </ul>
                    </Section>
                </div>


            </div>
        </div>
    );
}

function StatBox({ label, value, icon: Icon }: any) {
    return (
        <div className="bg-black/30 p-3 rounded-lg border border-white/5 flex flex-col items-center">
            <Icon className="w-4 h-4 text-purple-400 mb-1" />
            <div className="text-lg font-bold">{value}</div>
            <div className="text-xs text-muted-foreground">{label}</div>
        </div>
    )
}

function RewardTier({ rank, reward, color }: any) {
    return (
        <div className={cn("flex items-center justify-between p-4 rounded-xl border transition-all hover:scale-[1.01]", color)}>
            <div className="flex items-center gap-4">
                <div className="font-bold text-lg">{rank}</div>
            </div>
            <div className="flex items-center gap-2 font-mono font-bold text-sm md:text-base">
                <Gift className="w-4 h-4 opacity-50" /> {reward}
            </div>
        </div>
    )
}

function TrendingUpIcon(props: any) {
    return (
        <svg
            {...props}
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" />
            <polyline points="16 7 22 7 22 13" />
        </svg>
    )
}

function Section({ title, children }: { title: string, children: React.ReactNode }) {
    return (
        <section>
            <h3 className="text-lg font-bold text-white mb-2">{title}</h3>
            <div className="pl-6 border-l-2 border-white/10 ml-1 space-y-2">
                {children}
            </div>
        </section>
    );
}
