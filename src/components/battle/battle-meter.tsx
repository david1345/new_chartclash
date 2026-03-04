export function BattleMeter({ upPercent, downPercent }: { upPercent: number; downPercent: number }) {
    return (
        <div className="bg-[#141D2E] border border-[#1E2D45] rounded-xl p-2 mb-1.5">
            <div className="flex justify-between items-center mb-1">
                <span className="text-[10px] text-[#5A7090] font-bold uppercase tracking-wider">Battle Sentiment</span>
            </div>
            <div className="flex justify-between items-end mb-1">
                <div className="text-[#00E5B4] font-black text-lg leading-none">{upPercent.toFixed(1)}% UP</div>
                <div className="text-[#FF4560] font-black text-lg leading-none">{downPercent.toFixed(1)}% DOWN</div>
            </div>
            <div className="h-2.5 w-full bg-[#1A2639] rounded-full overflow-hidden flex shadow-inner">
                <div
                    className="h-full bg-gradient-to-r from-[#00E5B4]/80 to-[#00E5B4] transition-all duration-1000"
                    style={{ width: `${upPercent}%` }}
                ></div>
                <div
                    className="h-full bg-gradient-to-l from-[#FF4560]/80 to-[#FF4560] transition-all duration-1000"
                    style={{ width: `${downPercent}%` }}
                ></div>
            </div>
        </div>
    );
}
