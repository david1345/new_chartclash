export default function PrivacyPolicyPage() {
    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            <h1 className="text-3xl font-bold mb-6 flex items-center gap-2">
                <span>🔒</span> Privacy Policy
            </h1>

            <div className="space-y-6 text-gray-300">
                <Section title="1. Information We Collect">
                    <p>We may collect:</p>
                    <ul className="list-disc pl-5 space-y-1">
                        <li>Email address and authentication data</li>
                        <li>Username and profile information</li>
                        <li>Prediction activity and gameplay data</li>
                        <li>Device and browser information</li>
                        <li>Usage analytics and interaction data</li>
                    </ul>
                </Section>

                <Section title="2. How We Use Information">
                    <p>We use collected data to:</p>
                    <ul className="list-disc pl-5 space-y-1">
                        <li>Provide and improve the Service</li>
                        <li>Manage accounts and authentication</li>
                        <li>Calculate rankings and rewards</li>
                        <li>Prevent abuse and fraudulent activity</li>
                        <li>Analyze usage patterns</li>
                    </ul>
                </Section>

                <Section title="3. Data Sharing">
                    <p>We do not sell user data.</p>
                    <p>We may share data with trusted service providers (hosting, analytics, authentication) strictly to operate the platform.</p>
                </Section>

                <Section title="4. Data Security">
                    <p>We implement reasonable technical and organizational safeguards to protect user data, but no system is completely secure.</p>
                </Section>

                <Section title="5. Data Retention">
                    <p>We retain user data only as long as necessary to operate the Service or comply with legal obligations.</p>
                </Section>

                <Section title="6. User Rights">
                    <p>Users may request access, correction, or deletion of their personal data by contacting support.</p>
                </Section>

                <Section title="7. Cookies & Tracking">
                    <p>We may use cookies or similar technologies to improve user experience and analyze platform usage.</p>
                </Section>

                <Section title="8. Policy Updates">
                    <p>We may update this Privacy Policy periodically. Continued use of the Service indicates acceptance of changes.</p>
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
