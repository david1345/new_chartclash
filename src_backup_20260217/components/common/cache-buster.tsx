'use client';

import { useEffect } from 'react';

interface CacheBusterProps {
    buildId: string;
}

/**
 * CacheBuster component detects version mismatches between the current client
 * and the server's build ID. If a mismatch is found, it triggers a forced 
 * reload to fetch the latest assets, solving the "stale UI" issue.
 */
export function CacheBuster({ buildId }: CacheBusterProps) {
    useEffect(() => {
        // Only run on client
        if (typeof window === 'undefined') return;

        const CACHE_KEY = 'chartclash_build_id';
        const RELOAD_FLAG = 'chartclash_did_reload';
        const lastBuildId = localStorage.getItem(CACHE_KEY);
        const hasRecentlyReloaded = sessionStorage.getItem(RELOAD_FLAG);

        if (lastBuildId && lastBuildId !== buildId) {
            // If we just reloaded and it still doesn't match, something is wrong
            // Stop reloading to prevent infinite loops
            if (hasRecentlyReloaded) {
                console.warn('[CacheBuster] Version mismatch persists after reload. Stopping loop.');
                return;
            }

            console.log(`[CacheBuster] New version detected: ${buildId}. Reloading...`);

            // Update storage and set session flag
            localStorage.setItem(CACHE_KEY, buildId);
            sessionStorage.setItem(RELOAD_FLAG, 'true');

            // Hard reload with a version param to force-bust CDN/Browser HTML cache
            const url = new URL(window.location.href);
            url.searchParams.set('v', buildId);
            window.location.href = url.toString();
        } else {
            // Success: Version matches or first visit
            localStorage.setItem(CACHE_KEY, buildId);
            // Clear reload flag if versions match
            sessionStorage.removeItem(RELOAD_FLAG);

            // Optional: Clean up the URL if 'v' param exists to keep it clean
            const url = new URL(window.location.href);
            if (url.searchParams.has('v')) {
                url.searchParams.delete('v');
                window.history.replaceState({}, '', url.toString());
            }
        }
    }, [buildId]);

    return null;
}
