"use client";

import Link from "next/link";
import { useState } from "react";
import { FeedbackDialog } from "@/components/support/feedback-dialog";

export function Footer() {
    const [feedbackOpen, setFeedbackOpen] = useState(false);

    return (
        <footer className="w-full border-t border-white/5 bg-[#050505]/80 backdrop-blur-sm py-6 mt-auto">
            <FeedbackDialog open={feedbackOpen} onOpenChange={setFeedbackOpen} />
            <div className="container mx-auto px-4 text-center space-y-3">

                {/* Line 1: Links */}
                <div className="flex flex-wrap justify-center gap-2 text-xs text-muted-foreground uppercase tracking-wider font-medium">
                    <Link href="/legal/terms" className="hover:text-primary transition-colors">Terms</Link>
                    <span className="text-white/10">•</span>
                    <Link href="/legal/privacy" className="hover:text-primary transition-colors">Privacy</Link>
                    <span className="text-white/10">•</span>
                    <Link href="/legal/fair-play" className="hover:text-primary transition-colors">Fair Play</Link>
                    <span className="text-white/10">•</span>
                    <Link href="/legal/anti-abuse" className="hover:text-primary transition-colors">Anti-Abuse</Link>
                    <span className="text-white/10">•</span>
                    <Link href="/legal/cookies" className="hover:text-primary transition-colors">Cookies</Link>
                    <span className="text-white/10">•</span>
                    <button
                        onClick={() => setFeedbackOpen(true)}
                        className="hover:text-primary transition-colors uppercase"
                    >
                        Support
                    </button>
                </div>

                {/* Line 2: Warnings */}
                <div className="text-xs font-bold text-amber-500/80">
                    ⚠️ Entertainment Only • No Financial Advice • 18+ Only
                </div>

                {/* Line 3: Copyright */}
                <div className="text-[10px] text-white/20">
                    © 2026 ChartClash • All rights reserved
                </div>

            </div>
        </footer>
    );
}
