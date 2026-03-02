"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";
import { ShieldAlert, UserCheck } from "lucide-react";

export function NicknameEnforcer({ children }: { children: React.ReactNode }) {
    const [isOpen, setIsOpen] = useState(false);
    const [nickname, setNickname] = useState("");
    const [loading, setLoading] = useState(false);
    const [user, setUser] = useState<any>(null);
    const supabase = createClient();

    useEffect(() => {
        const checkUser = async () => {
            const { data: { user } } = await supabase.auth.getUser();
            if (user) {
                setUser(user);
                // Check if user has a display_name in metadata or profiles
                const { data: profile } = await supabase
                    .from("profiles")
                    .select("display_name")
                    .eq("id", user.id)
                    .single();

                if (!profile?.display_name && !user.user_metadata?.display_name) {
                    setIsOpen(true);
                }
            }
        };

        checkUser();

        const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
            if (event === "SIGNED_IN") {
                checkUser();
            } else if (event === "SIGNED_OUT") {
                setUser(null);
                setIsOpen(false);
            }
        });

        return () => subscription.unsubscribe();
    }, []);

    const handleSetNickname = async () => {
        if (!nickname || nickname.length < 2) {
            toast.error("Nickname must be at least 2 characters.");
            return;
        }

        setLoading(true);
        try {
            // 1. Update Profile Table
            const { error: profileError } = await supabase
                .from("profiles")
                .upsert({
                    id: user.id,
                    display_name: nickname,
                    updated_at: new Date().toISOString(),
                });

            if (profileError) throw profileError;

            // 2. Update Auth Metadata
            const { error: authError } = await supabase.auth.updateUser({
                data: { display_name: nickname }
            });

            if (authError) throw authError;

            toast.success(`Welcome, ${nickname}! Profile secured.`);
            setIsOpen(false);
            window.location.reload(); // Refresh to update all UI
        } catch (error: any) {
            toast.error(error.message || "Failed to set nickname");
        } finally {
            setLoading(false);
        }
    };

    return (
        <>
            {children}
            <Dialog open={isOpen} onOpenChange={() => { }}>
                <DialogContent className="sm:max-w-md bg-zinc-950 border-white/10" onPointerDownOutside={(e) => e.preventDefault()}>
                    <DialogHeader>
                        <DialogTitle className="flex items-center gap-2 text-xl">
                            <ShieldAlert className="w-5 h-5 text-amber-500" />
                            Nickname Required
                        </DialogTitle>
                        <DialogDescription className="text-zinc-400">
                            To protect your privacy, please set a public nickname.
                            This prevents your email or real name from appearing on the leaderboard and social feed.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Input
                                placeholder="Enter your unique nickname"
                                value={nickname}
                                onChange={(e) => setNickname(e.target.value)}
                                className="bg-white/5 border-white/10 h-10"
                                autoFocus
                            />
                        </div>
                    </div>
                    <DialogFooter>
                        <Button
                            onClick={handleSetNickname}
                            disabled={loading}
                            className="w-full bg-primary hover:bg-primary/90"
                        >
                            {loading ? "Saving..." : "Create Profile"}
                            <UserCheck className="ml-2 h-4 w-4" />
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}
