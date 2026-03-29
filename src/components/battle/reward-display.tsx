"use client";

import { Activity, ShieldCheck } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

interface RewardDisplayProps {
    betAmount: number;
    upPercent: number;
    downPercent: number;
}

function calcPayout(betAmount: number, myPercent: number, oppositePercent: number, feeRate: number) {
    if (betAmount <= 0 || myPercent <= 0) return betAmount;
    const ratio = oppositePercent / myPercent;
    const share = betAmount * ratio;
    return betAmount + share * (1 - feeRate);
}

export function RewardDisplay({ betAmount, upPercent, downPercent }: RewardDisplayProps) {
    const upEarly = calcPayout(betAmount, upPercent, downPercent, 0.01);
    const upLate = calcPayout(betAmount, upPercent, downPercent, 0.03);
    const downEarly = calcPayout(betAmount, downPercent, upPercent, 0.01);
    const downLate = calcPayout(betAmount, downPercent, upPercent, 0.03);

    return (
        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-2 mb-1.5">
            <div className="flex justify-between items-center mb-1.5 pb-1.5 border-b border-[#1E2D45]">
                <span className="text-[10px] text-[#F5A623] font-black uppercase tracking-wider flex items-center gap-1">
                    <ShieldCheck className="w-3 h-3" /> USDT Payout Preview
                </span>
                <Popover>
                    <PopoverTrigger asChild>
                        <button className="text-[10px] text-[#00E5B4] font-bold flex items-center gap-1 hover:underline">
                            <Activity className="w-3 h-3" /> Rules
                        </button>
                    </PopoverTrigger>
                    <PopoverContent className="w-72 bg-[#0F1623] border-[#1E2D45] p-3 shadow-xl">
                        <h4 className="text-xs font-black text-white uppercase mb-2">Pari-mutuel settlement</h4>
                        <p className="text-[10px] text-[#8BA3BF] leading-relaxed mb-2">
                            Winners split the losing pool pro-rata. Early GREEN bets pay a 1% fee on winnings, later YELLOW/RED bets pay 3%.
                        </p>
                        <p className="text-[10px] text-[#5A7090] leading-relaxed">
                            If one side has no bettors or the round closes exactly flat, the round is voided and stake is refunded.
                        </p>
                    </PopoverContent>
                </Popover>
            </div>

            <div className="grid grid-cols-2 gap-2">
                <div className="bg-[#0F1A10] border border-[#00E5B4]/20 rounded-lg p-1.5 text-center">
                    <div className="text-[9px] text-[#00E5B4] font-black uppercase mb-0.5">If LONG Wins</div>
                    <div className="text-sm font-mono font-bold text-[#00E5B4]">
                        {upLate.toFixed(2)} - {upEarly.toFixed(2)}
                    </div>
                    <div className="text-[9px] text-[#5A7090]">USDT return</div>
                </div>
                <div className="bg-[#1A0F10] border border-[#FF4560]/20 rounded-lg p-1.5 text-center">
                    <div className="text-[9px] text-[#FF4560] font-black uppercase mb-0.5">If SHORT Wins</div>
                    <div className="text-sm font-mono font-bold text-[#FF4560]">
                        {downLate.toFixed(2)} - {downEarly.toFixed(2)}
                    </div>
                    <div className="text-[9px] text-[#5A7090]">USDT return</div>
                </div>
            </div>

            <div className="flex justify-between items-center mt-1.5 text-[9px] text-[#5A7090]">
                <span>Wrong side: -{betAmount} USDT</span>
                <span>Void / tie: refunded</span>
            </div>
        </div>
    );
}
