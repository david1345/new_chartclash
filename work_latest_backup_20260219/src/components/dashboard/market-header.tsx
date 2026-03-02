import Link from "next/link";
import { Activity, Timer, BarChart3, Trophy, Coins, Settings, Medal, ScrollText, LogOut } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { LiveClock } from "@/components/dashboard/live-clock";
import { AppDrawer } from "@/components/navigation/app-drawer";
import { NotificationBell } from "@/components/notifications/notification-bell";

interface HeaderProps {
    user: any;
    username: string | null;
    userPoints: number;
    userRank: number | null;
    mounted: boolean;
    isGhostMode?: boolean;
}

export function MarketHeader({
    user, username, userPoints, userRank, mounted, isGhostMode
}: HeaderProps) {
    return (
        <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl supports-[backdrop-filter]:bg-background/20">
            <div className="container mx-auto px-4 h-16 flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <AppDrawer />
                    <Link href="/" className="flex items-center gap-2 group">
                        <div className="w-10 h-10 flex items-center justify-center group-hover:scale-110 transition-transform">
                            <img src="/logo-main.png" alt="ChartClash Logo" className="w-full h-full object-contain" />
                        </div>
                        <span className="text-xl font-black tracking-tighter flex items-center">
                            <span className="text-blue-500">CHART</span>
                            <span className="text-orange-500">CLASH</span>
                        </span>
                    </Link>
                </div>

                <div className="flex items-center gap-4">
                    <div className="flex items-center gap-3">
                        {/* Live Clock (Component) */}
                        <div className="hidden md:flex items-center gap-2 text-amber-500 font-mono font-bold bg-amber-500/10 px-3 py-1 rounded-lg border border-amber-500/20 whitespace-nowrap h-8">
                            <Timer className="w-4 h-4 animate-pulse" />
                            <span>{mounted ? <LiveClock /> : "00:00:00"}</span>
                        </div>

                        <Link href="/#markets-hub">
                            <Button variant="ghost" size="sm" className="hidden md:flex gap-2 text-muted-foreground hover:text-primary hover:bg-primary/10 h-8">
                                <Activity className="w-4 h-4" /> Markets
                            </Button>
                        </Link>

                        <Link href="/sentiment">
                            <Button variant="ghost" size="sm" className="hidden md:flex gap-2 text-muted-foreground hover:text-blue-400 hover:bg-blue-400/10 h-8">
                                <BarChart3 className="w-4 h-4" /> Sentiment
                            </Button>
                        </Link>

                        <Link href="/leaderboard">
                            <Button id="tutorial-leaderboard" variant="ghost" size="sm" className="hidden md:flex gap-2 text-muted-foreground hover:text-yellow-400 hover:bg-yellow-400/10 h-8">
                                <Trophy className="w-4 h-4" /> Leaderboard
                            </Button>
                        </Link>
                    </div>

                    {/* User Profile Dropdown */}
                    {mounted && (
                        <div className="flex items-center gap-3">
                            {user && (
                                <div className="hidden md:flex flex-col items-end mr-2 text-right">
                                    {isGhostMode && (
                                        <Badge variant="outline" className="mb-0.5 border-purple-500/50 text-purple-400 bg-purple-500/10 text-[9px] h-3.5 py-0 px-1 font-black animate-pulse">
                                            GHOST MODE
                                        </Badge>
                                    )}
                                    <div className="flex items-center gap-1.5 text-yellow-500 font-bold font-mono text-sm">
                                        <Coins className="w-3.5 h-3.5" />
                                        <span data-testid="user-points">{userPoints.toLocaleString()}</span>
                                    </div>
                                    <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-bold">
                                        {userRank ? `Rank #${userRank}` : 'Unranked'}
                                    </span>
                                </div>
                            )}

                            <NotificationBell />

                            {!user ? (
                                <Link href="/login">
                                    <Button data-testid="login-button" variant="outline" className="h-8 border-primary/20 bg-primary/10 text-primary hover:bg-primary/20 hover:text-primary">
                                        Sign In / Up
                                    </Button>
                                </Link>
                            ) : (
                                <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                        <Button data-testid="user-menu-trigger" variant="ghost" className="relative h-8 w-8 rounded-full bg-white/10 hover:bg-white/20 border border-white/5 p-0 overflow-hidden">
                                            <div className="flex items-center justify-center w-full h-full bg-gradient-to-b from-gray-700 to-gray-800 text-xs font-bold text-white/70">
                                                {username?.[0]?.toUpperCase() || user?.user_metadata?.display_name?.[0]?.toUpperCase() || user?.email?.[0]?.toUpperCase() || "U"}
                                            </div>
                                        </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent className="w-56 bg-[#0b0b0f] border-white/10" align="end" forceMount>
                                        <DropdownMenuLabel className="font-normal">
                                            <div className="flex flex-col space-y-1">
                                                <p className="text-sm font-medium leading-none text-white">{username || user?.user_metadata?.display_name || user?.email?.split('@')[0] || 'Trader'}</p>
                                                <p className="text-xs leading-none text-muted-foreground truncate">{user?.email || 'guest@chartclash.app'}</p>
                                            </div>
                                        </DropdownMenuLabel>
                                        <DropdownMenuSeparator className="bg-white/10" />
                                        <DropdownMenuItem asChild>
                                            <Link href="/leaderboard" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                                                <Trophy className="w-4 h-4 text-yellow-500" /> Leaderboard
                                            </Link>
                                        </DropdownMenuItem>
                                        <DropdownMenuItem asChild>
                                            <Link href="/my-stats" data-testid="nav-my-stats" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                                                <Activity className="w-4 h-4" /> My Stats
                                            </Link>
                                        </DropdownMenuItem>
                                        <DropdownMenuItem asChild>
                                            <Link href="/match-history" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                                                <ScrollText className="w-4 h-4" /> Match History
                                            </Link>
                                        </DropdownMenuItem>
                                        <DropdownMenuItem asChild>
                                            <Link href="/achievements" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                                                <Medal className="w-4 h-4" /> Achievements
                                            </Link>
                                        </DropdownMenuItem>
                                        <DropdownMenuSeparator className="bg-white/10" />
                                        <DropdownMenuItem asChild>
                                            <Link href="/settings" className="cursor-pointer flex items-center gap-2 text-muted-foreground hover:text-white focus:text-white focus:bg-white/10">
                                                <Settings className="w-4 h-4" /> Settings
                                            </Link>
                                        </DropdownMenuItem>
                                        <DropdownMenuSeparator className="bg-white/10" />
                                        <DropdownMenuItem
                                            onClick={async () => {
                                                const supabase = createClient();
                                                await supabase.auth.signOut();
                                                window.location.href = "/login";
                                            }}
                                            className="cursor-pointer flex items-center gap-2 text-red-400 hover:text-red-300 focus:text-red-300 focus:bg-red-400/10"
                                        >
                                            <LogOut className="w-4 h-4" /> Log Out
                                        </DropdownMenuItem>
                                    </DropdownMenuContent>
                                </DropdownMenu>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </header>
    );
}

// Hero Component that was inline
export function MarketHero() {
    return (
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-900/20 to-purple-900/20 border border-white/5 p-6 md:p-8">
            <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 bg-primary/20 blur-[100px] rounded-full pointer-events-none" />
            <div className="relative z-10 max-w-3xl mx-auto text-center">
                <Badge variant="outline" className="mb-3 border-orange-500/50 text-orange-500 bg-orange-500/10 animate-pulse uppercase tracking-wider font-bold">LIVE SEASON 1</Badge>
                <h1 className="text-3xl md:text-4xl font-extrabold mb-2 tracking-tight">
                    <span className="text-blue-500">Predict.</span> <span className="text-orange-500">Compete.</span> <span className="text-white">Clash.</span>
                </h1>
                <p className="text-muted-foreground text-sm md:text-base mt-3">
                    Choose an asset, forecast its next move, and hit your volatility target.<br />
                    The more accurate your calls, the higher you rise on the leaderboard.
                </p>
                {/* HeroCTA and ScrollHintArrow can be added here if needed, or kept simple */}
            </div>
        </div>
    );
}
