export default function AntiAbusePolicyPage() {
    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            <h1 className="text-3xl font-bold mb-6 flex items-center gap-2">
                <span>🚫</span> Anti-Abuse Policy
            </h1>
            <p className="text-gray-400 mb-8 pl-1">
                To maintain a fair and competitive environment, ChartClash actively monitors for exploitative behavior.
            </p>

            <div className="space-y-8 text-gray-300">
                <Section title="🚫 Prohibited Activities">
                    <p>The following actions are strictly forbidden:</p>
                    <ul className="list-disc pl-5 space-y-1 mt-2">
                        <li>Use of bots, automation tools, or scripts</li>
                        <li>Creating or operating multiple accounts</li>
                        <li>Coordinated manipulation of prediction outcomes</li>
                        <li>Exploiting bugs, latency, or system delays</li>
                        <li>Reverse engineering settlement or fee logic</li>
                        <li>Artificially inflating engagement, volume, or reported performance</li>
                    </ul>
                </Section>

                <Section title="🔍 Detection Methods">
                    <p>We use automated systems to identify suspicious behavior, including:</p>
                    <ul className="list-disc pl-5 space-y-1 mt-2">
                        <li>Device fingerprinting</li>
                        <li>Behavioral pattern analysis</li>
                        <li>IP and network anomaly detection</li>
                        <li>Statistical outlier detection in win rates, timing, and wallet activity</li>
                    </ul>
                    <p className="mt-2 text-sm text-gray-500 italic">Detection methods are confidential and continuously updated.</p>
                </Section>

                <Section title="⚖️ Enforcement Actions">
                    <p>If abuse is detected, we may apply one or more of the following actions:</p>
                    <ul className="list-disc pl-5 space-y-1 mt-2">
                        <li>Removal or freezing of abusive positions where allowed</li>
                        <li>Leaderboard disqualification</li>
                        <li>Temporary suspension</li>
                        <li>Permanent account ban</li>
                        <li>Restriction of deposits, withdrawals, or market access</li>
                    </ul>
                    <p className="mt-2 text-yellow-500/80">These actions may be applied without prior notice.</p>
                </Section>

                <Section title="📌 Final Authority">
                    <p>ChartClash reserves the right to make final decisions regarding abuse, exploits, and unfair advantage. All rulings are made to preserve fair competition.</p>
                </Section>
            </div>
        </div>
    );
}

function Section({ title, children }: { title: string, children: React.ReactNode }) {
    return (
        <section>
            <h2 className="text-xl font-semibold text-white mb-2">{title}</h2>
            {/* Indentation applied here as requested */}
            <div className="space-y-2 leading-relaxed pl-6 border-l-2 border-white/10 ml-1">
                {children}
            </div>
        </section>
    );
}
