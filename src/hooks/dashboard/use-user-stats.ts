import { useState, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import { toast } from 'sonner';

export function useUserStats(user: any) {
    const [userPoints, setUserPoints] = useState(1000);
    const [userStreak, setUserStreak] = useState(0);
    const [username, setUsername] = useState<string | null>(null);
    const [userRank, setUserRank] = useState<number | null>(null);
    const [activeCount, setActiveCount] = useState(0);
    const [isLoaded, setIsLoaded] = useState(false);
    const supabase = createClient();

    const fetchUserStats = async () => {
        if (!user || user.is_guest) {
            setIsLoaded(true);
            return;
        }

        try {
            // 1. Fetch Points, Streak & Username
            const { data, error: pError } = await supabase.from('profiles').select('points, streak, username').eq('id', user.id).single();
            if (pError) throw pError;

            if (data) {
                setUserPoints(data.points ?? 1000);
                setUserStreak(data.streak || 0);
                setUsername(data.username || null);
            }

            // 2. Fetch Rank
            const { data: rank, error: rError } = await supabase.rpc('get_user_rank', { p_user_id: user.id });
            if (rError) throw rError;
            if (rank) setUserRank(rank);

            // 3. Fetch Active Prediction Count (Excluding AI Opinions)
            const { count, error: cError } = await supabase
                .from('predictions')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', user.id)
                .eq('status', 'pending')
                .eq('is_opinion', false);

            if (!cError) setActiveCount(count || 0);

        } catch (err: any) {
            console.error('Failed to fetch user stats:', err.message);
        } finally {
            setIsLoaded(true);
        }
    };

    // Initial Load
    useEffect(() => {
        if (user) fetchUserStats();
    }, [user]);

    // Realtime Subscription (Notifications -> Refresh Stats)
    useEffect(() => {
        if (!user) return;

        const channel = supabase
            .channel('dashboard-user-stats')
            .on(
                'postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'notifications', filter: `user_id=eq.${user.id}` },
                (payload: any) => {
                    console.log("🔔 Notification received, refreshing stats...", payload);
                    fetchUserStats();

                    const newNotif = payload.new;
                    const isWin = newNotif.message?.includes('WIN');
                    const isLoss = newNotif.message?.includes('LOSS');
                    const isResolution = isWin || isLoss || newNotif.type === 'success';

                    if (isResolution) {
                        const title = isWin ? "Prediction Won! 🎉" : "Prediction Resolved";
                        toast.info(title, {
                            description: newNotif.message || "Your prediction has been resolved."
                        });
                    }
                }
            )
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, [user]);

    // Safety Polling (60s Fallback)
    useEffect(() => {
        if (!user) return;
        const interval = setInterval(() => {
            if (document.visibilityState === 'visible') {
                fetchUserStats();
            }
        }, 60000);
        return () => clearInterval(interval);
    }, [user]);

    return { userPoints, setUserPoints, userStreak, username, userRank, activeCount, fetchUserStats, isLoaded };
}
