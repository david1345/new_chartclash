export default function TermsOfServicePage() {
    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            <h1 className="text-3xl font-bold mb-6">Terms of Service</h1>

            <div className="space-y-6 text-gray-300">
                <Section title="1. Service Overview">
                    <p>This platform provides a virtual prediction game where users forecast financial market movements using virtual points.</p>
                    <p>The Service does not provide real-money gambling, betting, financial investment, or financial advisory services.</p>
                </Section>

                <Section title="2. Virtual Points System">
                    <p>All points used in the Service are virtual rewards with no monetary value.</p>
                    <p>Points cannot be exchanged for cash, cryptocurrency, goods, or legal tender.</p>
                    <p>Points are used solely for in-platform rankings, seasonal rewards, and achievement systems.</p>
                    <p>The Company reserves the right to modify point values, earning rates, and deduction rules at any time.</p>
                </Section>

                <Section title="3. User Responsibilities">
                    <p>Users agree not to:</p>
                    <ul className="list-disc pl-5 space-y-1">
                        <li>Exploit system vulnerabilities</li>
                        <li>Create multiple accounts for unfair advantage</li>
                        <li>Use bots, scripts, or automation tools</li>
                        <li>Harass, threaten, or post hateful content</li>
                        <li>Spread false or misleading information</li>
                        <li>Attempt to manipulate rankings or game outcomes</li>
                    </ul>
                    <p className="mt-2">Violation of these rules may result in account suspension or permanent termination without prior notice.</p>
                </Section>

                <Section title="4. Prediction Results & Market Data">
                    <p>Prediction outcomes are determined automatically based on predefined rules and data sources selected by the Service.</p>
                    <p>The Company is not responsible for inaccuracies, delays, or interruptions in market data caused by third-party providers or technical issues.</p>
                </Section>

                <Section title="5. Service Modifications">
                    <p>The Company may change, suspend, or discontinue any part of the Service at any time, including features, seasons, scoring systems, or reward structures.</p>
                </Section>

                <Section title="6. No Financial Advice">
                    <p>All content, data, and predictions within the Service are for entertainment and educational purposes only.</p>
                    <p>Nothing on the platform constitutes financial, investment, or trading advice.</p>
                </Section>

                <Section title="7. Account Termination">
                    <p>The Company may suspend or terminate accounts that violate these Terms or engage in behavior that harms the platform or other users.</p>
                </Section>

                <Section title="8. Limitation of Liability">
                    <p>The Service is provided "as is" without warranties of any kind. The Company is not liable for losses, damages, or disruptions arising from use of the Service.</p>
                </Section>

                <Section title="9. Changes to Terms">
                    <p>We may update these Terms periodically. Continued use of the Service constitutes acceptance of any revised Terms.</p>
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
