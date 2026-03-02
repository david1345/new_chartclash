export default function FairPlayPage() {
    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            <h1 className="text-3xl font-bold mb-6 flex items-center gap-2">
                <span>⚖️</span> Fair Play & Integrity Policy
            </h1>

            <div className="space-y-6 text-gray-300">
                <Section title="1. Equal Competition">
                    <p>All users compete under the same scoring and reward rules. No user receives preferential treatment.</p>
                </Section>

                <Section title="2. Anti-Cheating Measures">
                    <p>We monitor for:</p>
                    <ul className="list-disc pl-5 space-y-1">
                        <li>Multi-account abuse</li>
                        <li>Automated prediction scripts</li>
                        <li>Exploiting bugs or loopholes</li>
                        <li>Coordinated manipulation attempts</li>
                    </ul>
                    <p className="mt-2 text-yellow-500/80">Accounts found violating fair play may be reset, suspended, or permanently banned.</p>
                </Section>

                <Section title="3. Ranking Integrity">
                    <p>Leaderboard rankings are calculated automatically using transparent internal scoring formulas. Manual manipulation by staff is prohibited except to correct verified system errors.</p>
                </Section>

                <Section title="4. Season Resets">
                    <p>At the end of each season:</p>
                    <ul className="list-disc pl-5 space-y-1">
                        <li>Rankings may reset</li>
                        <li>Points may partially or fully reset</li>
                        <li>Rewards are distributed based on final standings</li>
                    </ul>
                </Section>

                <Section title="5. Dispute Resolution">
                    <p>If a user believes a scoring error occurred, they may submit a support request. The Company reserves final authority on all game-related decisions.</p>
                </Section>
            </div>
        </div>
    );
}

function Section({ title, children }: { title: string, children: React.ReactNode }) {
    return (
        <section>
            <h2 className="text-xl font-semibold text-white mb-2">{title}</h2>
            <div className="space-y-2 leading-relaxed pl-6 border-l-2 border-white/10 ml-1">
                {children}
            </div>
        </section>
    );
}
