"use client";

import { useResolutionHeartbeat } from "@/hooks/use-resolution-heartbeat";

export function ResolutionProvider({ children }: { children: React.ReactNode }) {
    // Trigger resolution check every 30 seconds
    useResolutionHeartbeat(30000);

    return <>{children}</>;
}
