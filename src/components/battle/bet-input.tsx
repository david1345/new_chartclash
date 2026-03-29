"use client";

import { cn } from "@/lib/utils";
import { DollarSign } from "lucide-react";

interface BetInputProps {
    amount: number;
    maxAmount: number;
    onChange: (val: number) => void;
    disabled?: boolean;
}

export function BetInput({ amount, maxAmount, onChange, disabled }: BetInputProps) {
    const maxBet = Math.max(1, Math.floor(maxAmount));
    const quickBets = [1, 5, 10, 25, 50, maxBet].filter((value, index, list) => list.indexOf(value) === index);

    return (
        <div className="flex-1 flex flex-col justify-end">
            <div className="flex items-center gap-1.5 mb-1.5 h-8">
                {/* Labels Column */}
                <div className="flex flex-col justify-center shrink-0">
                    <span className="text-[10px] text-[#5A7090] font-bold uppercase tracking-wider leading-none mb-1">Bet Amount</span>
                    <span className="text-[9px] text-[#00E5B4] font-bold leading-none">Avail: {maxAmount.toFixed(2)} USDT</span>
                </div>

                {/* Input Column */}
                <div className="relative flex-1">
                    <div className="absolute inset-y-0 left-0 pl-2.5 flex items-center pointer-events-none z-10">
                        <DollarSign className="h-4 w-4 text-[#8BA3BF]" />
                    </div>
                    <input
                        type="number"
                        min="1"
                        step="1"
                        value={amount}
                        onChange={(e) => onChange(Number(e.target.value))}
                        disabled={disabled}
                        className="w-full h-8 bg-[#0F1623] border border-[#1E2D45] rounded-lg pl-8 pr-2 py-0 text-base font-black text-white placeholder-[#5A7090] focus:outline-none focus:border-[#00E5B4] focus:ring-1 focus:ring-[#00E5B4] transition-all disabled:opacity-50 inline-flex items-center"
                        placeholder="0.00"
                    />
                </div>
            </div>

            <div className="flex gap-2">
                {quickBets.map((val) => (
                    <button
                        key={val}
                        onClick={() => onChange(val)}
                        disabled={disabled}
                        className={cn(
                            "flex-1 py-1 rounded-md text-[9px] font-bold transition-all border",
                            amount === val
                                ? "bg-[#00E5B4]/10 text-[#00E5B4] border-[#00E5B4]/30"
                                : "bg-[#0F1623] text-[#8BA3BF] border-[#1E2D45] hover:border-[#5A7090] hover:text-white"
                        )}
                    >
                        {val === maxBet ? "MAX" : `$${val}`}
                    </button>
                ))}
            </div>
        </div>
    );
}
