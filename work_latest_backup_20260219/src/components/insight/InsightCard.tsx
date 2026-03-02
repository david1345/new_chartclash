"use client";

import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowUpRight, ArrowDownRight, Flame, MessageSquare, ThumbsUp } from "lucide-react"
import { cn } from "@/lib/utils"

export interface InsightCardProps {
    id: string | number
    username: string
    badge: string
    winRate: number
    asset: string
    timeframe: string
    reasoning: string
    direction: "UP" | "DOWN"
    targetPercent: number
    result: "WIN" | "LOSS" | "PENDING" | "pending" | "ND"
    likes: number
    comments: number
    score: number
    createdAt: string
    entryPrice?: number
    currentPrice?: number
}

export function InsightCard(props: InsightCardProps) {
    const {
        username, badge, winRate, asset, timeframe,
        reasoning, direction, targetPercent,
        result, likes, comments, score, createdAt
    } = props

    // Robust Badge Class Logic
    const getBadgeStyle = (b: string) => {
        const upperB = b.toUpperCase();
        if (upperB.includes("LEGEND")) return "bg-orange-500/20 text-orange-500 border-orange-500/50";
        if (upperB.includes("MASTER")) return "bg-yellow-500/20 text-yellow-500 border-yellow-500/50";
        if (upperB.includes("PRO")) return "bg-purple-500/20 text-purple-500 border-purple-500/50";
        if (upperB.includes("SKILLED")) return "bg-blue-500/20 text-blue-500 border-blue-500/50";
        return "text-muted-foreground border-white/20";
    };

    return (
        <Card className="bg-white/5 border-white/10 hover:border-primary/40 transition group overflow-hidden">
            <CardContent className="p-5 space-y-4">

                {/* Top Row */}
                <div className="flex justify-between items-start">
                    <div className="space-y-1">
                        <div className="flex items-center gap-2 flex-wrap">
                            <Badge variant="outline" className={cn(
                                "text-[10px] px-1.5 py-0 h-5",
                                getBadgeStyle(badge)
                            )}>
                                {badge}
                            </Badge>
                            <span className={cn("text-xs font-mono font-bold", winRate >= 50 ? "text-emerald-500" : "text-muted-foreground")}>
                                {winRate}% Win Rate
                            </span>
                        </div>

                        <div className="flex items-center gap-2">
                            <div className="text-sm font-bold text-white">@{username}</div>
                            <div className="text-[10px] text-muted-foreground uppercase tracking-wider flex items-center gap-1.5">
                                <span>{asset}</span>
                                <span className="w-0.5 h-0.5 bg-white/20 rounded-full" />
                                <span>{timeframe}</span>
                                <span className="w-0.5 h-0.5 bg-white/20 rounded-full" />
                                <span>{createdAt}</span>
                            </div>
                        </div>
                    </div>

                    <div className="flex flex-col items-end gap-1.5">
                        <div className="flex items-center gap-1.5 bg-orange-500/10 border border-orange-500/20 px-2 py-1 rounded-md">
                            <Flame className="w-3.5 h-3.5 text-orange-500 fill-orange-500/20" />
                            <span className="text-xs font-bold text-orange-500">{Math.round(score)}</span>
                        </div>
                    </div>
                </div>

                {/* Reasoning */}
                <p className="text-sm leading-relaxed text-gray-300 pl-3 border-l-2 border-white/10 italic">
                    "{reasoning}"
                </p>

                {/* Prediction Result */}
                <div className="flex items-center justify-between text-xs border-t border-white/5 pt-3 mt-2">
                    <div className="flex items-center gap-3">
                        <Badge variant="outline" className={cn(
                            "text-xs px-2 py-0.5 h-6 capitalize border-0",
                            direction === "UP" ? "bg-emerald-500/10 text-emerald-500" : "bg-red-500/10 text-red-500"
                        )}>
                            {direction === "UP" ? <ArrowUpRight className="w-3.5 h-3.5 mr-1" /> : <ArrowDownRight className="w-3.5 h-3.5 mr-1" />}
                            {direction} {targetPercent}%
                        </Badge>

                        {/* Show entry price if available */}
                        {props.entryPrice && (
                            <span className="text-muted-foreground font-mono">Entry: {props.entryPrice}</span>
                        )}
                    </div>

                    <div className={cn(
                        "font-bold px-2 py-0.5 rounded text-[10px] uppercase tracking-wider",
                        result === "WIN" && "text-emerald-400 bg-emerald-400/10",
                        result === "LOSS" && "text-red-400 bg-red-400/10",
                        (result === "PENDING" || result === "pending") && "text-yellow-400 bg-yellow-400/10",
                        result === "ND" && "text-gray-400 bg-gray-400/10"
                    )}>
                        {result}
                    </div>
                </div>

                {/* Social */}
                <div className="flex gap-4 text-xs text-muted-foreground pt-1">
                    <div className="flex items-center gap-1.5 hover:text-white transition-colors cursor-pointer">
                        <ThumbsUp className="w-3.5 h-3.5" /> {likes}
                    </div>
                    <div className="flex items-center gap-1.5 hover:text-white transition-colors cursor-pointer">
                        <MessageSquare className="w-3.5 h-3.5" /> {comments}
                    </div>
                </div>

            </CardContent>
        </Card>
    )
}
