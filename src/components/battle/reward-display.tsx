"use client";

import { Sparkles, Activity } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

interface RewardDisplayProps {
    betAmount: number;
    expectedMin: number;
    expectedMax: number;
    streak: number;
}

export function RewardDisplay({ betAmount, expectedMin, expectedMax, streak }: RewardDisplayProps) {
    return (
        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-2 mb-1.5">
            <div className="flex justify-between items-center mb-1.5 pb-1.5 border-b border-[#1E2D45]">
                <span className="text-[10px] text-[#F5A623] font-black uppercase tracking-wider flex items-center gap-1">
                    <Sparkles className="w-3 h-3" /> Expected Reward
                </span>
                <Popover>
                    <PopoverTrigger asChild>
                        <button className="text-[10px] text-[#00E5B4] font-bold flex items-center gap-1 hover:underline">
                            <Activity className="w-3 h-3" /> Details
                        </button>
                    </PopoverTrigger>
                    <PopoverContent className="w-64 bg-[#0F1623] border-[#1E2D45] p-3 shadow-xl">
                        <h4 className="text-xs font-black text-white uppercase mb-2">Reward Structure</h4>
                        <p className="text-[10px] text-[#8BA3BF] leading-relaxed mb-2">
                            Rewards scale dynamically based on your accuracy, timeframe length, and the total losing pool size.
                        </p>
                        <div className="flex items-center gap-2 mb-1">
                            <span className="flex-1 text-[10px] text-[#00E5B4]">Green Zone (Early)</span>
                            <span className="text-[10px] font-bold text-white">1.0x</span>
                        </div>
                        <div className="flex items-center gap-2 mb-1">
                            <span className="flex-1 text-[10px] text-[#F5A623]">Yellow Zone (Mid)</span>
                            <span className="text-[10px] font-bold text-white">0.6x</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <span className="flex-1 text-[10px] text-[#FF4560]">Red Zone (Late)</span>
                            <span className="text-[10px] font-bold text-white">0.3x</span>
                        </div>
                    </PopoverContent>
                </Popover>
            </div>

            <div className="flex justify-between items-center">
                <span className="text-xs text-[#5A7090] font-medium">{streak} streaks</span>
                <div className="flex items-center gap-4">
                    <div className="flex flex-col items-end">
                        <span className="text-[9px] text-[#00E5B4] font-black uppercase">WIN</span>
                        <span className="text-sm font-mono font-bold text-[#00E5B4]">
                            +${expectedMin.toFixed(2)}~${expectedMax.toFixed(2)}
                        </span>
                    </div>
                    <div className="flex flex-col items-end">
                        <span className="text-[9px] text-[#FF4560] font-black uppercase">LOSS</span>
                        <span className="text-sm font-mono font-bold text-[#FF4560]">
                            -${betAmount.toFixed(2)}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    );
}
