"use client";

import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Medal, Lock, Star } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

export default function AchievementsPage() {
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
                        <Medal className="w-5 h-5 text-yellow-500" /> Achievements
                    </h1>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-6 max-w-4xl pb-20">

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <AchievementCard
                        title="First Blood"
                        desc="Make your first prediction"
                        unlocked
                        icon={Star}
                        color="text-yellow-500"
                    />
                    <AchievementCard
                        title="Sniper"
                        desc="Hit a 2% target volatility"
                        progress="2/5"
                        icon={TargetIcon}
                    />
                    <AchievementCard
                        title="Chart Check"
                        desc="Win 5 predictions in a row"
                        progress="3/5"
                        icon={FlameIcon}
                    />
                    <AchievementCard
                        title="BTC Whale"
                        desc="Trade 100 times on BTC/USDT"
                        progress="12/100"
                        icon={BitcoinIcon}
                    />
                    <AchievementCard
                        title="Diamond Hands"
                        desc="Hold a prediction for >4 hrs"
                        locked
                    />
                    <AchievementCard
                        title="Bear Slayer"
                        desc="Win 10 SHORT positions"
                        locked
                    />
                    <AchievementCard
                        title="Bull Rider"
                        desc="Win 10 LONG positions"
                        locked
                    />
                    <AchievementCard
                        title="Millionaire"
                        desc="Reach 1,000,000 Pts"
                        locked
                    />
                </div>

            </div>
        </div>
    );
}

function AchievementCard({ title, desc, unlocked, locked, progress, icon: Icon, color }: any) {
    return (
        <Card className={cn("bg-card/10 border-white/5 transition-colors relative overflow-hidden group", unlocked ? "border-yellow-500/30 bg-yellow-500/5 hover:bg-yellow-500/10" : "opacity-70")}>
            <CardContent className="p-6 flex flex-col items-center text-center gap-3">
                {locked && <div className="absolute top-2 right-2"><Lock className="w-4 h-4 text-muted-foreground" /></div>}

                <div className={cn("w-12 h-12 rounded-full flex items-center justify-center border-2 mb-1", unlocked ? "bg-yellow-500/20 border-yellow-500" : "bg-white/5 border-white/10")}>
                    {Icon ? <Icon className={cn("w-6 h-6", unlocked ? color : "text-muted-foreground")} /> : <Medal className="w-6 h-6 text-muted-foreground" />}
                </div>

                <div className="space-y-1">
                    <h3 className={cn("font-bold text-sm", unlocked && "text-white")}>{title}</h3>
                    <p className="text-xs text-muted-foreground leading-snug">{desc}</p>
                </div>

                {progress && (
                    <div className="w-full space-y-1 mt-2">
                        <div className="text-[10px] text-right text-muted-foreground font-mono">{progress}</div>
                        <div className="h-1.5 w-full bg-white/10 rounded-full overflow-hidden">
                            <div className="h-full bg-yellow-500" style={{ width: '30%' }} />
                        </div>
                    </div>
                )}
            </CardContent>
        </Card>
    )
}

function TargetIcon(props: any) { return <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><circle cx="12" cy="12" r="6" /><circle cx="12" cy="12" r="2" /></svg> }
function FlameIcon(props: any) { return <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.1.2-2.2.5-3.3.3-1.072 1.072-1.928 2.5-1.2Z" /></svg> }
function BitcoinIcon(props: any) { return <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11.767 19.089c4.924.868 6.14-6.025 1.216-6.894m-1.216 6.894L5.86 18.047m5.908 1.042-.347 1.97m1.563-8.864c4.924.869 6.14-6.025 1.215-6.893m-1.215 6.893-3.94-.694m5.155-6.2L14.06 9.25m-1.563-8.864L11.9 2.55" /></svg> }
