"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Zap, Trophy, Wallet } from "lucide-react";
import { cn } from "@/lib/utils";

export function BottomNav() {
    const pathname = usePathname();

    const navItems = [
        { label: "HOME", icon: Home, href: "/" },
        { label: "BATTLE", icon: Zap, href: "/play/BTCUSDT/1h" }, // Or "/play" if we have a generic router
        { label: "RANK", icon: Trophy, href: "/leaderboard" },
        { label: "WALLET", icon: Wallet, href: "/wallet" },
    ];

    return (
        <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-[#0F1623] border-t border-[#1E2D45] z-50 pb-safe">
            <div className="flex px-2 py-2 pb-6 justify-between items-center">
                {navItems.map((item) => {
                    const isActive =
                        pathname === item.href ||
                        (item.href !== "/" && pathname.startsWith(item.href.split("/")[1] ? "/" + item.href.split("/")[1] : "---"));
                    // e.g. /play/BTCUSDT/1h matches /play

                    return (
                        <Link
                            key={item.label}
                            href={item.href}
                            className="flex flex-col items-center justify-center flex-1 gap-1 cursor-pointer"
                        >
                            <item.icon
                                className={cn(
                                    "w-5 h-5 transition-all",
                                    isActive
                                        ? "text-[#00E5B4] drop-shadow-[0_0_6px_rgba(0,229,180,0.8)]"
                                        : "text-[#5A7090]"
                                )}
                            />
                            <span
                                className={cn(
                                    "text-[10px] font-semibold tracking-[0.04em]",
                                    isActive ? "text-[#00E5B4]" : "text-[#5A7090]"
                                )}
                            >
                                {item.label}
                            </span>
                        </Link>
                    );
                })}
            </div>
        </div>
    );
}
