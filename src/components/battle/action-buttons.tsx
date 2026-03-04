"use client";

import { cn } from "@/lib/utils";
import { ArrowUp, ArrowDown } from "lucide-react";

interface ActionButtonsProps {
    onPredict: (direction: "UP" | "DOWN") => void;
    isSubmitting: boolean;
    selectedDirection: "UP" | "DOWN" | null;
    className?: string;
}

export function ActionButtons({ onPredict, isSubmitting, selectedDirection, className }: ActionButtonsProps) {
    return (
        <div className={cn("flex gap-3", className)}>
            <button
                onClick={() => onPredict("UP")}
                disabled={isSubmitting}
                className={cn(
                    "flex-1 h-10 lg:h-12 rounded-xl font-black text-lg flex items-center justify-center gap-2 transition-all active:scale-[0.98]",
                    selectedDirection === "UP" ? "bg-[#00E5B4] text-black shadow-[0_0_20px_rgba(0,229,180,0.4)]" : "bg-[#141D2E] text-[#00E5B4] border-2 border-[#00E5B4]/30 hover:border-[#00E5B4]"
                )}
            >
                <ArrowUp strokeWidth={3} className={cn("w-5 h-5", selectedDirection === "UP" ? "text-black" : "text-[#00E5B4]")} /> UP
            </button>
            <button
                onClick={() => onPredict("DOWN")}
                disabled={isSubmitting}
                className={cn(
                    "flex-1 h-10 lg:h-12 rounded-xl font-black text-lg flex items-center justify-center gap-2 transition-all active:scale-[0.98]",
                    selectedDirection === "DOWN" ? "bg-[#FF4560] text-white shadow-[0_0_20px_rgba(255,69,96,0.4)]" : "bg-[#141D2E] text-[#FF4560] border-2 border-[#FF4560]/30 hover:border-[#FF4560]"
                )}
            >
                <ArrowDown strokeWidth={3} className={cn("w-5 h-5", selectedDirection === "DOWN" ? "text-white" : "text-[#FF4560]")} /> DOWN
            </button>
        </div>
    );
}
