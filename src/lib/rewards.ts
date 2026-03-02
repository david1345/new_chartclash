
export const calculatePotentialWin = (
    timeframe: string,
    betAmount: number,
    streak: number,
    targetPercent: number,
    candleElapsed: number | null
) => {
    let tfMult = 1.0;
    if (timeframe === '30m') tfMult = 1.2;
    else if (timeframe === '1h') tfMult = 1.5;
    else if (timeframe === '4h') tfMult = 2.2;
    else if (timeframe === '1d') tfMult = 3.0;

    let targetBonus = 0;
    // Only apply target bonus if target is strictly positive
    if (targetPercent > 0) {
        if (targetPercent <= 0.5) targetBonus = 8;
        else if (targetPercent <= 1.0) targetBonus = 16;
        else if (targetPercent <= 1.5) targetBonus = 24;
        else targetBonus = 32;
    }

    let lateMult = 1.0;
    let isStreakIncrementable = true;

    if (candleElapsed !== null) {
        let tfSeconds = 900;
        if (timeframe === '1m') tfSeconds = 60;
        else if (timeframe === '5m') tfSeconds = 300;
        else if (timeframe === '15m') tfSeconds = 900;
        else if (timeframe === '30m') tfSeconds = 1800;
        else if (timeframe.includes('h')) tfSeconds = parseInt(timeframe) * 3600;
        else if (timeframe.includes('d')) tfSeconds = 86400;

        const ratio = candleElapsed / tfSeconds;
        if (ratio < 0.33) {
            lateMult = 1.0;
            isStreakIncrementable = true;
        } else if (ratio < 0.66) {
            lateMult = 0.6;
            isStreakIncrementable = false;
        } else if (ratio < 0.90) {
            lateMult = 0.3;
            isStreakIncrementable = false;
        } else {
            lateMult = 0; // Locked 90%+
        }
    }

    // Handle streak calculation logic if needed, but for simple display:
    // We assume the passed 'streak' is the current streak.
    // The logic for next streak bonus application is a bit complex in local state,
    // but for pure potential win calculation, we can simplify or require explicit next streak.

    // To match exact logic from page.tsx:
    // const nextStreakCount = (isStreakIncrementable && streakOverride === undefined && target > 0) ? currentStreakCount + 1 : currentStreakCount;
    // We will assume 'streak' argument IS the calculated/effective streak to use.

    let streakBonusBase = 0;

    // Note: usage in page.tsx was doing some complex nextStreak logic.
    // For the extracted function, we might just calculate the bonus for a GIVEN streak level.
    // Let's replicate strict logic if we can, or simplify for 'potential' display.

    // Replicating page.tsx logic exactly requires knowing if we are simulating "next win"
    // Let's assume the caller passes the *projected* streak if they want that.

    if (streak >= 2) {
        streakBonusBase += 3;
    }

    // Milestone Bonus (applied if we just hit it) - this is state dependent (did we just cross it?).
    // For "Potential Win" display, we usually show what you get IF you win.
    // The page.tsx logic:
    // if (nextStreakCount > currentStreakCount) ...

    // Let's assume the caller handles the "nextStreak" determination and passes it here.
    // Actually, extracting this perfectly generic is hard without passing "isNextStreak".
    // Let's pass `isNextStreak: boolean`

    // Wait, looking at page.tsx again: 
    // calculatePotentialWin(undefined, 0) called with undefined streakOverride -> uses userStreak
    // It calculates `nextStreakCount`.

    return {
        tfMult,
        lateMult,
        targetBonus,
        // We will return a builder function or just the logic
    };
};

export const getZoneInfo = (
    timeframe: string,
    createdAtISO: string,
    closedAtISO: string
) => {
    let tfSeconds = 900;
    if (timeframe === '1m') tfSeconds = 60;
    else if (timeframe === '5m') tfSeconds = 300;
    else if (timeframe === '15m') tfSeconds = 900;
    else if (timeframe === '30m') tfSeconds = 1800;
    else if (timeframe.includes('h')) tfSeconds = parseInt(timeframe) * 3600;
    else if (timeframe.includes('d')) tfSeconds = 86400;

    const created = new Date(createdAtISO).getTime() / 1000;
    const closed = new Date(closedAtISO).getTime() / 1000;
    // logic from page.tsx: const ratio = (created - (closed - tfSeconds)) / tfSeconds;
    const ratio = (created - (closed - tfSeconds)) / tfSeconds;

    if (ratio < 0.33) return { label: "GREEN", color: "text-emerald-400", border: "border-emerald-500/50", bg: "bg-emerald-500/5" };
    if (ratio < 0.66) return { label: "YELLOW", color: "text-amber-400", border: "border-amber-500/50", bg: "bg-amber-500/5" };
    return { label: "RED", color: "text-rose-400", border: "border-rose-500/50", bg: "bg-rose-500/5" };
};

// We will refine `calculatePotentialWin` to be a pure function that can be used easily.
// Ideally usage: calculateReward(bet, target, streak, timeframe, elapsed)

export const calculateReward = (
    betAmount: number,
    targetPercent: number,
    userStreak: number,
    timeframe: string,
    candleElapsed: number | null = null,
    isProjectingWin: boolean = true // if true, calculates for next win
): number => {
    let tfMult = 1.0;
    if (timeframe === '30m') tfMult = 1.2;
    else if (timeframe === '1h') tfMult = 1.5;
    else if (timeframe === '4h') tfMult = 2.2;
    else if (timeframe === '1d') tfMult = 3.0;

    let targetBonus = 0;
    if (targetPercent > 0) {
        if (targetPercent <= 0.5) targetBonus = 8;
        else if (targetPercent <= 1.0) targetBonus = 16;
        else if (targetPercent <= 1.5) targetBonus = 24;
        else targetBonus = 32;
    }

    let lateMult = 1.0;
    let isStreakIncrementable = true;

    if (candleElapsed !== null) {
        let tfSeconds = 900;
        if (timeframe === '1m') tfSeconds = 60;
        else if (timeframe === '5m') tfSeconds = 300;
        else if (timeframe === '15m') tfSeconds = 900;
        else if (timeframe === '30m') tfSeconds = 1800;
        else if (timeframe.includes('h')) tfSeconds = parseInt(timeframe) * 3600;
        else if (timeframe.includes('d')) tfSeconds = 86400;

        const ratio = candleElapsed / tfSeconds;
        if (ratio < 0.33) {
            lateMult = 1.0;
            isStreakIncrementable = true;
        } else if (ratio < 0.66) {
            lateMult = 0.6;
            isStreakIncrementable = false;
        } else if (ratio < 0.90) {
            lateMult = 0.3;
            isStreakIncrementable = false;
        } else {
            lateMult = 0;
        }
    }

    const nextStreakCount = (isProjectingWin && isStreakIncrementable && targetPercent > 0)
        ? userStreak + 1
        : userStreak;

    let streakBonusBase = 0;
    if (nextStreakCount >= 2) {
        streakBonusBase += 3;
    }

    // Milestone Bonus
    // Warning: strictly speaking, milestone is only added IF we crossed it. 
    // If we are already at 10, we don't get 10's bonus again? 
    // The original logic: if (nextStreakCount > currentStreakCount) checks if we incremented.
    // And checks exact match.
    if (nextStreakCount > userStreak) {
        if (nextStreakCount === 3) streakBonusBase += 20;
        else if (nextStreakCount === 5) streakBonusBase += 50;
        else if (nextStreakCount === 7) streakBonusBase += 100;
        else if (nextStreakCount === 10) streakBonusBase += 200;
        else if (nextStreakCount === 15) streakBonusBase += 500;
    }

    const baseProfit = (betAmount * 0.8 + targetBonus + streakBonusBase) * tfMult * lateMult;
    const finalProfit = baseProfit * 0.995;
    return Math.round(finalProfit);
}
