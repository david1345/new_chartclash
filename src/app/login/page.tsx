"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { createClient } from "@/lib/supabase/client";
import { motion } from "framer-motion";
import { Lock, Github, MessageSquare } from "lucide-react";

import { toast } from "sonner";
import { DISPOSABLE_EMAIL_DOMAINS } from "@/lib/constants/disposable-domains";

export default function LoginPage() {
    const [mode, setMode] = useState<"login" | "signup">("login");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const searchParams = useSearchParams();
    const supabase = createClient();
    const authError = searchParams.get("error");
    const authReason = searchParams.get("reason");

    const handleOAuthLogin = async (provider: 'google' | 'discord' | 'github') => {
        setLoading(true);
        const callbackUrl = new URL("/auth/callback", window.location.origin);
        callbackUrl.searchParams.set("next", "/play/BTCUSDT/1h");

        const { data, error } = await supabase.auth.signInWithOAuth({
            provider,
            options: {
                redirectTo: callbackUrl.toString(),
                skipBrowserRedirect: true,
                queryParams: provider === 'google' ? {
                    prompt: 'select_account',
                    access_type: 'offline'
                } : undefined
            },
        });

        if (error) {
            toast.error(error.message);
            setLoading(false);
            return;
        }

        if (data?.url) {
            window.location.href = data.url;
        }
    };

    const handleAction = async () => {
        if (!email || !password) {
            toast.error("Please enter both email and password.");
            return;
        }

        // Garbage email check
        if (mode === "signup") {
            const domain = email.split('@')[1]?.toLowerCase();
            if (DISPOSABLE_EMAIL_DOMAINS.includes(domain)) {
                toast.error("Disposable email addresses are not allowed. Please use a permanent email.");
                return;
            }

            // Password Complexity Check
            if (password.length < 6) {
                toast.error("Password must be at least 6 characters long.");
                return;
            }
        }

        setLoading(true);
        if (mode === "login") {
            const { data, error } = await supabase.auth.signInWithPassword({
                email,
                password,
            });
            if (error) {
                toast.error(error.message);
            } else {
                window.location.href = "/play/BTCUSDT/1h";
            }
        } else {
            const generatedNickname = "Trader_" + Math.floor(Math.random() * 100000);
            const { data, error } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        display_name: generatedNickname,
                    }
                }
            });
            if (error) {
                toast.error(error.message);
            } else {
                toast.success("Welcome aboard! ChartClash is ready.");
                // Immediately log them in by redirecting since auto confirm is suspected
                window.location.href = "/play/BTCUSDT/1h";
            }
        }
        setLoading(false);
    };

    return (
        <div className="flex min-h-screen flex-col items-center pt-10 bg-background px-4 relative overflow-hidden">
            {/* Background Ambience */}
            <div className="absolute inset-0 z-0 pointer-events-none">
                <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary/20 blur-[120px] rounded-full mix-blend-screen" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-blue-600/20 blur-[120px] rounded-full mix-blend-screen" />
            </div>

            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5 }}
                className="z-10 w-full max-w-md"
            >
                <div className="text-center space-y-1 pb-4 px-2">
                    <motion.div
                        initial={{ scale: 0.9, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        className="mx-auto w-20 h-20 mb-2"
                    >
                        <img src="/logo-main.png" alt="ChartClash" className="w-full h-full object-contain" />
                    </motion.div>
                    <h1 className="text-2xl font-black tracking-tighter flex items-center justify-center gap-0">
                        <span className="text-blue-500">CHART</span>
                        <span className="text-orange-500">CLASH</span>
                    </h1>
                    <p className="text-xs text-muted-foreground/80">
                        {mode === "login" ? "Welcome back! Please log in." : "Create a new account to start."}
                    </p>
                </div>

                <div className="space-y-3 pb-2 px-2">
                    {authError ? (
                        <div className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-[11px] leading-5 text-amber-100">
                            <div className="font-semibold uppercase tracking-[0.16em] text-amber-300">
                                Social login did not complete
                            </div>
                            <div className="mt-1">
                                {authReason || "The OAuth callback failed before a session could be created."}
                            </div>
                            <div className="mt-2 text-amber-200/80">
                                If this happened inside an in-app browser, open the site in Safari or Chrome and try again.
                            </div>
                        </div>
                    ) : null}

                    <div className="space-y-1.5">
                        <Input
                            data-testid="email-input"
                            type="email"
                            placeholder="Email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            className="bg-black/20 border-white/10 focus:border-primary/50 focus:ring-primary/50 h-8 text-xs transition-all"
                        />
                        <Input
                            data-testid="password-input"
                            type="password"
                            placeholder="Password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="bg-black/20 border-white/10 focus:border-primary/50 focus:ring-primary/50 h-8 text-xs transition-all"
                        />

                        {mode === "signup" && (
                            <div className="space-y-1.5 pt-1 px-1">
                                <div className="flex items-center gap-1.5">
                                    <div className={`w-1.5 h-1.5 rounded-full transition-colors ${password.length >= 6 ? "bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]" : "bg-white/20"}`} />
                                    <span className={`text-[10px] transition-colors ${password.length >= 6 ? "text-green-400 font-medium" : "text-muted-foreground"}`}>
                                        6+ Characters
                                    </span>
                                </div>
                            </div>
                        )}
                    </div>

                    <div className="grid grid-cols-2 gap-2 pt-1">
                        <Button
                            data-testid="submit-login"
                            onClick={() => mode === "login" ? handleAction() : setMode("login")}
                            className={`w-full font-semibold h-8 text-xs transition-all ${mode === "login"
                                ? "bg-primary hover:bg-primary/90 text-primary-foreground shadow-[0_0_20px_rgba(var(--primary),0.3)]"
                                : "bg-transparent border border-white/10 text-muted-foreground hover:bg-white/5"
                                }`}
                            disabled={loading}
                        >
                            {loading && mode === "login" ? "..." : "Log In"}
                        </Button>
                        <Button
                            data-testid="submit-signup"
                            onClick={() => mode === "signup" ? handleAction() : setMode("signup")}
                            className={`w-full font-semibold h-8 text-xs transition-all ${mode === "signup"
                                ? "bg-primary hover:bg-primary/90 text-primary-foreground shadow-[0_0_20px_rgba(var(--primary),0.3)]"
                                : "bg-transparent border border-white/10 text-muted-foreground hover:bg-white/5"
                                }`}
                            disabled={loading}
                        >
                            {loading && mode === "signup" ? "..." : "Sign Up"}
                        </Button>
                    </div>

                    <div className="relative my-2">
                        <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-white/10"></span></div>
                        <div className="relative flex justify-center text-[10px] uppercase"><span className="bg-background px-2 text-muted-foreground">Or continue with</span></div>
                    </div>

                    <Button
                        variant="outline"
                        className="w-full border-white/10 bg-white/5 hover:bg-white/10 h-8 text-xs transition-all mb-2"
                        onClick={() => handleOAuthLogin('google')}
                        disabled={loading}
                    >
                        <svg className="mr-2 h-3 w-3" viewBox="0 0 24 24">
                            <path
                                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                                fill="#4285F4"
                            />
                            <path
                                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                                fill="#34A853"
                            />
                            <path
                                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.26.81-.58z"
                                fill="#FBBC05"
                            />
                            <path
                                d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                                fill="#EA4335"
                            />
                        </svg>
                        Google
                    </Button>

                    <div className="grid grid-cols-2 gap-2 mb-1">
                        <Button
                            variant="outline"
                            className="border-white/10 bg-white/5 hover:bg-white/10 h-8 text-xs transition-all font-semibold"
                            onClick={() => handleOAuthLogin('discord')}
                            disabled={loading}
                        >
                            <MessageSquare className="mr-1.5 h-3 w-3" /> Discord
                        </Button>
                        <Button
                            variant="outline"
                            className="border-white/10 bg-white/5 hover:bg-white/10 h-8 text-xs transition-all font-semibold"
                            onClick={() => handleOAuthLogin('github')}
                            disabled={loading}
                        >
                            <Github className="mr-1.5 h-3 w-3" /> GitHub
                        </Button>
                    </div>
                </div>

                <div className="flex justify-center mt-4">
                    <p className="text-[10px] text-muted-foreground flex items-center">
                        <Lock className="w-3 h-3 mr-1" /> Secured by Supabase
                    </p>
                </div>

                <div className="flex justify-center mt-3">
                    <Link
                        href="/auth-debug"
                        className="text-[10px] text-muted-foreground underline underline-offset-4 hover:text-primary transition-colors"
                    >
                        Trouble with mobile social login?
                    </Link>
                </div>
            </motion.div>
        </div>
    );
}
