import { useState, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import { toast } from 'sonner';

interface UseRoomFeedProps {
    assetSymbol: string;
    timeframe: string;
    currentUserId?: string;
}

export function useRoomFeed({ assetSymbol, timeframe, currentUserId }: UseRoomFeedProps) {
    const [feed, setFeed] = useState<any[]>([]);
    const supabase = createClient();

    const fetchFeed = async () => {
        const { data } = await supabase
            .from('predictions')
            .select(`
            *,
            profiles (
                username,
                tier,
                total_games,
                total_wins
            )
        `)
            .not('comment', 'is', null) // Only with comments
            .eq('asset_symbol', assetSymbol)
            .eq('is_opinion', false)
            .order('created_at', { ascending: false })
            .limit(50);

        if (data) setFeed(data);
    };

    useEffect(() => {
        // 1. Initial Load
        fetchFeed();

        // 2. Subscribe to Room
        const roomChannel = supabase
            .channel(`room-${assetSymbol}-${timeframe}`) // Added timeframe to channel for isolation
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'predictions',
                    filter: `asset_symbol=eq.${assetSymbol}`
                },
                async (payload: any) => {
                    // console.log("Realtime payload received:", payload);
                    const newPred = payload.new;

                    // If it's an update and no comment yet, or if it's missing essential data, 
                    // we still try to fetch the full record to be safe.
                    if (!newPred || (!newPred.comment && payload.old?.comment === newPred.comment)) return;

                    // Fetch full profile to ensure consistency and get the username
                    const { data, error } = await supabase
                        .from('predictions')
                        .select(`
                            *,
                            profiles (
                                username,
                                tier,
                                total_games,
                                total_wins
                            )
                        `)
                        .eq('id', newPred.id)
                        .maybeSingle();

                    if (error || !data || !data.comment || data.is_opinion) return;

                    // Only update feed and show toast logic was here
                    setFeed(prev => {
                        const index = prev.findIndex(p => p.id === data.id);
                        if (index !== -1) {
                            const newFeed = [...prev];
                            newFeed[index] = data;
                            return newFeed;
                        }
                        return [data, ...prev];
                    });
                }
            )
            .subscribe((status) => {
                if (status === 'SUBSCRIBED') {
                    // console.log("Successfully subscribed to realtime feed for", assetSymbol);
                }
            });

        return () => {
            supabase.removeChannel(roomChannel);
        };
    }, [assetSymbol, timeframe, currentUserId]);

    return { feed, setFeed, fetchFeed };
}
