"use client";

import { useState } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowLeft, HelpCircle, Home, Info, Lock, Mail, MessageSquare, Settings, Target, Wallet } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

export default function HelpPage() {
    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
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
                    <FaqItem q="1. Is ChartClash a real-money product?" a="Yes. ChartClash is a USDT staking market. Users fund an internal contract balance and take long or short positions on scheduled rounds." />
                    <FaqItem q="2. Do I need both an account and a wallet?" a="Yes. Your account handles identity, history, and portfolio views. MetaMask handles signing, deposits, withdrawals, and on-chain betting." />
                    <FaqItem q="3. Can I use the product without connecting a wallet?" a="You can browse markets without a wallet, but you cannot place live bets until you sign in and connect MetaMask." />
                    <FaqItem q="4. Which network is used?" a="The current staking flow is built around the configured Polygon network environment shown in the wallet and deposit screens." />
                </FaqSection>

                <FaqSection title="Wallet & Funding" icon={Wallet}>
                    <FaqItem q="5. How do I start?" a="Connect MetaMask, deposit USDT into the ChartClash contract balance, then choose a market and place a long or short bet." />
                    <FaqItem q="6. Where is my available balance?" a="Your available staking balance is the contract balance shown in the header, wallet page, and stake composer." />
                    <FaqItem q="7. Can I withdraw at any time?" a="You can withdraw available contract balance that is not tied up in unresolved positions. Withdrawals are processed on-chain and may include a platform fee." />
                    <FaqItem q="8. What happens if I send unsupported assets?" a="Only the supported USDT network and token should be used. Unsupported assets or wrong-network transfers may be unrecoverable." />
                </FaqSection>

                <FaqSection title="Market Mechanics" icon={Target}>
                    <FaqItem q="9. How does a market resolve?" a="Each round opens with a fixed reference price and resolves against a fixed market data source. When the round closes, the final direction determines win, loss, or refund." />
                    <FaqItem q="10. What is the payout model?" a="ChartClash uses a pari-mutuel structure. Winners split the losing side's pool pro-rata after the applicable fee on winnings." />
                    <FaqItem q="11. What if the market closes flat or only one side placed bets?" a="Those rounds are treated as void/refund rounds. Your stake is returned rather than scored as a win or loss." />
                    <FaqItem q="12. Can I cancel after placing a bet?" a="No. Once a transaction is confirmed on-chain, the position is locked for that round." />
                </FaqSection>

                <FaqSection title="Fees & Risk" icon={Lock}>
                    <FaqItem q="13. Are all bets charged the same fee?" a="No. Early GREEN entries receive a lower fee on winnings than later YELLOW or RED entries. The contract applies the fee schedule at claim time." />
                    <FaqItem q="14. What do I lose if my position is wrong?" a="A losing position loses its stake for that round. Only refunded rounds return the full stake." />
                    <FaqItem q="15. Is there guaranteed profit?" a="No. ChartClash is a risk product. Every trade can lose money, and no content on the platform should be treated as guaranteed outcome or financial advice." />
                </FaqSection>

                <FaqSection title="Leaderboard & History" icon={MessageSquare}>
                    <FaqItem q="16. What does the leaderboard rank?" a="The leaderboard ranks real trading performance metrics such as net PnL, hit rate, and resolved market history." />
                    <FaqItem q="17. Why might my history appear before settlement?" a="Positions are mirrored into your ledger when the on-chain bet succeeds, then updated to win, loss, or refund once the round settles." />
                    <FaqItem q="18. Why could a chart differ slightly from resolution?" a="Display charts can differ from the exact resolution candle because the official close is taken from the market source locked in the round rules." />
                </FaqSection>

                <FaqSection title="Account & Compliance" icon={Settings}>
                    <FaqItem q="19. Can I have multiple accounts?" a="No. Multi-accounting, coordinated abuse, and automated exploitation are prohibited and can lead to restrictions or bans." />
                    <FaqItem q="20. Is availability the same in every country?" a="Not necessarily. Real-money access may depend on jurisdiction, compliance requirements, and future policy updates." />
                    <FaqItem q="21. Is my data secure?" a="Account data is handled through the app stack, while transactions are signed in your wallet. You are responsible for wallet security and key custody." />
                </FaqSection>

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
                                        <div className="text-xs text-muted-foreground">Discuss live markets with other traders</div>
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

function FaqSection({ title, icon: Icon, children }: { title: string; icon: any; children: React.ReactNode }) {
    return (
        <div className="space-y-3">
            <h2 className="text-lg font-bold flex items-center gap-2 text-white">
                <Icon className="w-5 h-5 text-purple-500" /> {title}
            </h2>
            <div className="space-y-2">{children}</div>
        </div>
    );
}

function FaqItem({ q, a }: { q: string; a: string }) {
    const [isOpen, setIsOpen] = useState(false);

    return (
        <Card className="bg-card/5 border-white/5 hover:bg-white/5 transition-colors cursor-pointer" onClick={() => setIsOpen(!isOpen)}>
            <CardContent className="p-3">
                <div className="flex items-center justify-between gap-4">
                    <h3 className="font-bold text-white text-sm select-none">{q}</h3>
                    <div className="text-white/50">{isOpen ? "−" : "+"}</div>
                </div>
                {isOpen && (
                    <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} className="pt-2">
                        <p className="text-sm text-gray-200 leading-relaxed border-t border-white/5 pt-3">{a}</p>
                    </motion.div>
                )}
            </CardContent>
        </Card>
    );
}
