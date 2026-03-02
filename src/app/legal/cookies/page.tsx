export default function CookiePolicy() {
    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl text-gray-300 space-y-8">
            <div className="space-y-4">
                <h1 className="text-3xl font-bold text-white">Cookie Policy</h1>
                <p className="text-sm text-muted-foreground">Last updated: {new Date().toLocaleDateString()}</p>
            </div>

            <section className="space-y-4">
                <h2 className="text-xl font-semibold text-white">1. What Are Cookies</h2>
                <p>
                    Cookies are small text files that are placed on your computer or mobile device when you visit a website.
                    We use them to ensure our website functions correctly, to understand how you use our content, and to improve your experience.
                </p>
            </section>

            <section className="space-y-4">
                <h2 className="text-xl font-semibold text-white">2. How We Use Cookies</h2>
                <ul className="list-disc pl-5 space-y-2">
                    <li>To recognize you when you sign in (Authentication).</li>
                    <li>To remember your preferences and settings.</li>
                    <li>To improve the speed and security of the site.</li>
                    <li>To allow you to share pages with social networks like Facebook or Twitter.</li>
                </ul>
            </section>

            <section className="space-y-4">
                <h2 className="text-xl font-semibold text-white">3. Types of Cookies We Use</h2>
                <div className="space-y-2">
                    <h3 className="text-white font-medium">Essential Cookies</h3>
                    <p>These are necessary for the website to function. They include cookies that enable you to log into secure areas of our website.</p>

                    <h3 className="text-white font-medium mt-4">Analytical/Performance Cookies</h3>
                    <p>These allow us to recognize and count the number of visitors and to see how visitors move around our website when they are using it.</p>
                </div>
            </section>

            <section className="space-y-4">
                <h2 className="text-xl font-semibold text-white">4. Managing Cookies</h2>
                <p>
                    Most web browsers allow some control of most cookies through the browser settings.
                    To find out more about cookies, including how to see what cookies have been set, visit <a href="https://www.aboutcookies.org" className="text-primary hover:underline">www.aboutcookies.org</a> or <a href="https://www.allaboutcookies.org" className="text-primary hover:underline">www.allaboutcookies.org</a>.
                </p>
            </section>
        </div>
    )
}
