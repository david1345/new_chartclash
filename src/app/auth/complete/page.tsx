"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";
import { AlertTriangle, LoaderCircle, ShieldCheck } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

type Status = "working" | "success" | "error";

export default function AuthCompletePage() {
    const searchParams = useSearchParams();
    const [status, setStatus] = useState<Status>("working");
    const [message, setMessage] = useState("Completing your sign-in session...");

    const code = searchParams.get("code");
    const next = searchParams.get("next")?.startsWith("/")
        ? searchParams.get("next")!
        : "/play/BTCUSDT/1h";
    const providerError = searchParams.get("error_description") || searchParams.get("error");

    const supabase = useMemo(() => createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookieOptions: {
                path: "/",
                sameSite: "lax",
                secure: process.env.NODE_ENV === "production",
            },
            auth: {
                detectSessionInUrl: false,
            },
        }
    ), []);

    useEffect(() => {
        let cancelled = false;

        const completeAuth = async () => {
            if (providerError) {
                setStatus("error");
                setMessage(providerError);
                return;
            }

            if (!code) {
                setStatus("error");
                setMessage("Missing OAuth code in callback.");
                return;
            }

            const { error } = await supabase.auth.exchangeCodeForSession(code);

            if (cancelled) {
                return;
            }

            if (error) {
                setStatus("error");
                setMessage(error.message);
                return;
            }

            setStatus("success");
            setMessage("Sign-in complete. Redirecting to the live market...");
            window.location.replace(next);
        };

        completeAuth();

        return () => {
            cancelled = true;
        };
    }, [code, next, providerError, supabase]);

    return (
        <main className="flex min-h-screen items-center justify-center bg-[#060914] px-4 text-white">
            <Card className="w-full max-w-lg border-white/10 bg-[#0C1321]">
                <CardHeader>
                    <div className="flex items-center gap-2 text-[11px] uppercase tracking-[0.22em] text-[#8DA4BF]">
                        <ShieldCheck className="h-4 w-4 text-[#00E5B4]" />
                        OAuth Session
                    </div>
                    <CardTitle className="text-2xl font-black tracking-tight text-white">
                        {status === "error" ? "Sign-in needs attention" : "Finalizing sign-in"}
                    </CardTitle>
                    <CardDescription className="text-[#93A8C1]">
                        {status === "error"
                            ? "The account provider returned, but the app could not finish creating a session."
                            : "Please wait while ChartClash completes your session."}
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className={`rounded-2xl border p-4 text-sm ${status === "error" ? "border-amber-500/30 bg-amber-500/10" : "border-[#00E5B4]/20 bg-[#00E5B4]/10"}`}>
                        <div className="flex items-start gap-3">
                            {status === "error" ? (
                                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-amber-300" />
                            ) : (
                                <LoaderCircle className="mt-0.5 h-4 w-4 shrink-0 animate-spin text-[#00E5B4]" />
                            )}
                            <div>
                                <div className="font-semibold text-white">
                                    {status === "success" ? "Session created" : status === "error" ? "Session exchange failed" : "Working"}
                                </div>
                                <div className="mt-1 break-words text-xs leading-5 text-[#D8E3EE]">
                                    {message}
                                </div>
                            </div>
                        </div>
                    </div>

                    {status === "error" ? (
                        <div className="space-y-3">
                            <div className="rounded-2xl border border-white/10 bg-white/5 p-4 text-xs leading-5 text-[#A5B7CB]">
                                If this happened inside MetaMask, KakaoTalk, Telegram, Discord, or another in-app browser,
                                open the site in Safari or Chrome and try again.
                            </div>
                            <div className="flex flex-wrap gap-2">
                                <Button asChild className="bg-[#00E5B4] text-black hover:bg-[#00E5B4]/90">
                                    <Link href="/login">
                                        Back to Login
                                    </Link>
                                </Button>
                                <Button asChild variant="outline" className="border-white/10 bg-white/5 hover:bg-white/10">
                                    <Link href="/auth-debug">
                                        Open Auth Debug
                                    </Link>
                                </Button>
                            </div>
                        </div>
                    ) : null}
                </CardContent>
            </Card>
        </main>
    );
}
