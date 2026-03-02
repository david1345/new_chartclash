"use client";

import { useState, useEffect } from "react";
import { createBrowserClient } from "@supabase/ssr";
import { useMounted } from "@/hooks/use-mounted";
import { Bell, Check, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
// import { formatDistanceToNow } from "date-fns"; // Removed

function timeAgo(dateString: string) {
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (seconds < 60) return 'Just now';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
}

interface Notification {
    id: string;
    type: 'win' | 'loss' | 'streak' | 'rank' | 'info';
    title: string;
    message: string;
    points_change: number;
    is_read: boolean;
    created_at: string;
}

export function NotificationBell() {
    const [notifications, setNotifications] = useState<Notification[]>([]);
    const [unreadCount, setUnreadCount] = useState(0);
    const [isOpen, setIsOpen] = useState(false);
    const mounted = useMounted();

    // Use createBrowserClient for client-side usage with stable reference
    const [supabase] = useState(() => createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    ));

    const fetchNotifications = async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;

        // Ghost Mode logic
        const ghostId = typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null;
        const isImpersonating = ghostId && user.email === 'sjustone000@gmail.com';
        const targetId = isImpersonating ? ghostId : user.id;

        const { data, error } = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', targetId)
            .order('created_at', { ascending: false })
            .limit(20);

        if (data) {
            setNotifications(data as Notification[]);
            setUnreadCount(data.filter((n: any) => !n.is_read).length);
        }
    };

    const markAllRead = async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;

        // Ghost Mode logic
        const ghostId = typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null;
        const isImpersonating = ghostId && user.email === 'sjustone000@gmail.com';
        const targetId = isImpersonating ? ghostId : user.id;

        await supabase
            .from('notifications')
            .update({ is_read: true })
            .eq('user_id', targetId)
            .eq('is_read', false);

        setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
        setUnreadCount(0);
        setIsOpen(false);
    };

    useEffect(() => {
        fetchNotifications();

        const setupRealtime = async () => {
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) return;

            // Ghost Mode logic
            const ghostId = typeof window !== 'undefined' ? sessionStorage.getItem('ghost_target_id') : null;
            const isImpersonating = ghostId && user.email === 'sjustone000@gmail.com';
            const targetId = isImpersonating ? ghostId : user.id;

            const channel = supabase
                .channel(`notifications:${targetId}`)
                .on('postgres_changes', {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'notifications',
                    filter: `user_id=eq.${targetId}`
                }, (payload: any) => {
                    const newNotif = payload.new as Notification;
                    setNotifications(prev => [newNotif, ...prev]);
                    setUnreadCount(prev => prev + 1);
                })
                .subscribe();

            return () => { supabase.removeChannel(channel) };
        };

        setupRealtime();
    }, [supabase]);

    const unreadNotifications = notifications.filter(n => !n.is_read);
    const readNotifications = notifications.filter(n => n.is_read);

    return (
        <DropdownMenu open={isOpen} onOpenChange={setIsOpen}>
            <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="relative">
                    <Bell className="w-5 h-5 text-gray-400 hover:text-white transition-colors" />
                    {unreadCount > 0 && (
                        <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-pulse" />
                    )}
                </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-80 bg-[#0f1115] border-white/10 text-white">
                <div className="flex flex-row items-center justify-between px-2 py-1.5">
                    <DropdownMenuLabel className="p-0">Notifications</DropdownMenuLabel>
                    {unreadCount > 0 && (
                        <Button variant="ghost" size="sm" onClick={markAllRead} className="h-6 text-xs text-blue-400 hover:text-blue-300 px-2">
                            Mark all read
                        </Button>
                    )}
                </div>
                <DropdownMenuSeparator className="bg-white/10" />
                <ScrollArea className="h-[300px]">
                    {notifications.length === 0 ? (
                        <div className="p-4 text-center text-sm text-muted-foreground">
                            No notifications yet.
                        </div>
                    ) : (
                        <div className="p-2 space-y-1">
                            {/* Unread Section */}
                            {unreadNotifications.length > 0 && (
                                <>
                                    <div className="px-2 py-1 text-xs font-semibold text-muted-foreground uppercase">New</div>
                                    {unreadNotifications.map(n => (
                                        <NotificationItem key={n.id} notification={n} mounted={mounted} />
                                    ))}
                                    <div className="h-2" />
                                </>
                            )}

                            {/* Read Section */}
                            {readNotifications.length > 0 && (
                                <>
                                    <div className="px-2 py-1 text-xs font-semibold text-muted-foreground uppercase">Earlier</div>
                                    {readNotifications.map(n => (
                                        <NotificationItem key={n.id} notification={n} mounted={mounted} />
                                    ))}
                                </>
                            )}
                        </div>
                    )}
                </ScrollArea>
            </DropdownMenuContent>
        </DropdownMenu>
    );
}

function NotificationItem({ notification, mounted }: { notification: Notification, mounted: boolean }) {
    const isWin = notification.type === 'win';
    const isLoss = notification.type === 'loss';
    let icon = "🔔";
    if (isWin) icon = "✅";
    if (isLoss) icon = "❌";
    if (notification.type === 'streak') icon = "🔥";
    if (notification.type === 'rank') icon = "🏆";

    return (
        <div className={`flex gap-3 p-3 rounded-lg text-sm transition-colors ${notification.is_read ? 'opacity-60 hover:opacity-100 hover:bg-white/5' : 'bg-white/5 hover:bg-white/10 border-l-2 border-blue-500'}`}>
            <div className="text-lg mt-0.5">{icon}</div>
            <div className="flex-1 space-y-1">
                <div className="font-medium leading-none">
                    {notification.title}
                </div>
                <div className="text-xs text-muted-foreground leading-snug">
                    {notification.message}
                </div>
                <div className="text-[10px] text-gray-500 text-right">
                    {mounted ? timeAgo(notification.created_at) : "--"}
                </div>
            </div>
        </div>
    )
}
