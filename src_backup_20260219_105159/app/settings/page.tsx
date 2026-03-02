"use client";

import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ArrowLeft, Settings, Moon, Bell, LogOut, Loader2 } from "lucide-react";
import Link from "next/link";
import { Switch } from "@/components/ui/switch";
import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";
import { toast } from "sonner";

export default function SettingsPage() {
    const [nickname, setNickname] = useState("");
    const [email, setEmail] = useState("");
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [user, setUser] = useState<any>(null);

    const supabase = createClient();

    useEffect(() => {
        const loadProfile = async () => {
            const { data: { user: realUser } } = await supabase.auth.getUser();
            if (realUser) {
                // Ghost Mode logic: if admin, check for impersonation
                const ghostId = typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null;
                const isImpersonating = ghostId && realUser.email === 'sjustone000@gmail.com';
                const targetId = isImpersonating ? ghostId : realUser.id;

                if (isImpersonating) {
                    console.log("👻 SETTINGS: GHOST MODE - Viewing profile for", targetId);
                }

                const { data: profile } = await supabase
                    .from('profiles')
                    .select('username, email')
                    .eq('id', targetId)
                    .maybeSingle();

                setUser(isImpersonating ? { id: targetId, email: profile?.email } : realUser);
                setEmail(profile?.email || realUser.email || "");
                setNickname(profile?.username || "");
            }
            setLoading(false);
        };
        loadProfile();
    }, []);

    const handleSave = async () => {
        if (!user) return;
        if (!nickname.trim()) {
            toast.error("Nickname cannot be empty");
            return;
        }

        setSaving(true);
        try {
            const { error } = await supabase
                .from('profiles')
                .update({ username: nickname.trim() })
                .eq('id', user.id);

            if (error) throw error;
            toast.success("Profile updated successfully");
        } catch (err: any) {
            toast.error(err.message || "Failed to save changes");
        } finally {
            setSaving(false);
        }
    };

    return (
        <div className="min-h-screen bg-[#050505] text-foreground font-sans selection:bg-primary/20 flex flex-col">
            {/* Header */}
            <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-background/60 backdrop-blur-xl">
                <div className="container mx-auto px-4 h-16 flex items-center gap-4">
                    <Link href="/">
                        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white">
                            <ArrowLeft className="w-5 h-5" />
                        </Button>
                    </Link>
                    <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">
                        <Settings className="w-5 h-5 text-muted-foreground" /> Settings
                    </h1>
                </div>
            </header>

            <div className="flex-1 container mx-auto px-4 py-8 space-y-6 max-w-2xl pb-20">

                {/* Profile */}
                <Card className="bg-card/10 border-white/5">
                    <CardHeader>
                        <CardTitle>Profile Settings</CardTitle>
                        <CardDescription>Manage your public profile information.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="nickname">Nickname</Label>
                            <Input
                                id="nickname"
                                placeholder="Enter your nickname"
                                className="bg-black/20"
                                value={nickname}
                                onChange={(e) => setNickname(e.target.value)}
                                disabled={loading}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="email">Email</Label>
                            <Input
                                id="email"
                                value={email}
                                disabled
                                className="bg-black/20 opacity-50"
                            />
                        </div>
                    </CardContent>
                    <CardFooter>
                        <Button onClick={handleSave} disabled={loading || saving}>
                            {saving ? (
                                <>
                                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                                    Saving...
                                </>
                            ) : "Save Changes"}
                        </Button>
                    </CardFooter>
                </Card>

                {/* Preferences */}
                <Card className="bg-card/10 border-white/5">
                    <CardHeader>
                        <CardTitle>App Preferences</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-6">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <Bell className="w-5 h-5 text-muted-foreground" />
                                <div>
                                    <div className="font-bold">Notifications</div>
                                    <p className="text-xs text-muted-foreground">Receive alerts for result resolution.</p>
                                </div>
                            </div>
                            <Switch defaultChecked />
                        </div>
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <Moon className="w-5 h-5 text-muted-foreground" />
                                <div>
                                    <div className="font-bold">Dark Mode</div>
                                    <p className="text-xs text-muted-foreground">Always on for ChartClash.</p>
                                </div>
                            </div>
                            <Switch defaultChecked disabled />
                        </div>
                    </CardContent>
                </Card>

                <div className="pt-4 space-y-3">
                    <Button
                        variant="ghost"
                        onClick={async () => {
                            const { createClient } = await import("@/lib/supabase/client");
                            const supabase = createClient();
                            if (typeof window !== 'undefined') {
                                sessionStorage.removeItem('ghost_target_id');
                            }
                            await supabase.auth.signOut();
                            window.location.href = "/login";
                        }}
                        className="w-full border border-white/5 bg-white/5 hover:bg-white/10 h-10"
                    >
                        <LogOut className="w-4 h-4 mr-2" /> Log Out
                    </Button>

                    <div className="pt-6 mt-6 border-t border-red-500/20">
                        <h3 className="text-red-500 font-bold mb-2 flex items-center gap-2">
                            Danger Zone
                        </h3>
                        <p className="text-xs text-muted-foreground mb-4">
                            Permanently delete your account and all associated data. This action is irreversible.
                        </p>
                        <Button
                            variant="destructive"
                            className="w-full bg-red-500/10 border border-red-500/20 text-red-500 hover:bg-red-500 hover:text-white transition-all"
                            onClick={async () => {
                                if (confirm("DESTRUCTIVE ACTION: Are you absolutely sure you want to delete your account? All points and history will be lost forever.")) {
                                    try {
                                        const res = await fetch('/api/user/delete', { method: 'POST' });
                                        if (res.ok) {
                                            window.location.href = "/login";
                                        } else {
                                            const data = await res.json();
                                            alert(data.error || "Failed to delete account");
                                        }
                                    } catch (err) {
                                        alert("An error occurred. Please try again.");
                                    }
                                }
                            }}
                        >
                            Delete My Account
                        </Button>
                    </div>
                </div>

            </div>
        </div>
    );
}
