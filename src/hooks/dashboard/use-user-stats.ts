import { useCallback, useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { getContractBalance } from '@/lib/contract';

export function useUserStats(user: any) {
    const [userPoints, setUserPoints] = useState(0);
    const [userStreak] = useState(0);
    const [username, setUsername] = useState<string | null>(null);
    const [userRank] = useState<number | null>(null);
    const [activeCount, setActiveCount] = useState(0);
    const [isLoaded, setIsLoaded] = useState(false);
    const supabase = createClient();

    const fetchWalletBalance = useCallback(async () => {
        if (typeof window === 'undefined' || !window.ethereum) {
            setUserPoints(0);
            return;
        }

        try {
            const accounts = await window.ethereum.request({ method: 'eth_accounts' }) as string[];
            if (!accounts[0]) {
                setUserPoints(0);
                return;
            }

            const balance = await getContractBalance(accounts[0]);
            setUserPoints(balance);
        } catch (error) {
            console.error('Failed to fetch wallet balance:', error);
            setUserPoints(0);
        }
    }, []);

    const fetchUserStats = useCallback(async () => {
        if (!user) {
            setUsername(null);
            setActiveCount(0);
            setUserPoints(0);
            setIsLoaded(true);
            return;
        }

        try {
            const [{ data: profile }, { count }] = await Promise.all([
                supabase
                    .from('profiles')
                    .select('username')
                    .eq('id', user.id)
                    .maybeSingle(),
                supabase
                    .from('predictions')
                    .select('*', { count: 'exact', head: true })
                    .eq('user_id', user.id)
                    .eq('status', 'pending')
            ]);

            setUsername(profile?.username || null);
            setActiveCount(count || 0);
            await fetchWalletBalance();
        } catch (err: any) {
            console.error('Failed to fetch user stats:', err.message);
        } finally {
            setIsLoaded(true);
        }
    }, [fetchWalletBalance, supabase, user]);

    useEffect(() => {
        fetchUserStats();
    }, [fetchUserStats]);

    useEffect(() => {
        if (typeof window === 'undefined' || !window.ethereum) return;

        const handleAccountsChanged = () => {
            fetchUserStats();
        };

        window.ethereum.on?.('accountsChanged', handleAccountsChanged);
        return () => {
            window.ethereum.removeListener?.('accountsChanged', handleAccountsChanged);
        };
    }, [fetchUserStats]);

    useEffect(() => {
        if (!user) return;
        const interval = setInterval(() => {
            if (document.visibilityState === 'visible') {
                fetchUserStats();
            }
        }, 30000);

        return () => clearInterval(interval);
    }, [fetchUserStats, user]);

    return { userPoints, setUserPoints, userStreak, username, userRank, activeCount, fetchUserStats, isLoaded };
}
