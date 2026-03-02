"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/client";
import { motion } from "framer-motion";
import { Sparkles, TrendingUp, Lock, Github, MessageSquare } from "lucide-react";

import { toast } from "sonner";
import { DISPOSABLE_EMAIL_DOMAINS } from "@/lib/constants/disposable-domains";

export default function LoginPage() {
    const [mode, setMode] = useState<"login" | "signup">("login");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [nickname, setNickname] = useState("");
    const [loading, setLoading] = useState(false);
    const supabase = createClient();

    const handleGoogleLogin = async () => {
        setLoading(true);
        const { error } = await supabase.auth.signInWithOAuth({
            provider: 'google',
            options: {
                redirectTo: `${window.location.origin}/auth/callback`,
            },
        });
        if (error) {
            toast.error(error.message);
            setLoading(false);
        }
    };

    const handleAction = async () => {
        if (!email || !password) {
            toast.error("Please enter both email and password.");
            return;
        }

        if (mode === "signup" && !nickname) {
            toast.error("Please enter a nickname.");
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
            const isLengthMet = password.length >= 8;
            const isUpperMet = /[A-Z]/.test(password);
            const isNumberMet = /[0-9]/.test(password);
            const isSpecialMet = /[!@#$%^&*(),.?":{}|<>]/.test(password);

            if (!isLengthMet || !isUpperMet || !isNumberMet || !isSpecialMet) {
                toast.error("Password must include 8+ chars, uppercase, number, and special character.");
                return;
            }
        }

        setLoading(true);
        if (mode === "login") {
            const { error } = await supabase.auth.signInWithPassword({
                email,
                password,
            });
            if (error) {
                toast.error(error.message);
            } else {
                window.location.href = "/";
            }
        } else {
            const { error } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        display_name: nickname,
                    }
                }
            });
            if (error) {
                toast.error(error.message);
            } else {
                toast.success("Check your email for the confirmation link!");
            }
        }
        setLoading(false);
    };

    return (
        <div className="flex min-h-screen items-center justify-center bg-background p-4 relative overflow-hidden">
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
                <Card className="backdrop-blur-xl bg-card/60 border-white/10 shadow-2xl">
                    <CardHeader className="text-center space-y-2">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            className="mx-auto w-32 h-32 mb-4"
                        >
                            <img src="/logo-main.png" alt="ChartClash" className="w-full h-full object-contain" />
                        </motion.div>
                        <CardTitle className="text-3xl font-black tracking-tighter flex items-center justify-center gap-0">
                            <span className="text-blue-500">CHART</span>
                            <span className="text-orange-500">CLASH</span>
                        </CardTitle>
                        <CardDescription className="text-muted-foreground/80">
                            {mode === "login" ? "Welcome back! Please log in." : "Create a new account to start."}
                        </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Input
                                data-testid="email-input"
                                type="email"
                                placeholder="Email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                className="bg-black/20 border-white/10 focus:border-primary/50 focus:ring-primary/50 h-10 transition-all"
                            />
                            {mode === "signup" && (
                                <Input
                                    data-testid="nickname-input"
                                    type="text"
                                    placeholder="Nickname"
                                    value={nickname}
                                    onChange={(e) => setNickname(e.target.value)}
                                    className="bg-black/20 border-white/10 focus:border-primary/50 focus:ring-primary/50 h-10 transition-all"
                                />
                            )}
                            <Input
                                data-testid="password-input"
                                type="password"
                                placeholder="Password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="bg-black/20 border-white/10 focus:border-primary/50 focus:ring-primary/50 h-10 transition-all"
                            />

                            {mode === "signup" && (
                                <div className="space-y-1.5 pt-1 px-1">
                                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest mb-1">Security Standards</p>
                                    <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                                        {[
                                            { label: "8+ Characters", met: password.length >= 8 },
                                            { label: "Uppercase Letter", met: /[A-Z]/.test(password) },
                                            { label: "Number (0-9)", met: /[0-9]/.test(password) },
                                            { label: "Special (!@#$%^*)", met: /[!@#$%^&*(),.?":{}|<>]/.test(password) },
                                        ].map((rule, i) => (
                                            <div key={i} className="flex items-center gap-1.5">
                                                <div className={`w-1.5 h-1.5 rounded-full transition-colors ${rule.met ? "bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]" : "bg-white/20"}`} />
                                                <span className={`text-[10px] transition-colors ${rule.met ? "text-green-400 font-medium" : "text-muted-foreground"}`}>
                                                    {rule.label}
                                                </span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>

                        <div className="grid grid-cols-2 gap-3 pt-2">
                            <Button
                                data-testid="submit-login"
                                onClick={() => mode === "login" ? handleAction() : setMode("login")}
                                className={`w-full font-semibold transition-all ${mode === "login"
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
                                className={`w-full font-semibold transition-all ${mode === "signup"
                                    ? "bg-primary hover:bg-primary/90 text-primary-foreground shadow-[0_0_20px_rgba(var(--primary),0.3)]"
                                    : "bg-transparent border border-white/10 text-muted-foreground hover:bg-white/5"
                                    }`}
                                disabled={loading}
                            >
                                {loading && mode === "signup" ? "..." : "Sign Up"}
                            </Button>
                        </div>

                        <div className="relative my-4">
                            <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-white/10"></span></div>
                            <div className="relative flex justify-center text-xs uppercase"><span className="bg-background px-2 text-muted-foreground">Or continue with</span></div>
                        </div>

                        <Button
                            variant="outline"
                            className="w-full border-white/10 bg-white/5 hover:bg-white/10 h-10 transition-all mb-3"
                            onClick={handleGoogleLogin}
                            disabled={loading}
                        >
                            <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">
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

                        <div className="grid grid-cols-2 gap-3 mb-3">
                            <Button variant="outline" className="border-white/10 bg-white/5 opacity-50 cursor-not-allowed h-10">
                                <MessageSquare className="mr-2 h-4 w-4" /> Discord
                            </Button>
                            <Button variant="outline" className="border-white/10 bg-white/5 opacity-50 cursor-not-allowed h-10">
                                <Github className="mr-2 h-4 w-4" /> GitHub
                            </Button>
                        </div>

                        <Button variant="ghost" className="w-full border border-white/5 bg-white/5 hover:bg-white/10 h-10 opacity-50 cursor-not-allowed">
                            <Sparkles className="mr-2 h-4 w-4" /> Guest Access (Soon)
                        </Button>

                    </CardContent>
                    <CardFooter className="justify-center">
                        <p className="text-xs text-muted-foreground flex items-center">
                            <Lock className="w-3 h-3 mr-1" /> Secured by Supabase
                        </p>
                    </CardFooter>
                </Card>
            </motion.div>
        </div>
    );
}
