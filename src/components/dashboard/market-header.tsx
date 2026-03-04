"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Zap, Trophy, BrainCircuit, Wallet, LogOut, Settings } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

interface HeaderProps {
    user: any;
    username: string | null;
    userPoints: number;
    userRank?: number | null;
    activeCount?: number;
    isGhostMode?: boolean;
    onAssetSelect?: (asset: any) => void;
}

export function MarketHeader({
    user, username, userPoints
}: HeaderProps) {
    const pathname = usePathname() || "";

    return (
        <header className="sticky top-0 z-50 w-full border-b border-[#1E2D45] bg-[#0F1623]">
            <div className="container mx-auto px-4 h-14 flex items-center justify-between gap-4">
                {/* Logo */}
                <Link href="/" className="flex items-center gap-1 shrink-0">
                    <span className="text-lg lg:text-xl font-black tracking-tighter text-white uppercase flex items-center">
                        CHART<span className="text-[#00E5B4]">CLASH</span>
                    </span>
                </Link>

                {/* Desktop Nav Links */}
                <nav className="hidden lg:flex items-center gap-2 flex-1 ml-8">
                    <Link href="/play/BTCUSDT/1h">
                        <Button variant="ghost" size="sm" className={cn("text-[13px] font-bold h-9 px-4 rounded-lg", pathname.includes("/play") ? "bg-[#00E5B4]/10 text-[#00E5B4]" : "text-[#5A7090] hover:text-white")}>
                            ⚡ Battle
                        </Button>
                    </Link>
                    <Link href="/leaderboard">
                        <Button variant="ghost" size="sm" className={cn("text-[13px] font-bold h-9 px-4 rounded-lg", pathname.includes("/leaderboard") ? "bg-[#00E5B4]/10 text-[#00E5B4]" : "text-[#5A7090] hover:text-white")}>
                            🏆 Leaderboard
                        </Button>
                    </Link>
                    <Link href="/community?tab=analyst-hub">
                        <Button variant="ghost" size="sm" className={cn("text-[13px] font-bold h-9 px-4 rounded-lg", pathname.includes("/community") ? "bg-[#00E5B4]/10 text-[#00E5B4]" : "text-[#5A7090] hover:text-white")}>
                            🤖 AI Hub
                        </Button>
                    </Link>
                </nav>

                {/* Right: Wallet & Avatar */}
                <div className="flex items-center gap-3 shrink-0 ml-auto">
                    {/* Wallet Badge */}
                    <div className="h-8 bg-[#141D2E] border border-[#1E2D45] rounded-full px-3 flex items-center gap-1.5">
                        <span className="font-mono text-[11px] sm:text-[13px] font-bold text-[#00E5B4] whitespace-nowrap mt-[1px]">
                            💰 {(userPoints ?? 1000).toLocaleString()} <span className="text-[9px] sm:text-[10px] text-[#00E5B4]/70">USDT</span>
                        </span>
                    </div>

                    <Link href="/deposit" className="hidden lg:inline-flex">
                        <Button className="bg-[#00E5B4] hover:bg-[#00E5B4]/80 text-black font-bold h-8 px-4 text-xs rounded-lg">
                            + Deposit
                        </Button>
                    </Link>

                    {!user ? (
                        <Link href="/login">
                            <Button
                                variant="outline"
                                className="h-8 border-[#00E5B4]/20 bg-[#00E5B4]/10 text-[#00E5B4] hover:bg-[#00E5B4]/20 px-2 lg:px-3 text-[9px] sm:text-[10px] leading-tight text-center font-black tracking-wider uppercase rounded-full"
                            >
                                SIGN<br className="sm:hidden" /> IN/UP
                            </Button>
                        </Link>
                    ) : (
                        <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                                <Button variant="ghost" className="h-8 w-8 rounded-full p-0 overflow-hidden bg-gradient-to-br from-[#00E5B4] to-blue-600 border border-white/10 hover:opacity-90">
                                    <div className="flex items-center justify-center w-full h-full text-xs font-bold text-white shadow-inner">
                                        {username?.[0]?.toUpperCase() || user?.email?.[0]?.toUpperCase() || "U"}
                                    </div>
                                </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent className="w-56 bg-[#0F1623] border-[#1E2D45]" align="end">
                                <DropdownMenuLabel className="font-normal">
                                    <div className="flex flex-col space-y-1">
                                        <p className="text-sm font-medium leading-none text-white">{username || user?.email?.split('@')[0] || 'Trader'}</p>
                                        <p className="text-xs leading-none text-[#5A7090] truncate">{user?.email}</p>
                                    </div>
                                </DropdownMenuLabel>
                                <DropdownMenuSeparator className="bg-[#1E2D45]" />
                                <DropdownMenuItem asChild>
                                    <Link href="/wallet" className="cursor-pointer flex items-center gap-2 text-[#8BA3BF] hover:text-white focus:text-white focus:bg-white/10">
                                        <Wallet className="w-4 h-4" /> Wallet & Stats
                                    </Link>
                                </DropdownMenuItem>
                                <DropdownMenuItem asChild>
                                    <Link href="/settings" className="cursor-pointer flex items-center gap-2 text-[#8BA3BF] hover:text-white focus:text-white focus:bg-white/10">
                                        <Settings className="w-4 h-4" /> Settings
                                    </Link>
                                </DropdownMenuItem>
                                <DropdownMenuSeparator className="bg-[#1E2D45]" />
                                <DropdownMenuItem
                                    onClick={async () => {
                                        const supabase = createClient();
                                        await supabase.auth.signOut();
                                        window.location.href = "/login";
                                    }}
                                    className="cursor-pointer flex items-center gap-2 text-[#FF4560] hover:text-[#FF4560]/80 focus:text-[#FF4560]"
                                >
                                    <LogOut className="w-4 h-4" /> Log Out
                                </DropdownMenuItem>
                            </DropdownMenuContent>
                        </DropdownMenu>
                    )}
                </div>
            </div>
        </header>
    );
}

export function MarketHero() {
    return null;
}
