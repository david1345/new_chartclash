"use client";

import { useEffect, useState } from "react";
import { Clock } from "lucide-react";

export function LiveClock() {
    const [timeStr, setTimeStr] = useState("00:00:00");
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
        const tick = () => {
            setTimeStr(new Date().toLocaleTimeString('en-US', { hour12: false }));
        };
        tick();
        const interval = setInterval(tick, 1000);
        return () => clearInterval(interval);
    }, []);

    if (!mounted) return <span className="text-xs font-mono text-muted-foreground w-[60px] inline-block">00:00:00</span>;

    return (
        <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground/80 bg-white/5 px-2 py-1 rounded">
            <Clock className="w-3 h-3" />
            <span>{timeStr}</span>
        </div>
    );
}
