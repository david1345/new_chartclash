"use client";

import { cn } from "@/lib/utils";

interface TimeframeSelectorProps {
    selectedTimeframe: string;
    onSelect: (tf: string) => void;
}

export function TimeframeSelector({ selectedTimeframe, onSelect }: TimeframeSelectorProps) {
    const timeframes = ["1h", "4h"];

    return (
        <div className="flex flex-col gap-1.5 h-full w-full">
            <button
                onClick={() => onSelect("1h")}
                className={cn(
                    "w-full h-8 rounded-lg text-[11px] font-black transition-all uppercase flex items-center justify-center border",
                    selectedTimeframe === "1h"
                        ? "bg-[#1A2639] text-[#00E5B4] border-[#00E5B4]/30"
                        : "bg-[#0F1623] text-[#5A7090] border-[#1E2D45] hover:border-[#5A7090]"
                )}
            >
                1H
            </button>
            <button
                onClick={() => onSelect("4h")}
                className={cn(
                    "w-full flex-1 rounded-md text-[11px] font-black transition-all uppercase flex items-center justify-center border",
                    selectedTimeframe === "4h"
                        ? "bg-[#1A2639] text-[#00E5B4] border-[#00E5B4]/30"
                        : "bg-[#0F1623] text-[#5A7090] border-[#1E2D45] hover:border-[#5A7090]"
                )}
            >
                4H
            </button>
        </div>
    );
}
