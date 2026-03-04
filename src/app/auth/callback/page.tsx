"use client";

import { useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { Loader2 } from 'lucide-react';
import { toast } from 'sonner';

function AuthCallbackContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const supabase = createClient();

    useEffect(() => {
        let mounted = true;

        const handleCallback = async () => {
            const code = searchParams.get('code');
            const errorParam = searchParams.get('error');
            const next = searchParams.get('next') || '/play/BTCUSDT/1h';

            if (errorParam) {
                toast.error(`Authentication error: ${searchParams.get('error_description') || errorParam}`);
                router.replace("/login");
                return;
            }

            if (code) {
                // Exchange code for session using browser client
                const { error, data } = await supabase.auth.exchangeCodeForSession(code);

                if (error) {
                    console.error("Auth callback error:", error);
                    toast.error(`Failed to authenticate: ${error.message}`);
                    router.replace("/login");
                    return;
                }

                if (data?.session?.user && mounted) {
                    // Update user profile immediately
                    try {
                        const { user } = data.session;
                        await supabase.from('profiles').upsert({
                            id: user.id,
                            email: user.email,
                            username: user.email?.split('@')[0] || 'trader',
                            points: 1000
                        }, {
                            onConflict: 'id',
                            ignoreDuplicates: true
                        });
                    } catch (e) {
                        console.error("Profile upsert error", e);
                    }

                    // Client-side redirect ensures we stay on the same origin (e.g. 172.30.1.77)
                    router.replace(next);
                }
            } else {
                // No code and no error? Might be an implicit or fallback flow.
                // Often the session is just there in the hash or already established
                const { data: { session } } = await supabase.auth.getSession();
                if (session) {
                    router.replace(next);
                } else {
                    router.replace("/login");
                }
            }
        };

        handleCallback();

        return () => {
            mounted = false;
        };
    }, [router, searchParams, supabase]);

    return (
        <div className="flex h-screen w-full items-center justify-center bg-background">
            <div className="flex flex-col items-center gap-4">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
                <p className="text-sm font-medium text-muted-foreground animate-pulse">
                    Authenticating securely...
                </p>
            </div>
        </div>
    );
}

export default function AuthCallback() {
    return (
        <Suspense fallback={
            <div className="flex h-screen w-full items-center justify-center bg-background">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        }>
            <AuthCallbackContent />
        </Suspense>
    );
}
