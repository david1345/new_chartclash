"use client";

import { useState } from "react";

import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Mail, HelpCircle, MessageSquare, Target, Calculator, Trophy, Lock, Settings, Info, Home, Plus, Minus } from "lucide-react";
import Link from "next/link";
import { motion } from "framer-motion";

export default function HelpPage() {
    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            {/* Header */}
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <HelpCircle className="w-5 h-5 text-muted-foreground" /> HELP / FAQ
                    </h1>
                    <div className="ml-auto">
                        <Link href="/">
                            <Button variant="ghost" size="sm" className="gap-2 text-muted-foreground hover:text-white">
                                <Home className="w-4 h-4" />
                                <span className="hidden sm:inline">Home</span>
                            </Button>
                        </Link>
                    </div>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-8 max-w-3xl pb-20">

                <FaqSection title="General" icon={Info}>
                    <FaqItem q="1. How do I get points?" a="All new users receive base points upon sign-up. You can earn more points by making successful predictions." />
                    <FaqItem q="2. Is this real money?" a="No. This service is a point-based prediction game platform with no real money transactions." />
                    <FaqItem q="3. What happens if I lose all points?" a="Even if you lose all points, you can receive base points again to try again if you meet certain conditions." />
                    <FaqItem q="4. Can I change my username?" a="You can change it in Settings. There may be a limit on how often you can change it within a certain period." />
                </FaqSection>

                <FaqSection title="Prediction System" icon={Target}>
                    <FaqItem q="5. How does prediction work?" a="Users select a specific asset and timeframe, then predict whether the price will rise or fall and the target fluctuation rate." />
                    <FaqItem q="6. What timeframes are available?" a="Various timeframes are provided, from short-term (e.g., 15 minutes) to medium and long-term (e.g., 1 day)." />
                    <FaqItem q="7. Does a longer timeframe give higher rewards?" a="Yes. Since the prediction difficulty increases, higher rewards are given for longer timeframes." />
                    <FaqItem q="8. What is target percentage?" a="It is the target range of fluctuation you predict the price will move by. Predicting a larger fluctuation rate yields larger rewards." />
                    <FaqItem q="9. When is a prediction considered successful?" a="It is considered successful if the predicted direction and target conditions are met within the selected time." />
                    <FaqItem q="10. Can I cancel a prediction after placing it?" a="No. Predictions cannot be changed or canceled after submission." />
                </FaqSection>

                <FaqSection title="Points & Rewards" icon={Calculator}>
                    <FaqItem q="11. How are rewards calculated?" a="Rewards are calculated based on an internal formula that combines timeframe length, target fluctuation rate, and difficulty." />
                    <FaqItem q="12. Do I lose all points if my prediction fails?" a="No. Only the points used for the prediction are deducted." />
                    <FaqItem q="13. Is there a maximum reward?" a="To ensure system stability and balance, the maximum reward per prediction may be limited." />
                    <FaqItem q="14. Do rewards change over time?" a="Yes. The reward structure may be adjusted for game balance." />
                </FaqSection>

                <FaqSection title="Ranking & Competition" icon={Trophy}>
                    <FaqItem q="15. How does the leaderboard work?" a="Rankings are calculated based on points held, prediction success rate, activity history, etc." />
                    <FaqItem q="16. What is a season?" a="A season is a competitive period for a set duration. Top users may receive special rewards at the end of the season." />
                    <FaqItem q="17. Do inactive users lose rank?" a="If there is no activity, your rank may drop as other users overtake you." />
                </FaqSection>

                <FaqSection title="Community & Comments" icon={MessageSquare}>
                    <FaqItem q="18. Who can see my reasoning comment?" a="It is only displayed to users who participated in that prediction game." />
                    <FaqItem q="19. Can I edit or delete my comment?" a="Editing may be possible within a certain time, but it may be restricted afterwards for record keeping." />
                    <FaqItem q="20. What kind of comments are allowed?" a="Only content related to predictions, such as market analysis, technical rationale, and news interpretation, is allowed." />
                    <FaqItem q="21. Are there penalties for spam or abuse?" a="Yes. Inappropriate content may result in comment restrictions or account sanctions." />
                </FaqSection>

                <FaqSection title="Fairness & Data" icon={Lock}>
                    <FaqItem q="22. Are market prices real?" a="Yes. Prediction results are calculated based on actual market data." />
                    <FaqItem q="23. Can users manipulate results?" a="No. Results are processed by an automated system and cannot be manipulated." />
                    <FaqItem q="24. Why did my result differ slightly from the chart I saw?" a="Slight differences may occur due to data feed delays or price differences between exchanges." />
                </FaqSection>

                <FaqSection title="Account & System" icon={Settings}>
                    <FaqItem q="25. Can I have multiple accounts?" a="Multiple accounts are restricted for fair competition." />
                    <FaqItem q="26. Will my points ever expire?" a="Some points may expire if you do not log in for a long time." />
                    <FaqItem q="27. Is my data secure?" a="Yes. All user data is protected according to security standards." />
                </FaqSection>


                {/* Contact */}
                <div className="pt-8 border-t border-white/10 space-y-4">
                    <h2 className="text-xl font-bold">Need more help?</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Link href="#" className="block">
                            <Card className="bg-card/10 border-white/5 hover:bg-white/5 transition-colors">
                                <CardContent className="p-6 flex items-center gap-4">
                                    <Mail className="w-8 h-8 text-blue-500" />
                                    <div>
                                        <div className="font-bold">Email Support</div>
                                        <div className="text-xs text-muted-foreground">support@chartclash.io</div>
                                    </div>
                                </CardContent>
                            </Card>
                        </Link>
                        <Link href="/community" className="block">
                            <Card className="bg-card/10 border-white/5 hover:bg-white/5 transition-colors">
                                <CardContent className="p-6 flex items-center gap-4">
                                    <MessageSquare className="w-8 h-8 text-indigo-500" />
                                    <div>
                                        <div className="font-bold">Community Forum</div>
                                        <div className="text-xs text-muted-foreground">Ask other traders</div>
                                    </div>
                                </CardContent>
                            </Card>
                        </Link>
                    </div>
                </div>

            </div>
        </div>
    );
}

function FaqSection({ title, icon: Icon, children }: { title: string, icon: any, children: React.ReactNode }) {
    return (
        <div className="space-y-3">
            <h2 className="text-lg font-bold flex items-center gap-2 text-white">
                <Icon className="w-5 h-5 text-purple-500" /> {title}
            </h2>
            <div className="space-y-2">
                {children}
            </div>
        </div>
    )
}

// ... imports

function FaqItem({ q, a }: { q: string, a: string }) {
    const [isOpen, setIsOpen] = useState(false);

    return (
        <Card
            className="bg-card/5 border-white/5 hover:bg-white/5 transition-colors cursor-pointer"
            onClick={() => setIsOpen(!isOpen)}
        >
            <CardContent className="p-3">
                <div className="flex items-center justify-between gap-4">
                    <h3 className="font-bold text-white text-sm select-none">{q}</h3>
                    {isOpen ? (
                        <div className="text-white/50"><Minus className="w-4 h-4" /></div>
                    ) : (
                        <div className="text-white/50"><Plus className="w-4 h-4" /></div>
                    )}
                </div>
                {isOpen && (
                    <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        className="pt-2"
                    >
                        <p className="text-sm text-gray-200 leading-relaxed border-t border-white/5 pt-3">
                            {a}
                        </p>
                    </motion.div>
                )}
            </CardContent>
        </Card>
    )
}
