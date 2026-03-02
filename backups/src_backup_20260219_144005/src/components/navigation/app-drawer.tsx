"use client"

import Link from "next/link"
import {
    Sheet,
    SheetContent,
    SheetHeader,
    SheetTitle,
} from "@/components/ui/sheet"
import { Separator } from "@/components/ui/separator"
import { ScrollArea } from "@/components/ui/scroll-area"
import {
    Trophy,
    BarChart3,
    MessageCircle,
    Gift,
    BookOpen,
    HelpCircle,
} from "lucide-react"
import { MenuButton } from "./menu-button"

export function AppDrawer() {
    return (
        <Sheet>
            {/* 햄버거 버튼 */}
            <MenuButton />

            {/* 좌측 슬라이드 패널 */}
            <SheetContent
                side="left"
                className="w-72 bg-[#0b0b0f] border-r border-white/10 p-0"
            >
                <SheetHeader className="p-6 pb-4">
                    <div className="flex items-center gap-2">
                        <div className="w-10 h-10 flex items-center justify-center">
                            <img src="/logo-main.png" alt="ChartClash Logo" className="w-full h-full object-contain" />
                        </div>
                        <SheetTitle className="text-xl font-black tracking-tight flex items-center">
                            <span className="text-blue-500">CHART</span>
                            <span className="text-orange-500">CLASH</span>
                        </SheetTitle>
                    </div>
                </SheetHeader>

                <ScrollArea className="h-[calc(100vh-80px)] px-4 pb-10">
                    <div className="space-y-6">

                        {/* ===== GAME ECOSYSTEM ===== */}
                        <div>
                            <p className="text-xs text-muted-foreground mb-3 px-2 font-bold tracking-wider">GAME</p>
                            <nav className="space-y-1">
                                <DrawerLink href="/leaderboard" icon={Trophy} label="Leaderboard" />
                                <DrawerLink href="/sentiment" icon={BarChart3} label="Market Sentiment" />
                                <DrawerLink href="/community" icon={MessageCircle} label="Community" />
                            </nav>
                        </div>

                        <Separator className="bg-white/10" />

                        {/* ===== INFO ===== */}
                        <div>
                            <p className="text-xs text-muted-foreground mb-3 px-2 font-bold tracking-wider">INFO</p>
                            <nav className="space-y-1">
                                <DrawerLink href="/rewards" icon={Gift} label="Season Rewards" />
                                <DrawerLink href="/how-it-works" icon={BookOpen} label="How It Works" />
                                <DrawerLink href="/help" icon={HelpCircle} label="Help / FAQ" />
                            </nav>
                        </div>

                    </div>
                </ScrollArea>
            </SheetContent>
        </Sheet>
    )
}

function DrawerLink({
    href,
    icon: Icon,
    label,
}: {
    href: string
    icon: any
    label: string
}) {
    return (
        <Link
            href={href}
            suppressHydrationWarning
            className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-muted-foreground hover:text-white hover:bg-white/5 transition-colors"
        >
            <Icon className="w-4 h-4" />
            {label}
        </Link>
    )
}
