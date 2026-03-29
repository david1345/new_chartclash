export default function TermsOfServicePage() {
    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            <h1 className="text-3xl font-bold mb-6">Terms of Service</h1>

            <div className="space-y-6 text-gray-300">
                <Section title="1. Service Overview">
                    <p>ChartClash provides real-money market participation features where users may deposit supported USDT, place on-chain long or short bets, and view mirrored position history inside the app.</p>
                    <p>Availability may depend on jurisdiction, compliance requirements, and future product policy. Access to certain features may be restricted or suspended at any time.</p>
                </Section>

                <Section title="2. Wallets, Deposits, and Withdrawals">
                    <p>Users are responsible for securing their wallet, seed phrase, and signing environment.</p>
                    <p>Only supported networks and assets may be used for deposits. Sending unsupported assets or using the wrong network may result in permanent loss.</p>
                    <p>Withdrawals, fees, and on-chain processing are governed by the deployed contract and current platform rules.</p>
                </Section>

                <Section title="3. Betting Risks">
                    <p>All bets involve risk of loss. Users may lose some or all of the stake committed to a round.</p>
                    <p>Payouts are not guaranteed and depend on round outcome, pool composition, fees, and settlement rules.</p>
                    <p>Nothing on the Service constitutes financial, investment, legal, or tax advice.</p>
                </Section>

                <Section title="4. Market Rules & Resolution">
                    <p>Each market is governed by predefined rules, timing, and resolution sources selected by the Service.</p>
                    <p>The Company is not responsible for delays, interruptions, or inaccuracies caused by third-party market data providers, wallets, RPC providers, or blockchain infrastructure.</p>
                    <p>Rounds may be voided or refunded according to the applicable market rules or contract behavior.</p>
                </Section>

                <Section title="5. User Responsibilities">
                    <p>Users agree not to:</p>
                    <ul className="list-disc pl-5 space-y-1">
                        <li>Exploit system vulnerabilities or timing gaps</li>
                        <li>Create multiple accounts for unfair advantage</li>
                        <li>Use bots, scripts, or automation tools</li>
                        <li>Harass, threaten, or post hateful content</li>
                        <li>Misrepresent identity, ownership, or market activity</li>
                        <li>Attempt to manipulate market outcomes or platform operations</li>
                    </ul>
                </Section>

                <Section title="6. Compliance & Restrictions">
                    <p>The Company may request additional verification, restrict features, or deny access where legally required.</p>
                    <p>Users are responsible for ensuring that use of the Service is lawful in their jurisdiction.</p>
                </Section>

                <Section title="7. Service Modifications">
                    <p>The Company may change, suspend, or discontinue any part of the Service at any time, including features, fee schedules, access rules, settlement flows, or reward programs.</p>
                </Section>

                <Section title="8. Account Termination">
                    <p>The Company may suspend or terminate accounts that violate these Terms, applicable law, or platform safety policies.</p>
                </Section>

                <Section title="9. Limitation of Liability">
                    <p>The Service is provided "as is" without warranties of any kind. The Company is not liable for trading losses, wallet compromise, data feed issues, network congestion, smart contract risk, or use of third-party infrastructure.</p>
                </Section>

                <Section title="10. Changes to Terms">
                    <p>We may update these Terms periodically. Continued use of the Service constitutes acceptance of any revised Terms.</p>
                </Section>
            </div>
        </div>
    );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
    return (
        <section>
            <h2 className="text-xl font-semibold text-white mb-2">{title}</h2>
            <div className="space-y-2 leading-relaxed pl-6 border-l-2 border-white/10 ml-1">{children}</div>
        </section>
    );
}
