"use client";

import { Sparkles, Activity } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

interface RewardDisplayProps {
    betAmount: number;
    expectedMin?: number;
    expectedMax?: number;
    streak: number;
    upPercent: number;
    downPercent: number;
}

const HOUSE_FEE = 0.03; // 3% platform fee

function calcPayout(betAmount: number, myPercent: number, oppositePercent: number): string {
    if (myPercent <= 0 || oppositePercent <= 0 || betAmount <= 0) return "---";
    const ratio = oppositePercent / myPercent;
    const gross = betAmount * ratio;
    const net = betAmount + gross * (1 - HOUSE_FEE);
    return `+${net.toFixed(1)}`;
}

export function RewardDisplay({ betAmount, streak, upPercent, downPercent }: RewardDisplayProps) {
    const upPayout = calcPayout(betAmount, upPercent, downPercent);
    const downPayout = calcPayout(betAmount, downPercent, upPercent);

    return (
        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-2 mb-1.5">
            <div className="flex justify-between items-center mb-1.5 pb-1.5 border-b border-[#1E2D45]">
                <span className="text-[10px] text-[#F5A623] font-black uppercase tracking-wider flex items-center gap-1">
                    <Sparkles className="w-3 h-3" /> Payout Preview
                </span>
                <Popover>
                    <PopoverTrigger asChild>
                        <button className="text-[10px] text-[#00E5B4] font-bold flex items-center gap-1 hover:underline">
                            <Activity className="w-3 h-3" /> How?
                        </button>
                    </PopoverTrigger>
                    <PopoverContent className="w-64 bg-[#0F1623] border-[#1E2D45] p-3 shadow-xl">
                        <h4 className="text-xs font-black text-white uppercase mb-2">Pari-mutuel Pool</h4>
                        <p className="text-[10px] text-[#8BA3BF] leading-relaxed mb-2">
                            {"Losers' pool is distributed to winners proportionally. Payout changes as more bets come in. Platform fee: 3%."}
                        </p>
                        <p className="text-[10px] text-[#5A7090]">
                            Formula: Bet + (Bet ÷ WinPool) × LosePool × 97%
                        </p>
                    </PopoverContent>
                </Popover>
            </div>

            <div className="grid grid-cols-2 gap-2">
                <div className="bg-[#0F1A10] border border-[#00E5B4]/20 rounded-lg p-1.5 text-center">
                    <div className="text-[9px] text-[#00E5B4] font-black uppercase mb-0.5">If UP Wins</div>
                    <div className="text-sm font-mono font-bold text-[#00E5B4]">{upPayout}</div>
                    <div className="text-[9px] text-[#5A7090]">pts</div>
                </div>
                <div className="bg-[#1A0F10] border border-[#FF4560]/20 rounded-lg p-1.5 text-center">
                    <div className="text-[9px] text-[#FF4560] font-black uppercase mb-0.5">If DOWN Wins</div>
                    <div className="text-sm font-mono font-bold text-[#FF4560]">{downPayout}</div>
                    <div className="text-[9px] text-[#5A7090]">pts</div>
                </div>
            </div>

            <div className="flex justify-between items-center mt-1.5">
                <span className="text-[9px] text-[#5A7090]">{streak} streak bonus</span>
                <span className="text-[9px] text-[#5A7090]">Loss: -{betAmount} pts</span>
            </div>
        </div>
    );
}
