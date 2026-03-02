import { useEffect, useRef } from 'react';

/**
 * useResolutionHeartbeat
 * Periodically calls the resolution API to process pending predictions.
 * This acts as a client-side cron fallback for local development and active sessions.
 */
export function useResolutionHeartbeat(intervalMs: number = 60000) {
    const isFetching = useRef(false);

    useEffect(() => {
        // Add a random jitter (0-30s) to prevent multiple tabs from hitting synchronized
        const jitter = Math.random() * 30000;

        const triggerResolution = async () => {
            // Only trigger if the tab is visible to save resources
            if (document.visibilityState !== 'visible') return;

            // In-flight Guard: Prevent overlapping requests if a previous one is still pending
            if (isFetching.current) {
                console.log("💓 Resolution Heartbeat: Skipping (previous request still pending)");
                return;
            }

            try {
                isFetching.current = true;
                const res = await fetch('/api/resolve');
                const data = await res.json();

                if (data.resolved > 0) {
                    console.log(`💓 Resolution Heartbeat: Resolved ${data.resolved} predictions.`);
                }
            } catch (error) {
                // Ignore silent errors
            } finally {
                isFetching.current = false;
            }
        };

        // Initial trigger with jitter
        const initialTimeout = setTimeout(triggerResolution, jitter);

        // Interval with consistent jittered offset
        const interval = setInterval(triggerResolution, intervalMs);

        return () => {
            clearTimeout(initialTimeout);
            clearInterval(interval);
        };
    }, [intervalMs]);
}
