"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { AlertTriangle, Copy, ExternalLink, RefreshCw, ShieldCheck, Smartphone } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";

type OAuthProvider = "google" | "discord" | "github";

type HealthResult = {
    status: string;
    body: string;
};

function detectBrowserContext(userAgent: string) {
    const checks = [
        { label: "KakaoTalk in-app browser", regex: /KAKAOTALK/i },
        { label: "Instagram in-app browser", regex: /Instagram/i },
        { label: "Facebook in-app browser", regex: /FBAN|FBAV/i },
        { label: "Discord in-app browser", regex: /Discord/i },
        { label: "Telegram in-app browser", regex: /Telegram/i },
        { label: "X/Twitter in-app browser", regex: /Twitter/i },
        { label: "LINE in-app browser", regex: /Line\//i },
        { label: "Naver in-app browser", regex: /NAVER/i },
        { label: "Samsung Internet", regex: /SamsungBrowser/i },
    ];

    const match = checks.find((item) => item.regex.test(userAgent));

    return {
        isInApp: Boolean(match) && !/Safari|CriOS|Chrome/i.test(userAgent),
        label: match?.label ?? "Standalone browser",
    };
}

export default function AuthDebugPage() {
    const supabase = useMemo(() => createClient(), []);
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
    const supabaseHost = useMemo(() => {
        try {
            return new URL(supabaseUrl).host;
        } catch {
            return "missing-supabase-url";
        }
    }, [supabaseUrl]);

    const [origin, setOrigin] = useState("");
    const [userAgent, setUserAgent] = useState("");
    const [provider, setProvider] = useState<OAuthProvider>("google");
    const [loading, setLoading] = useState(false);
    const [oauthUrl, setOauthUrl] = useState("");
    const [errorMessage, setErrorMessage] = useState("");
    const [healthResult, setHealthResult] = useState<HealthResult | null>(null);

    const browserContext = detectBrowserContext(userAgent);
    const callbackUrl = origin ? `${origin}/auth/callback` : "";

    useEffect(() => {
        setOrigin(window.location.origin);
        setUserAgent(window.navigator.userAgent);
    }, []);

    const runHealthCheck = async () => {
        if (!supabaseUrl) {
            setHealthResult({
                status: "missing",
                body: "NEXT_PUBLIC_SUPABASE_URL is missing in this build.",
            });
            return;
        }

        try {
            const response = await fetch(`${supabaseUrl}/auth/v1/health`);
            const body = await response.text();

            setHealthResult({
                status: `${response.status} ${response.statusText}`,
                body: body.slice(0, 300),
            });
        } catch (error) {
            setHealthResult({
                status: "network-error",
                body: error instanceof Error ? error.message : "Unknown network error",
            });
        }
    };

    const buildOAuthUrl = async (nextProvider: OAuthProvider) => {
        setLoading(true);
        setProvider(nextProvider);
        setOauthUrl("");
        setErrorMessage("");

        const { data, error } = await supabase.auth.signInWithOAuth({
            provider: nextProvider,
            options: {
                redirectTo: `${window.location.origin}/auth/callback`,
                skipBrowserRedirect: true,
                queryParams: nextProvider === "google" ? {
                    prompt: "select_account",
                    access_type: "offline",
                } : undefined,
            },
        });

        if (error) {
            setErrorMessage(error.message);
            toast.error(error.message);
            setLoading(false);
            return;
        }

        if (!data?.url) {
            setErrorMessage("Supabase did not return an OAuth URL.");
            setLoading(false);
            return;
        }

        setOauthUrl(data.url);
        toast.success(`${nextProvider} OAuth URL generated.`);
        setLoading(false);
    };

    const copyUrl = async () => {
        if (!oauthUrl) {
            return;
        }

        try {
            await navigator.clipboard.writeText(oauthUrl);
            toast.success("OAuth URL copied.");
        } catch (error) {
            toast.error(error instanceof Error ? error.message : "Copy failed.");
        }
    };

    return (
        <div className="min-h-screen bg-background px-4 py-8 text-foreground">
            <div className="mx-auto flex w-full max-w-5xl flex-col gap-6">
                <div className="space-y-2">
                    <div className="flex items-center gap-2 text-xs uppercase tracking-[0.24em] text-muted-foreground">
                        <Smartphone className="h-3.5 w-3.5" />
                        Auth Debug
                    </div>
                    <h1 className="text-3xl font-black tracking-tight">Mobile OAuth Inspector</h1>
                    <p className="max-w-2xl text-sm text-muted-foreground">
                        This page generates the exact Supabase OAuth URL used by production, then lets you open or copy it on the phone.
                        It helps us separate “URL generation works” from “browser/network redirect fails”.
                    </p>
                </div>

                <div className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
                    <Card className="border-white/10 bg-black/20">
                        <CardHeader>
                            <CardTitle>Runtime Snapshot</CardTitle>
                            <CardDescription>
                                These values come from the live client bundle running in this browser.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4 text-sm">
                            <div className="grid gap-4 md:grid-cols-2">
                                <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                    <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Origin</div>
                                    <div className="mt-2 break-all font-mono text-xs">{origin || "Loading..."}</div>
                                </div>
                                <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                    <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Callback URL</div>
                                    <div className="mt-2 break-all font-mono text-xs">{callbackUrl || "Loading..."}</div>
                                </div>
                                <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                    <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Supabase Host</div>
                                    <div className="mt-2 break-all font-mono text-xs">{supabaseHost}</div>
                                </div>
                                <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                    <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Browser Context</div>
                                    <div className="mt-2 text-xs">
                                        <span className={browserContext.isInApp ? "text-amber-400" : "text-emerald-400"}>
                                            {browserContext.label}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div className={`rounded-lg border p-4 text-sm ${browserContext.isInApp ? "border-amber-500/30 bg-amber-500/10" : "border-emerald-500/30 bg-emerald-500/10"}`}>
                                <div className="flex items-center gap-2 font-semibold">
                                    {browserContext.isInApp ? <AlertTriangle className="h-4 w-4" /> : <ShieldCheck className="h-4 w-4" />}
                                    {browserContext.isInApp ? "In-app browser detected" : "Standalone browser detected"}
                                </div>
                                <p className="mt-2 text-xs text-muted-foreground">
                                    {browserContext.isInApp
                                        ? "Google OAuth often fails inside in-app browsers. Please open this page in Safari or Chrome first."
                                        : "This browser context looks suitable for Google OAuth."}
                                </p>
                            </div>

                            <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">User Agent</div>
                                <div className="mt-2 break-all font-mono text-[11px] text-muted-foreground">
                                    {userAgent || "Loading..."}
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="border-white/10 bg-black/20">
                        <CardHeader>
                            <CardTitle>Supabase Reachability</CardTitle>
                            <CardDescription>
                                This checks the exact Auth host that the production bundle is using.
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4 text-sm">
                            <Button
                                variant="outline"
                                className="w-full border-white/10 bg-white/5 hover:bg-white/10"
                                onClick={runHealthCheck}
                            >
                                <RefreshCw className="h-4 w-4" />
                                Check `/auth/v1/health`
                            </Button>

                            <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Health Status</div>
                                <div className="mt-2 font-mono text-xs">{healthResult?.status ?? "Not checked yet"}</div>
                                <div className="mt-3 break-all font-mono text-[11px] text-muted-foreground">
                                    {healthResult?.body ?? "Run the health check on the phone to verify direct access."}
                                </div>
                            </div>

                            <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                                <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Direct Host Test</div>
                                <a
                                    href={`${supabaseUrl}/auth/v1/health`}
                                    target="_blank"
                                    rel="noreferrer"
                                    className="mt-2 inline-flex break-all font-mono text-xs text-primary underline underline-offset-4"
                                >
                                    {supabaseUrl ? `${supabaseUrl}/auth/v1/health` : "Missing Supabase URL"}
                                </a>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                <Card className="border-white/10 bg-black/20">
                    <CardHeader>
                        <CardTitle>OAuth URL Generator</CardTitle>
                        <CardDescription>
                            Generates the exact provider URL that the live login page would open.
                        </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="flex flex-wrap gap-2">
                            <Button
                                className="bg-primary text-primary-foreground hover:bg-primary/90"
                                onClick={() => buildOAuthUrl("google")}
                                disabled={loading}
                            >
                                {loading && provider === "google" ? "..." : "Generate Google URL"}
                            </Button>
                            <Button
                                variant="outline"
                                className="border-white/10 bg-white/5 hover:bg-white/10"
                                onClick={() => buildOAuthUrl("discord")}
                                disabled={loading}
                            >
                                {loading && provider === "discord" ? "..." : "Generate Discord URL"}
                            </Button>
                            <Button
                                variant="outline"
                                className="border-white/10 bg-white/5 hover:bg-white/10"
                                onClick={() => buildOAuthUrl("github")}
                                disabled={loading}
                            >
                                {loading && provider === "github" ? "..." : "Generate GitHub URL"}
                            </Button>
                        </div>

                        {errorMessage ? (
                            <div className="rounded-lg border border-destructive/40 bg-destructive/10 p-4 text-sm text-destructive">
                                {errorMessage}
                            </div>
                        ) : null}

                        <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                            <div className="flex items-center justify-between gap-3">
                                <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">Latest OAuth URL</div>
                                <div className="text-[11px] uppercase tracking-[0.18em] text-muted-foreground">
                                    Provider: {provider}
                                </div>
                            </div>

                            <div className="mt-3 break-all font-mono text-[11px] text-muted-foreground">
                                {oauthUrl || "Generate a provider URL to inspect the exact redirect target."}
                            </div>

                            <div className="mt-4 flex flex-wrap gap-2">
                                <Button
                                    variant="outline"
                                    className="border-white/10 bg-white/5 hover:bg-white/10"
                                    onClick={copyUrl}
                                    disabled={!oauthUrl}
                                >
                                    <Copy className="h-4 w-4" />
                                    Copy URL
                                </Button>
                                <Button
                                    className="bg-primary text-primary-foreground hover:bg-primary/90"
                                    onClick={() => window.location.href = oauthUrl}
                                    disabled={!oauthUrl}
                                >
                                    <ExternalLink className="h-4 w-4" />
                                    Open Generated URL
                                </Button>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
                    <Link href="/login" className="underline underline-offset-4 hover:text-primary">
                        Back to login
                    </Link>
                    <span>•</span>
                    <a
                        href="https://newchartclash.vercel.app/login"
                        target="_blank"
                        rel="noreferrer"
                        className="underline underline-offset-4 hover:text-primary"
                    >
                        Open production login in new tab
                    </a>
                </div>
            </div>
        </div>
    );
}
