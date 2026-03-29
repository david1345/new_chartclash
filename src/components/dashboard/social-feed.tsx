"use client";

import { Activity, ArrowUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { useState } from "react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { InsightCard } from "@/components/insight/InsightCard";
import { calculateInsightScore } from "@/lib/insight-score";
import { useMounted } from "@/hooks/use-mounted";

interface SocialFeedProps {
    feed: any[];
    selectedAsset: any;
    user: any;
    refreshFeed?: () => void;
}

export function SocialFeed({ feed, selectedAsset, user, refreshFeed }: SocialFeedProps) {
    const [comment, setComment] = useState("");
    const [isSubmitting, setIsSubmitting] = useState(false);
    const supabase = createClient();
    const mounted = useMounted();

    const handlePostComment = async () => {
        if (!user || !comment.trim()) {
            toast.error("Please write a comment");
            return;
        }

        setIsSubmitting(true);

        try {
            // 1. Find latest PENDING prediction for THIS ASSET
            const { data: latest, error: fetchError } = await supabase
                .from('predictions')
                .select('id')
                .eq('user_id', user.id)
                .eq('asset_symbol', selectedAsset.symbol)
                .eq('status', 'pending')
                .order('created_at', { ascending: false })
                .limit(1)
                .maybeSingle();

            if (fetchError || !latest) {
                toast.error("You must have an active bet in this asset to post!");
                setIsSubmitting(false);
                return;
            }

            // 2. Update comment
            const { error: updateError } = await supabase
                .from('predictions')
                .update({ comment: comment.trim() })
                .eq('id', latest.id);

            if (updateError) {
                console.error("Comment update error:", updateError);
                toast.error("Failed to post comment");
            } else {
                toast.success("Alpha shared!");
                setComment("");
                if (refreshFeed) refreshFeed();
            }
        } catch (err) {
            console.error("Unexpected error:", err);
            toast.error("Something went wrong");
        } finally {
            setIsSubmitting(false);
        }
    };

    const displayFeed = feed.length > 0 ? feed : [
        {
            id: 'dummy-1',
            created_at: new Date().toISOString(),
            profiles: { username: 'crypto_king', tier: 'PRO', total_games: 100, total_wins: 65 },
            direction: 'UP',
            timeframe: '15m',
            asset_symbol: selectedAsset.symbol,
            target_percent: 1.5,
            status: 'pending',
            likes_count: 12,
            comment: "Breaking resistance, sending it! 🔥 3 wins in a row!"
        },
        {
            id: 'dummy-2',
            created_at: new Date(Date.now() - 120000).toISOString(),
            profiles: { username: 'moon_boy', tier: 'MASTER', total_games: 250, total_wins: 180 },
            direction: 'DOWN',
            timeframe: '1h',
            asset_symbol: selectedAsset.symbol,
            target_percent: 2.0,
            status: 'WIN',
            likes_count: 45,
            comment: "RSI divergence on the 5m looks heavy. Shorting here. 💰"
        },
        {
            id: 'dummy-3',
            created_at: new Date(Date.now() - 300000).toISOString(),
            profiles: { username: 'whale_trader', tier: 'LEGEND', total_games: 500, total_wins: 400 },
            direction: 'UP',
            timeframe: '4h',
            asset_symbol: selectedAsset.symbol,
            target_percent: 0.5,
            status: 'WIN',
            likes_count: 89,
            comment: "Easy scalp. Real size got paid. Watching for the next continuation setup."
        }
    ];

    return (
        <Card className="bg-[#0F1623] border-[#1E2D45] flex flex-col overflow-hidden min-h-0 basis-0 grow">
            <CardHeader className="py-2 px-3 border-b border-[#1E2D45] bg-[#141D2E] min-h-[36px] flex-none flex flex-row items-center justify-between">
                <CardTitle className="text-xs font-bold flex items-center gap-2">
                    <div className="relative">
                        <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse absolute -right-0.5 -top-0.5" />
                        <Activity className="w-3 h-3" />
                    </div>
                    Live Clash Feed
                </CardTitle>
                <span className="text-[9px] text-muted-foreground uppercase tracking-widest font-mono">
                    {selectedAsset.symbol}
                </span>
            </CardHeader>
            <div className="flex-1 flex flex-col p-2 gap-2 overflow-hidden bg-[#0F1623] min-h-0">
                <div className="flex-1 min-h-0 relative">
                    <ScrollArea className="absolute inset-0 h-full w-full pr-2">
                        <div className="space-y-3 pb-2">
                            {displayFeed.map((post) => {
                                const userWinRate = post.profiles?.total_games > 0
                                    ? (post.profiles.total_wins / post.profiles.total_games) * 100
                                    : 0;

                                const score = calculateInsightScore({
                                    status: post.status,
                                    targetPercent: post.target_percent || 0,
                                    likes: post.likes_count || 0,
                                    comments: 0,
                                    userWinRate,
                                    createdAt: post.created_at
                                });

                                return (
                                    <InsightCard
                                        key={post.id}
                                        id={post.id}
                                        username={post.profiles?.username || 'Trader'}
                                        badge={post.profiles?.tier || 'Novice'}
                                        winRate={Math.round(userWinRate)}
                                        asset={post.asset_symbol || selectedAsset.symbol}
                                        timeframe={post.timeframe || '??'}
                                        reasoning={post.comment}
                                        direction={post.direction}
                                        targetPercent={post.target_percent || 0}
                                        result={post.status}
                                        likes={post.likes_count || 0}
                                        comments={0}
                                        score={score}
                                        createdAt={mounted ? new Date(post.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "--:--"}
                                        entryPrice={post.entry_price}
                                    />
                                );
                            })}
                        </div>
                    </ScrollArea>
                </div>

                <div className="flex gap-2 shrink-0 pt-1">
                    <Input
                        data-testid="comment-input"
                        placeholder="Share your reasoning..."
                        className="h-8 text-xs bg-black/30 border-white/10"
                        value={comment}
                        onChange={(e) => setComment(e.target.value)}
                        onKeyDown={(e) => {
                            if (e.nativeEvent.isComposing) return;
                            if (e.key === 'Enter') handlePostComment();
                        }}
                    />
                    <Button
                        size="sm"
                        onClick={handlePostComment}
                        disabled={isSubmitting}
                        className="h-8 w-8 p-0 bg-white/10 hover:bg-white/20 text-white border border-white/10 rounded-full"
                    >
                        <ArrowUp className="w-4 h-4" />
                    </Button>
                </div>
            </div>
        </Card>
    );
}
