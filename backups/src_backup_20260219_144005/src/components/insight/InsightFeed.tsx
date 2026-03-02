import { InsightCard, InsightCardProps } from "./InsightCard"

export function InsightFeed({ insights }: { insights: InsightCardProps[] }) {
    if (!insights || insights.length === 0) {
        return (
            <div className="text-center py-12 text-muted-foreground bg-white/5 rounded-xl border border-white/5 border-dashed">
                <p>No insights yet. Be the first to share alpha!</p>
            </div>
        )
    }

    return (
        <div className="space-y-4">
            {insights.map((item, idx) => (
                <InsightCard key={item.id || idx} {...item} />
            ))}
        </div>
    )
}
