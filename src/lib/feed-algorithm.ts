export type Tier = "bronze" | "silver" | "gold" | "platinum" | "master" | "legend" | "Unranked"; // Added Unranked for compatibility

export type RiskLevel = "low" | "mid" | "high";

export interface AuthorStats {
    tier: Tier
    assetAccuracy: number // 0 ~ 1 (e.g. 0.63 = 63%)
}

export interface PostEngagement {
    likes: number
    bookmarks: number
    comments: number
    shares: number
    likedByHighTier: number // Count of interactions from high-tier users
}

export interface PostMeta {
    createdAt: Date
    volatilityTarget: number // e.g. 0.5, 1, 2 (%)
}

export interface FollowContext {
    followsAuthor: boolean
    followsAsset: boolean
    followsTimeframe: boolean
    followsRisk: boolean
}

export interface FeedPost {
    author: AuthorStats
    engagement: PostEngagement
    meta: PostMeta
}

// 🧠 Score Calculation (Hybrid Architecture)

/**
 * 1. Base Score (Server/DB Side)
 * - Score to be stored in DB. Includes objective metrics only, excluding personalized factors (Follow).
 * - Recomputed and updated in DB whenever engagement (likes, comments, etc.) changes.
 */
export function calculateBaseScore(
    post: FeedPost,
    now: Date = new Date()
): number {
    const authorScore = getAuthorTierScore(post.author.tier)
    const accuracyScore = getAccuracyScore(post.author.assetAccuracy)
    const riskScore = getRiskDifficultyScore(post.meta.volatilityTarget)
    const engagementScore = getEngagementScore(post.engagement)
    const freshnessScore = getFreshnessScore(post.meta.createdAt, now)

    const total =
        authorScore * 0.35 +
        accuracyScore * 0.2 +
        riskScore * 0.15 +
        engagementScore * 0.15 +
        freshnessScore * 0.15

    return Math.round(total)
}

/**
 * Legacy wrapper for compatibility
 */
export function calculatePostScore(
    post: FeedPost,
    follow: FollowContext,
    now: Date = new Date()
): number {
    return calculateBaseScore(post, now) + getFollowBonus(follow);
}

// 1️⃣ Author Tier Score
function getAuthorTierScore(tier: Tier): number {
    const map: Record<Tier, number> = {
        Unranked: 0,
        bronze: 20,
        silver: 40,
        gold: 60,
        platinum: 75,
        master: 90,
        legend: 100,
    }
    return map[tier] || 20; // Default to bronze if unknown
}

// 2️⃣ Asset Accuracy Score
function getAccuracyScore(accuracy: number): number {
    if (accuracy >= 0.7) return 100
    if (accuracy >= 0.65) return 80
    if (accuracy >= 0.6) return 60
    if (accuracy >= 0.55) return 40
    return 20
}

// 3️⃣ Risk Difficulty Score
function getRiskDifficultyScore(volatility: number): number {
    if (volatility >= 3) return 100
    if (volatility >= 2) return 85
    if (volatility >= 1) return 60
    return 30
}

// 4️⃣ Engagement Score (includes high-tier weighting)
function getEngagementScore(e: PostEngagement): number {
    const base =
        e.likes * 1 +
        e.comments * 2 +
        e.bookmarks * 3 +
        e.shares * 4

    const highTierBoost = e.likedByHighTier * 5

    const raw = base + highTierBoost

    // Cap at 100 to prevent viral spikes
    return Math.min(100, raw)
}

// 5️⃣ Freshness Score
function getFreshnessScore(createdAt: Date, now: Date): number {
    const hours = (now.getTime() - createdAt.getTime()) / (1000 * 60 * 60)

    if (hours <= 1) return 100
    if (hours <= 6) return 80
    if (hours <= 12) return 60
    if (hours <= 24) return 40
    return 20
}

// 6️⃣ Follow Bonus (Client Side)
export function getFollowBonus(follow: FollowContext): number {
    let bonus = 0
    if (follow.followsAuthor) bonus += 15
    if (follow.followsAsset) bonus += 10
    if (follow.followsTimeframe) bonus += 8
    if (follow.followsRisk) bonus += 5
    return bonus
}
