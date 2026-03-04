"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Activity } from "lucide-react";
import { ActivePositionPanel } from "@/components/battle/active-position-panel";

interface DesktopActivePositionProps {
    activePrediction: any;
    currentPrice: number | null;
}

export function DesktopActivePosition({ activePrediction, currentPrice }: DesktopActivePositionProps) {
    if (!activePrediction) return null;

    return (
        <Card className="bg-[#0F1623] border-[#1E2D45] overflow-hidden flex flex-col shrink-0">
            <CardHeader className="py-2 px-3 bg-[#141D2E] border-b border-[#1E2D45] shrink-0 min-h-[36px] flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-xs font-bold flex items-center gap-2 uppercase tracking-wider text-white">
                    <Activity className="w-3 h-3 text-primary" /> Active Position
                </CardTitle>
            </CardHeader>
            <CardContent className="p-3 bg-[#080C14]">
                <ActivePositionPanel prediction={activePrediction} currentPrice={currentPrice} />
            </CardContent>
        </Card>
    );
}
