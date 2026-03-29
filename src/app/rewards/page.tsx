"use client";

import Link from "next/link";
import { ArrowLeft, Gift, Home, ShieldCheck, Star, Tag, Timer, Users } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export default function RewardsPage() {
    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <Gift className="w-5 h-5 text-purple-500" /> Programs & Rewards
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
                <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-purple-900/20 to-blue-900/20 border border-purple-500/20 p-8 text-center space-y-4">
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-purple-500 to-transparent opacity-50" />
                    <Badge className="bg-purple-500/20 text-purple-300 hover:bg-purple-500/30 border-none">Beta Program</Badge>
                    <h2 className="text-4xl font-bold tracking-tighter text-white">Launch Incentives</h2>
                    <p className="text-muted-foreground max-w-lg mx-auto">
                        ChartClash is moving toward real-money market participation. Future programs may reward early users with access, fee rebates, badges, and campaign-specific benefits.
                    </p>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 pt-6 max-w-2xl mx-auto">
                        <StatBox label="Phase" value="Closed Beta" icon={Timer} />
                        <StatBox label="Campaign Type" value="Invite + Volume" icon={Star} />
                        <StatBox label="Participants" value="Rolling" icon={Users} />
                        <StatBox label="Access" value="Review Queue" icon={Tag} />
                    </div>
                </div>

                <Card className="bg-card/10 border-white/5">
                    <CardHeader>
                        <CardTitle className="text-lg flex items-center gap-2">
                            <ShieldCheck className="w-5 h-5 text-emerald-500" /> What Rewards May Look Like
                        </CardTitle>
                        <CardDescription>Program structures can change before public launch.</CardDescription>
                    </CardHeader>
                    <CardContent className="grid gap-4 md:grid-cols-3">
                        <RewardCard title="Access" body="Priority onboarding, beta invitations, and early access to new market categories." />
                        <RewardCard title="Fee Benefits" body="Campaign-based withdrawal or winnings fee discounts for qualified users." />
                        <RewardCard title="Recognition" body="Profile badges, leaderboard callouts, and seasonal recognition for early contributors." />
                    </CardContent>
                </Card>

                <div className="space-y-4">
                    <h3 className="text-xl font-bold">Program Rules</h3>
                    <div className="grid gap-4">
                        <RuleCard title="Eligibility" body="Accounts must remain in good standing and comply with platform, compliance, and anti-abuse rules." color="border-emerald-500/30 bg-emerald-500/5" />
                        <RuleCard title="Verification" body="Any campaign benefit may require identity, wallet, or activity verification before it is granted." color="border-blue-500/30 bg-blue-500/5" />
                        <RuleCard title="Enforcement" body="Benefits may be delayed, reduced, or revoked if abuse, multi-accounting, or manipulation is detected." color="border-red-500/30 bg-red-500/5" />
                    </div>
                </div>

                <div className="pt-8 border-t border-white/10 space-y-8">
                    <Section title="Program Notes">
                        <ul className="list-disc pl-5 space-y-1 text-gray-300">
                            <li>Not every season or campaign will include direct monetary rewards.</li>
                            <li>Some benefits may take the form of fee rebates, badges, or gated access.</li>
                            <li>Program availability can change by jurisdiction and compliance status.</li>
                        </ul>
                    </Section>

                    <Section title="Integrity">
                        <p className="text-gray-300">
                            ChartClash reserves the right to review suspicious activity and remove participants from promotional programs where necessary to preserve fairness.
                        </p>
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
    );
}

function RewardCard({ title, body }: { title: string; body: string }) {
    return (
        <div className="rounded-xl border border-white/10 bg-white/5 p-4">
            <div className="font-bold text-white">{title}</div>
            <p className="mt-2 text-sm text-gray-400 leading-relaxed">{body}</p>
        </div>
    );
}

function RuleCard({ title, body, color }: { title: string; body: string; color: string }) {
    return (
        <div className={cn("rounded-xl border p-4", color)}>
            <div className="font-bold text-white">{title}</div>
            <p className="mt-2 text-sm text-gray-400 leading-relaxed">{body}</p>
        </div>
    );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
    return (
        <section>
            <h3 className="text-lg font-bold text-white mb-2">{title}</h3>
            <div className="pl-6 border-l-2 border-white/10 ml-1 space-y-2">{children}</div>
        </section>
    );
}
