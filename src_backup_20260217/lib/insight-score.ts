export function calculateInsightScore({
    result,
    targetPercent,
    likes,
    comments,
    userWinRate,
    createdAt,
    status
}: {
    result?: "WIN" | "LOSS" | string
    status?: string
    targetPercent: number
    likes: number
    comments: number
    userWinRate: number
    createdAt: string
}) {
    const isWin = result === "WIN" || status === "WIN";
    const hoursOld = (Date.now() - new Date(createdAt).getTime()) / 36e5

    // Ensure non-negative score generally, though formula allows negative
    const score = (
        (isWin ? 40 : 0) +
        (targetPercent * 15) +
        (likes * 2) +
        (comments * 3) +
        (userWinRate * 0.2) -
        (hoursOld * 1.5)
    )

    return Number(score.toFixed(1));
}
