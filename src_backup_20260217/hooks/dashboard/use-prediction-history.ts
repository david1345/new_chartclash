import { useState, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';

export function usePredictionHistory(user: any) {
    const [predictions, setPredictions] = useState<any[]>([]);
    const [isLoadingPredictions, setIsLoadingPredictions] = useState(true);
    const supabase = createClient();

    const fetchPredictions = async () => {
        if (!user) return;

        setIsLoadingPredictions(true);
        const { data } = await supabase
            .from('predictions')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', { ascending: false })
            .limit(20);

        if (data) setPredictions(data);
        setIsLoadingPredictions(false);
    };

    useEffect(() => {
        if (user) fetchPredictions();
    }, [user]);

    // Optionally listen to realtime updates here too, or relying on Page to call refetch works.
    // We'll expose refetch.

    // Also Safety Polling (sync with user stats? or independent?)
    // Independent is safer for decoupled components.
    useEffect(() => {
        if (!user) return;
        const interval = setInterval(() => {
            if (document.visibilityState === 'visible') {
                fetchPredictions();
            }
        }, 60000);
        return () => clearInterval(interval);
    }, [user]);

    return { predictions, isLoadingPredictions, fetchPredictions, setPredictions };
}
