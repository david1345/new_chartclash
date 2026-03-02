"use client";

import React, { useState } from "react";
import { Gamepad2, X, ExternalLink, Zap } from "lucide-react";
import {
    Sheet,
    SheetContent,
    SheetHeader,
    SheetTitle,
    SheetTrigger,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export interface EntertainmentHubProps {
    open?: boolean;
    onOpenChange?: (open: boolean) => void;
}

export function EntertainmentHub({ open: controlledOpen, onOpenChange }: EntertainmentHubProps) {
    const [internalOpen, setInternalOpen] = useState(false);

    const isOpen = controlledOpen !== undefined ? controlledOpen : internalOpen;
    const setIsOpen = onOpenChange || setInternalOpen;

    return (
        <div className="fixed bottom-6 right-6 z-[60]">
            <Sheet open={isOpen} onOpenChange={setIsOpen}>
                <SheetTrigger asChild>
                    <Button
                        size="icon"
                        className="h-14 w-14 rounded-full shadow-2xl shadow-blue-500/20 bg-gradient-to-tr from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 border-2 border-white/20 transition-all hover:scale-110 active:scale-95 group"
                    >
                        <Gamepad2 className="w-7 h-7 text-white group-hover:animate-bounce" />
                        <span className="absolute -top-1 -right-1 flex h-4 w-4">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-4 w-4 bg-orange-500 border-2 border-[#0b0b0f] text-[8px] font-bold text-white items-center justify-center">!</span>
                        </span>
                    </Button>
                </SheetTrigger>
                <SheetContent
                    side="right"
                    className="w-full sm:w-[450px] p-0 border-l border-white/10 bg-[#0b0b0f] overflow-hidden flex flex-col"
                >
                    <SheetHeader className="p-4 border-b border-white/5 bg-gradient-to-r from-blue-900/40 to-black shrink-0">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-blue-500/20 rounded-lg">
                                    <Zap className="w-5 h-5 text-blue-400" />
                                </div>
                                <div>
                                    <SheetTitle className="text-white text-lg font-black tracking-tight flex items-center gap-2">
                                        AI-BEAT <span className="text-blue-500 text-xs font-bold px-1.5 py-0.5 rounded border border-blue-500/30">CHALLENGE</span>
                                    </SheetTitle>
                                    <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-bold">Predict with AI and Win</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <Button
                                    variant="ghost"
                                    size="icon-xs"
                                    className="text-muted-foreground hover:text-white"
                                    onClick={() => window.open("http://127.0.0.1:3001", "_blank")}
                                >
                                    <ExternalLink className="w-4 h-4" />
                                </Button>
                            </div>
                        </div>
                    </SheetHeader>

                    <div className="flex-1 relative bg-black">
                        {/* Loading State or Iframe */}
                        <iframe
                            src="http://127.0.0.1:3001"
                            className="w-full h-full border-none shadow-inner"
                            title="AI-Beat Challenge"
                            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                        />
                    </div>

                    <div className="p-3 bg-blue-950/20 border-t border-white/5 shrink-0 text-center">
                        <p className="text-[10px] text-blue-400/70 font-medium">
                            Don't miss your entry! Current game results in progress.
                        </p>
                    </div>
                </SheetContent>
            </Sheet>
        </div>
    );
}
