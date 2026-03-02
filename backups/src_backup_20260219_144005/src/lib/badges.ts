export function getBadge(winRate: number, rank?: number) {
    // Rank based logic (if we had global rank context)
    if (rank && rank <= 10) return "🔥 CLASH LEGEND"

    // Winrate based logic
    if (winRate >= 72) return "🟡 MARKET MASTER"
    if (winRate >= 65) return "🟣 PRO TRADER"
    if (winRate >= 55) return "🔵 SKILLED"

    return "⚪ NOVICE"
}
