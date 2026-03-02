"use client";

import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from "@/components/ui/dialog";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { MessageSquarePlus, Send } from "lucide-react";

export function FeedbackDialog({
    open,
    onOpenChange
}: {
    open: boolean;
    onOpenChange: (open: boolean) => void;
}) {
    const [email, setEmail] = useState("");
    const [category, setCategory] = useState("suggestion");
    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(false);
    const [user, setUser] = useState<any>(null);
    const supabase = createClient();

    useEffect(() => {
        const getUser = async () => {
            const { data: { user } } = await supabase.auth.getUser();
            if (user) {
                setUser(user);
                setEmail(user.email || "");
            }
        };
        getUser();
    }, []);

    const handleSubmit = async () => {
        if (!email || !message) {
            toast.error("Please fill in your email and message.");
            return;
        }

        if (message.length > 2000) {
            toast.error("Message is too long (max 2000 characters).");
            return;
        }

        setLoading(true);
        try {
            const { error } = await supabase
                .from("feedbacks")
                .insert({
                    user_id: user?.id || null,
                    email,
                    category,
                    message,
                });

            if (error) throw error;

            toast.success("Thank you! Your feedback has been received.");
            setMessage("");
            onOpenChange(false);
        } catch (error: any) {
            toast.error(error.message || "Failed to send feedback.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-md bg-zinc-950 border-white/10">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2 text-xl">
                        <MessageSquarePlus className="w-5 h-5 text-primary" />
                        Send Feedback
                    </DialogTitle>
                    <DialogDescription className="text-zinc-400">
                        Help us improve ChartClash. Report a bug or suggest a new feature.
                    </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 py-4">
                    <div className="space-y-2">
                        <label className="text-xs font-medium text-zinc-500 uppercase tracking-wider">Category</label>
                        <Select value={category} onValueChange={setCategory}>
                            <SelectTrigger className="bg-white/5 border-white/10">
                                <SelectValue placeholder="Select type" />
                            </SelectTrigger>
                            <SelectContent className="bg-zinc-900 border-white/10">
                                <SelectItem value="bug">🐛 Bug Report</SelectItem>
                                <SelectItem value="suggestion">💡 Suggestion</SelectItem>
                                <SelectItem value="other">❓ Other</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div className="space-y-2">
                        <label className="text-xs font-medium text-zinc-500 uppercase tracking-wider">Contact Email</label>
                        <Input
                            type="email"
                            placeholder="your@email.com"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            className="bg-white/5 border-white/10"
                        />
                    </div>
                    <div className="space-y-2">
                        <label className="text-xs font-medium text-zinc-500 uppercase tracking-wider">Message</label>
                        <Textarea
                            placeholder="What's on your mind? (max 2000 chars)"
                            value={message}
                            onChange={(e) => setMessage(e.target.value)}
                            className="bg-white/5 border-white/10 min-h-[120px] resize-none"
                        />
                    </div>
                </div>
                <DialogFooter>
                    <Button
                        onClick={handleSubmit}
                        disabled={loading}
                        className="w-full bg-primary hover:bg-primary/90"
                    >
                        {loading ? "Sending..." : "Submit Feedback"}
                        <Send className="ml-2 h-4 w-4" />
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
