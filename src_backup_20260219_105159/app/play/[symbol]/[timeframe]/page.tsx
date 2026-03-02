"use client";

import dynamic from "next/dynamic";
import { Skeleton } from "@/components/ui/skeleton";

// Deeply Dynamic Import for the entire Play page content
const PlayContent = dynamic(() => import("@/components/dashboard/play-content").then(mod => mod.PlayContent), {
    ssr: false,
    loading: () => <PlaySkeleton />
});

export default function PlayPage() {
    return <PlayContent />;
}

function PlaySkeleton() {
    return (
        <main className="min-h-screen bg-[#060609] text-white overflow-hidden">
            {/* Header Skeleton */}
            <div className="h-16 border-b border-white/5 bg-background/20 backdrop-blur-xl flex items-center px-4 justify-between">
                <div className="flex items-center gap-4">
                    <Skeleton className="w-8 h-8 rounded-lg bg-white/5" />
                    <Skeleton className="w-32 h-6 bg-white/5" />
                </div>
                <div className="flex items-center gap-4">
                    <Skeleton className="w-24 h-8 rounded-full bg-white/5" />
                    <Skeleton className="w-8 h-8 rounded-full bg-white/5" />
                </div>
            </div>

            <div className="container mx-auto px-4 py-8 space-y-8 max-w-6xl">
                {/* Hero Skeleton */}
                <Skeleton className="w-full h-40 rounded-2xl bg-white/5 border border-white/5" />

                {/* Main Content Grid Skeleton */}
                <section className="grid grid-cols-1 md:grid-cols-12 gap-4 items-stretch min-h-[850px]">
                    {/* Left Column */}
                    <div className="md:col-span-4 h-full flex flex-col gap-3">
                        <Skeleton className="w-full h-[400px] rounded-2xl bg-white/5 border border-white/5" />
                        <Skeleton className="w-full h-[340px] rounded-2xl bg-white/5 border border-white/5 mt-auto" />
                    </div>

                    {/* Right Column */}
                    <div className="md:col-span-8 h-full flex flex-col gap-3">
                        <Skeleton className="w-full h-[480px] rounded-2xl bg-white/5 border border-white/5" />
                        <div className="h-[340px] mt-auto grid grid-cols-1 md:grid-cols-2 gap-3">
                            <Skeleton className="w-full h-full rounded-2xl bg-white/5 border border-white/5" />
                            <Skeleton className="w-full h-full rounded-2xl bg-white/5 border border-white/5" />
                        </div>
                    </div>
                </section>
            </div>
        </main>
    );
}
