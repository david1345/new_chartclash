"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { ArrowLeft, RefreshCw, Trash2, Search, Save, Settings, AlertCircle, Eye, Power, Ghost, Activity, Users, TrendingUp, DollarSign, BarChart3 } from "lucide-react";
import { toast } from "sonner";
import dayjs from "dayjs";

// 🛡️ Helper to get Zone status (Cloned from match-history)
const getZoneInfo = (pred: any) => {
    let tfSeconds = 900;
    const tf = pred.timeframe || '15m';
    if (tf === '1m') tfSeconds = 60;
    else if (tf === '5m') tfSeconds = 300;
    else if (tf === '15m') tfSeconds = 900;
    else if (tf === '30m') tfSeconds = 1800;
    else if (tf.includes('h')) tfSeconds = parseInt(tf) * 3600;
    else if (tf.includes('d')) tfSeconds = 86400;

    const created = new Date(pred.created_at).getTime() / 1000;
    const candleClose = pred.candle_close_at ? new Date(pred.candle_close_at).getTime() / 1000 : created + tfSeconds;
    const ratio = (created - (candleClose - tfSeconds)) / tfSeconds;

    if (ratio < 0.33) return { label: "GREEN", color: "text-emerald-400", border: "border-emerald-500/50", bg: "bg-emerald-500/5" };
    if (ratio < 0.66) return { label: "YELLOW", color: "text-amber-400", border: "border-amber-500/50", bg: "bg-amber-500/5" };
    return { label: "RED", color: "text-rose-400", border: "border-rose-500/50", bg: "bg-rose-500/5" };
};

export default function AdminDashboard() {
    const supabase = createClient();

    // Auth State
    const [isAuthorized, setIsAuthorized] = useState(false);
    const [password, setPassword] = useState("");

    // Dashboard State
    const [stats, setStats] = useState({
        totalUsers: 0,
        totalPredictions: 0,
        pendingPredictions: 0,
        totalPointsInCirculation: 0,
        winRate: 0,
        activeNow: 0
    });

    const [recentPredictions, setRecentPredictions] = useState<any[]>([]);
    const [topUsers, setTopUsers] = useState<any[]>([]);
    const [searchTerm, setSearchTerm] = useState("");
    const [selectedUserForView, setSelectedUserForView] = useState<any>(null);
    const [userPredictions, setUserPredictions] = useState<any[]>([]);
    const [feedbacks, setFeedbacks] = useState<any[]>([]);
    const [systemHealth, setSystemHealth] = useState<any>({});
    const [isLoading, setIsLoading] = useState(false);
    const [isProfileLoading, setIsProfileLoading] = useState(false);

    // Pagination State
    const [usersPage, setUsersPage] = useState(1);
    const [predsPage, setPredsPage] = useState(1);
    const [totalUsersCount, setTotalUsersCount] = useState(0);
    const [totalPredsCount, setTotalPredsCount] = useState(0);
    const [isFullTableOpen, setIsFullTableOpen] = useState(false);
    const PAGE_SIZE = 20;

    const ADMIN_PASSWORD = 'clash-control-999';

    // Initial Auth Check
    useEffect(() => {
        const verifyAdmin = async () => {
            console.log("🔍 ADMIN_DEBUG: Starting verifyAdmin...");
            const { data: { user } } = await supabase.auth.getUser();
            console.log("🔍 ADMIN_DEBUG: Supabase User:", user?.email || "No User");

            if (!user || user.email !== 'sjustone000@gmail.com') {
                console.warn("⚠️ ADMIN_DEBUG: Unauthorized email attempt:", user?.email);
                localStorage.removeItem('admin_auth');
                // Don't redirect immediately to allow debug check if needed, but safe to keep
                return;
            }

            const adminPass = localStorage.getItem('admin_auth');
            console.log("🔍 ADMIN_DEBUG: localStorage password found:", adminPass ? "YES" : "NO");

            if (adminPass === ADMIN_PASSWORD) {
                console.log("✅ ADMIN_DEBUG: Authorized via localStorage");
                setIsAuthorized(true);
                fetchAllData();
            } else if (adminPass) {
                console.warn("❌ ADMIN_DEBUG: localStorage password MISMATCH or OUTDATED");
            }
        };
        verifyAdmin();
    }, []);

    // Polling Effect (only when authorized)
    useEffect(() => {
        if (!isAuthorized) return;

        // Initial fetch if not already done by auth check (handled by separate call usually, but safe to call here)
        if (stats.totalUsers === 0) fetchAllData();

        // 30초마다 자동 새로고침
        const interval = setInterval(fetchAllData, 30000);
        return () => clearInterval(interval);
    }, [isAuthorized]);

    const handleLogin = () => {
        console.log("🚀 ADMIN_DEBUG: Login attempt started");
        console.log("🚀 ADMIN_DEBUG: Entered password:", `[${password}]`);
        console.log("🚀 ADMIN_DEBUG: Expected password:", `[${ADMIN_PASSWORD}]`);
        console.log("🚀 ADMIN_DEBUG: Length check - Entered:", password.length, "Expected:", ADMIN_PASSWORD.length);

        if (password === ADMIN_PASSWORD) {
            console.log("✅ ADMIN_DEBUG: Password match SUCCESS");
            localStorage.setItem('admin_auth', password);
            setIsAuthorized(true);
            toast.success("Welcome back, Admin");
            fetchAllData();
        } else {
            console.error("❌ ADMIN_DEBUG: Password match FAILED");
            toast.error('Invalid password');
        }
    };

    const fetchAllData = async () => {
        setIsLoading(true);
        await Promise.all([
            fetchStats(),
            fetchRecentPredictions(),
            fetchTopUsers(),
            fetchFeedbacks(),
            checkSystemHealth()
        ]);
        setIsLoading(false);
    };

    // Refetch when page changes
    useEffect(() => {
        if (isAuthorized) fetchRecentPredictions();
    }, [predsPage, isAuthorized]);

    useEffect(() => {
        if (isAuthorized) fetchTopUsers();
    }, [usersPage, isAuthorized]);

    const fetchStats = async () => {
        // 전체 사용자 수
        const { count: userCount } = await supabase
            .from('profiles')
            .select('*', { count: 'exact', head: true });

        // 전체 예측 수
        const { count: predCount } = await supabase
            .from('predictions')
            .select('*', { count: 'exact', head: true });

        // Pending 예측 수
        const { count: pendingCount } = await supabase
            .from('predictions')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'pending');

        // 총 포인트
        const { data: pointsData } = await supabase
            .from('profiles')
            .select('points');
        const totalPoints = pointsData?.reduce((sum, u) => sum + (u.points || 0), 0) || 0;

        // 승률 계산
        const { data: resolved } = await supabase
            .from('predictions')
            .select('status')
            .in('status', ['WIN', 'LOSS']);

        const wins = resolved?.filter(p => p.status === 'WIN').length || 0;
        const total = resolved?.length || 1;
        const winRate = (wins / total) * 100;

        // 최근 활동 사용자 (1시간 내)
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
        const { count: activeCount } = await supabase
            .from('predictions')
            .select('user_id', { count: 'exact', head: true })
            .gte('created_at', oneHourAgo);

        setStats({
            totalUsers: userCount || 0,
            totalPredictions: predCount || 0,
            pendingPredictions: pendingCount || 0,
            totalPointsInCirculation: totalPoints,
            winRate: winRate,
            activeNow: activeCount || 0
        });
    };

    const fetchRecentPredictions = async () => {
        const from = (predsPage - 1) * PAGE_SIZE;
        const to = from + PAGE_SIZE - 1;

        const { data, count } = await supabase
            .from('predictions')
            .select(`
        *,
        profiles (username, email, streak_count)
      `, { count: 'exact' })
            .order('created_at', { ascending: false })
            .range(from, to);

        setRecentPredictions(data || []);
        if (count !== null) setTotalPredsCount(count);
    };

    const fetchTopUsers = async () => {
        setIsLoading(true);
        try {
            const term = searchTerm.trim();
            const from = (usersPage - 1) * PAGE_SIZE;
            const to = from + PAGE_SIZE - 1;

            let query = supabase
                .from('profiles')
                .select('id, username, email, points, tier, total_games, total_wins', { count: 'exact' });

            if (term) {
                const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[0-89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(term);
                if (isUuid) {
                    query = query.eq('id', term);
                } else if (term.includes('@')) {
                    query = query.ilike('email', `%${term}%`);
                } else {
                    query = query.ilike('username', `%${term}%`);
                }
                // When searching, sort by points or keep original? 
                // Request said "User List: Sort alphabetically by default"
                query = query.order('username', { ascending: true });
            } else {
                // Default: Alphabetical
                query = query.order('username', { ascending: true });
            }

            const { data: profiles, error: pError, count } = await query.range(from, to);

            if (pError) throw new Error(pError.message);

            setTopUsers(profiles || []);
            if (count !== null) setTotalUsersCount(count);
        } catch (err: any) {
            console.error("❌ ADMIN_DEBUG: Global catch error:", err);
            toast.error("Failed to search: " + err.message);
        } finally {
            setIsLoading(false);
        }
    };

    const fetchAllUsersDetailed = async () => {
        setIsLoading(true);
        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('id, username, email, points, tier, total_games, total_wins, created_at')
                .order('points', { ascending: false })
                .limit(1000); // Increased for "Full" view

            if (error) throw error;
            setTopUsers(data || []);
            toast.success("Detailed user directory loaded (Top 1000)");
        } catch (err: any) {
            toast.error("Failed to fetch full list: " + err.message);
        } finally {
            setIsLoading(false);
        }
    };

    const fetchFeedbacks = async () => {
        const { data } = await supabase
            .from('feedbacks')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(50);

        setFeedbacks(data || []);
    };

    const checkSystemHealth = async () => {
        try {
            // API 응답 테스트
            const start = Date.now();
            const res = await fetch('/api/cron/resolve'); // Use the actual cron endpoint we made
            const latency = Date.now() - start;

            // Even if it returns 200, we check latency
            setSystemHealth({
                apiStatus: res.ok ? 'healthy' : 'error',
                latency: latency,
                lastCheck: new Date().toISOString()
            });
        } catch (err) {
            setSystemHealth({
                apiStatus: 'error',
                latency: 0,
                lastCheck: new Date().toISOString()
            });
        }
    };

    const handleForceResolve = async () => {
        try {
            const res = await fetch('/api/cron/resolve');
            const data = await res.json();

            if (res.ok) {
                toast.success(`Force resolve triggered. Message: ${data.message || 'Done'}`);
                fetchAllData();
            } else {
                toast.error('Resolution failed: ' + data.error);
            }
        } catch (err) {
            toast.error('Error calling resolve API');
        }
    };

    const handleResetUser = async (userId: string) => {
        if (!confirm('Reset user points to 1000?')) return;

        const { error } = await supabase
            .from('profiles')
            .update({ points: 1000 })
            .eq('id', userId);

        if (!error) {
            toast.success('User reset successfully');
            fetchAllData();
        } else {
            toast.error('Reset failed');
        }
    };

    // Auth Screen
    if (!isAuthorized) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center p-4">
                <Card className="w-full max-w-md bg-gray-900 border-gray-800 text-white">
                    <CardHeader>
                        <CardTitle className="text-center">Admin Access</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <Input
                            type="password"
                            placeholder="Enter admin password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            onKeyPress={(e) => e.key === 'Enter' && handleLogin()}
                            className="bg-gray-800 border-gray-700 text-white"
                        />
                        <Button onClick={handleLogin} className="w-full">
                            Login
                        </Button>
                    </CardContent>
                </Card>
            </div>
        );
    }

    // Dashboard Screen
    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-black text-white p-8">
            <div className="max-w-7xl mx-auto space-y-6">

                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-3xl font-bold">Admin Dashboard</h1>
                        <p className="text-gray-400">Service monitoring & management</p>
                    </div>
                    <div className="flex gap-2">
                        <Button
                            variant="outline"
                            onClick={fetchAllData}
                            disabled={isLoading}
                            className="bg-transparent border-gray-600 hover:bg-white/10"
                        >
                            <RefreshCw className={`w-4 h-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
                            Refresh
                        </Button>
                        <Button onClick={handleForceResolve} className="bg-yellow-600 hover:bg-yellow-700">
                            <RefreshCw className="w-4 h-4 mr-2" />
                            Force Resolve
                        </Button>
                        <Button
                            variant="destructive"
                            onClick={() => {
                                localStorage.removeItem('admin_auth');
                                setIsAuthorized(false);
                            }}
                        >
                            Logout
                        </Button>
                    </div>
                </div>

                {/* System Health */}
                <Card className="bg-white/5 border-white/10 text-white">
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Activity className="w-5 h-5 text-green-400" />
                            System Health
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="grid grid-cols-3 gap-4">
                            <div>
                                <p className="text-sm text-gray-400">API Status</p>
                                <Badge variant={systemHealth.apiStatus === 'healthy' ? 'default' : 'destructive'} className={systemHealth.apiStatus === 'healthy' ? "bg-green-600" : "bg-red-600"}>
                                    {systemHealth.apiStatus || 'Unknown'}
                                </Badge>
                            </div>
                            <div>
                                <p className="text-sm text-gray-400">API Latency</p>
                                <p className={`text-2xl font-bold ${systemHealth.latency > 1000 ? 'text-red-400' : 'text-green-400'}`}>
                                    {systemHealth.latency ? `${systemHealth.latency}ms` : '-'}
                                </p>
                            </div>
                            <div>
                                <p className="text-sm text-gray-400">Last Check</p>
                                <p className="text-sm">{systemHealth.lastCheck ? new Date(systemHealth.lastCheck).toLocaleTimeString() : '-'}</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                {/* Key Metrics */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <Card className="bg-white/5 border-white/10 text-white">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm flex items-center gap-2">
                                <Users className="w-4 h-4" />
                                Total Users
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-3xl font-bold">{stats.totalUsers}</p>
                            <p className="text-xs text-gray-400">{stats.activeNow} active in last 1h</p>
                        </CardContent>
                    </Card>

                    <Card className="bg-white/5 border-white/10 text-white">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm flex items-center gap-2">
                                <BarChart3 className="w-4 h-4" />
                                Total Predictions
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-3xl font-bold">{stats.totalPredictions}</p>
                            <p className="text-xs text-yellow-400">{stats.pendingPredictions} pending</p>
                        </CardContent>
                    </Card>

                    <Card className="bg-white/5 border-white/10 text-white">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm flex items-center gap-2">
                                <TrendingUp className="w-4 h-4" />
                                Win Rate
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-3xl font-bold">{isNaN(stats.winRate) ? '0.0' : stats.winRate.toFixed(1)}%</p>
                            <p className="text-xs text-gray-400">Platform average</p>
                        </CardContent>
                    </Card>

                    <Card className="bg-white/5 border-white/10 text-white">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm flex items-center gap-2">
                                <DollarSign className="w-4 h-4" />
                                Total Points
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-3xl font-bold">{stats.totalPointsInCirculation.toLocaleString()}</p>
                            <p className="text-xs text-gray-400">In circulation</p>
                        </CardContent>
                    </Card>
                </div>

                {/* Tabs */}
                <Tabs defaultValue="predictions" className="space-y-4">
                    <TabsList className="bg-white/10 text-white">
                        <TabsTrigger value="predictions">Recent Predictions</TabsTrigger>
                        <TabsTrigger value="users">Top Users</TabsTrigger>
                        <TabsTrigger value="feedbacks">Feedbacks</TabsTrigger>
                        <TabsTrigger value="alerts">Alerts</TabsTrigger>
                    </TabsList>

                    {/* Recent Predictions Tab */}
                    <TabsContent value="predictions">
                        <Card className="bg-white/5 border-white/10 text-white">
                            <CardHeader>
                                <CardTitle>Recent Predictions (by Nickname)</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="overflow-x-auto">
                                    <table className="w-full text-sm text-left">
                                        <thead className="text-xs text-muted-foreground uppercase bg-white/5 border-b border-white/5">
                                            <tr>
                                                <th className="px-6 py-3">Time</th>
                                                <th className="px-6 py-3">User / Asset</th>
                                                <th className="px-6 py-3 text-center">Streak</th>
                                                <th className="px-6 py-3">Pick</th>
                                                <th className="px-6 py-3 text-right">Target</th>
                                                <th className="px-6 py-3 text-right">Result</th>
                                                <th className="px-6 py-3 text-right">Points</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-white/5">
                                            {recentPredictions.map((pred) => (
                                                <AdminHistoryRow key={pred.id} pred={pred} />
                                            ))}
                                        </tbody>
                                    </table>
                                    {recentPredictions.length === 0 && (
                                        <div className="text-center text-muted-foreground py-12">
                                            <Activity className="w-12 h-12 mx-auto mb-4 opacity-10" />
                                            <p className="text-lg font-medium">No recent predictions found.</p>
                                        </div>
                                    )}
                                </div>

                                {/* Pagination for Predictions */}
                                <div className="flex items-center justify-between pt-4 border-t border-white/5 mt-4">
                                    <p className="text-xs text-gray-500">
                                        Page {predsPage} of {Math.ceil(totalPredsCount / PAGE_SIZE)} ({totalPredsCount} total)
                                    </p>
                                    <div className="flex gap-2">
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            disabled={predsPage <= 1}
                                            onClick={() => setPredsPage(p => p - 1)}
                                            className="h-8 bg-transparent border-white/10"
                                        >
                                            Prev
                                        </Button>
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            disabled={predsPage >= Math.ceil(totalPredsCount / PAGE_SIZE)}
                                            onClick={() => setPredsPage(p => p + 1)}
                                            className="h-8 bg-transparent border-white/10"
                                        >
                                            Next
                                        </Button>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Feedbacks Tab */}
                    <TabsContent value="feedbacks">
                        <Card className="bg-white/5 border-white/10 text-white">
                            <CardHeader>
                                <CardTitle>User Feedbacks</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-4">
                                    {feedbacks.map((f) => (
                                        <div key={f.id} className="p-4 bg-white/5 rounded-lg border border-white/10 space-y-2">
                                            <div className="flex items-center justify-between">
                                                <div className="flex items-center gap-2">
                                                    <Badge variant="outline" className={
                                                        f.category === 'bug' ? "border-red-500 text-red-400" :
                                                            f.category === 'suggestion' ? "border-emerald-500 text-emerald-400" : "border-zinc-500 text-zinc-400"
                                                    }>
                                                        {f.category}
                                                    </Badge>
                                                    <span className="text-xs font-mono text-zinc-400">{f.email}</span>
                                                </div>
                                                <span className="text-[10px] text-zinc-500">
                                                    {new Date(f.created_at).toLocaleString()}
                                                </span>
                                            </div>
                                            <p className="text-sm text-zinc-200 leading-relaxed italic">
                                                "{f.message}"
                                            </p>
                                        </div>
                                    ))}
                                    {feedbacks.length === 0 && (
                                        <div className="text-center text-gray-500 py-8">No feedback received yet.</div>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Top Users Tab */}
                    <TabsContent value="users">
                        <Card className="bg-white/5 border-white/10 text-white">
                            <CardHeader className="flex flex-row items-center justify-between">
                                <CardTitle>User Search & Ranking</CardTitle>
                                <div className="flex items-center gap-2">
                                    <div className="relative w-64">
                                        <Search className="absolute left-2 top-2.5 h-4 w-4 text-gray-500" />
                                        <Input
                                            placeholder="Nickname, Email or ID..."
                                            value={searchTerm}
                                            onChange={(e) => setSearchTerm(e.target.value)}
                                            onKeyPress={(e) => e.key === 'Enter' && fetchTopUsers()}
                                            className="pl-8 h-9 bg-black/40 border-white/10"
                                        />
                                    </div>
                                    <Button size="sm" onClick={fetchTopUsers} disabled={isLoading}>
                                        Search
                                    </Button>
                                    <Button size="sm" variant="outline" onClick={() => {
                                        fetchAllUsersDetailed();
                                        setIsFullTableOpen(true);
                                    }} className="bg-indigo-500/10 border-indigo-500/20 text-indigo-400 hover:bg-indigo-500/20">
                                        View Full Detailed Table
                                    </Button>
                                </div>
                            </CardHeader>
                            <CardContent>
                                <Dialog open={isFullTableOpen} onOpenChange={setIsFullTableOpen}>
                                    <DialogContent className="max-w-5xl bg-[#0f1115] border-white/10 text-white max-h-[80vh] flex flex-col">
                                        <DialogHeader>
                                            <DialogTitle className="text-xl flex items-center gap-2">
                                                <Users className="w-5 h-5 text-indigo-400" />
                                                Master User Registry & Performance Analysis
                                            </DialogTitle>
                                        </DialogHeader>
                                        <div className="flex-1 overflow-auto mt-4 border border-indigo-500/10 rounded-xl bg-black/40 backdrop-blur-md">
                                            <table className="w-full text-xs text-left border-collapse">
                                                <thead className="sticky top-0 bg-[#1a1d24] text-zinc-400 border-b border-white/10 z-10">
                                                    <tr>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px]">Rank</th>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px]">User Identifier</th>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px]">Point Balance</th>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px]">Accuracy (Win Rate)</th>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px]">Activity</th>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px]">Joined Date</th>
                                                        <th className="p-4 font-semibold uppercase tracking-wider text-[10px] text-right">Actions</th>
                                                    </tr>
                                                </thead>
                                                <tbody className="divide-y divide-white/5">
                                                    {topUsers.map((user, idx) => {
                                                        const winRate = user.total_games > 0 ? ((user.total_wins / user.total_games) * 100).toFixed(1) : '0';
                                                        return (
                                                            <tr key={user.id} className="hover:bg-indigo-500/5 transition-colors border-b border-white/5 last:border-0">
                                                                <td className="p-4 font-mono text-indigo-400 text-sm">#{(usersPage - 1) * PAGE_SIZE + idx + 1}</td>
                                                                <td className="p-4">
                                                                    <div className="flex flex-col">
                                                                        <span className="font-bold text-zinc-100 text-sm">{user.username || 'Anonymous'}</span>
                                                                        <span className="text-[10px] text-zinc-500 font-mono font-normal truncate max-w-[180px]">{user.email}</span>
                                                                    </div>
                                                                </td>
                                                                <td className="p-4">
                                                                    <span className="text-amber-500 font-bold text-sm">
                                                                        {user.points.toLocaleString()}
                                                                        <span className="text-[10px] ml-1 opacity-50 font-normal">pts</span>
                                                                    </span>
                                                                </td>
                                                                <td className="p-4">
                                                                    <div className="flex items-center gap-2">
                                                                        <div className="w-12 bg-white/5 h-1.5 rounded-full overflow-hidden">
                                                                            <div
                                                                                className={cn("h-full rounded-full", Number(winRate) >= 50 ? "bg-green-500" : "bg-zinc-600")}
                                                                                style={{ width: `${winRate}%` }}
                                                                            />
                                                                        </div>
                                                                        <span className={cn("font-bold", Number(winRate) >= 50 ? "text-green-400" : "text-zinc-400")}>
                                                                            {winRate}%
                                                                        </span>
                                                                    </div>
                                                                </td>
                                                                <td className="p-4">
                                                                    <div className="flex items-center gap-2 text-zinc-300">
                                                                        <Activity className="w-3 h-3 opacity-50" />
                                                                        <span>{user.total_games || 0} Games</span>
                                                                    </div>
                                                                </td>
                                                                <td className="p-4 text-zinc-500 text-[11px] font-mono">
                                                                    {user.created_at ? new Date(user.created_at).toLocaleDateString('en-GB') : '-'}
                                                                </td>
                                                                <td className="p-4 text-right">
                                                                    <div className="flex justify-end gap-2">
                                                                        <Button
                                                                            size="icon"
                                                                            variant="ghost"
                                                                            className="h-8 w-8 hover:bg-purple-500/20 text-purple-400"
                                                                            onClick={() => window.open(`/?impersonate=${user.id}`, '_blank')}
                                                                            title="View as User"
                                                                        >
                                                                            <Ghost className="w-4 h-4" />
                                                                        </Button>
                                                                        <Button
                                                                            size="icon"
                                                                            variant="ghost"
                                                                            className="h-8 w-8 hover:bg-red-500/20 text-red-400"
                                                                            onClick={() => handleResetUser(user.id)}
                                                                            title="Reset Points"
                                                                        >
                                                                            <RefreshCw className="w-4 h-4" />
                                                                        </Button>
                                                                    </div>
                                                                </td>
                                                            </tr>
                                                        );
                                                    })}
                                                </tbody>
                                            </table>
                                        </div>
                                        <div className="pt-4 flex justify-between items-center text-xs text-zinc-500">
                                            <div className="flex items-center gap-4">
                                                <span>Total Records: {topUsers.length}</span>
                                                <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-green-500" /> High Accuracy</span>
                                            </div>
                                            <div className="flex gap-2">
                                                <Button size="sm" onClick={() => window.print()} variant="outline" className="h-8 border-white/10 hover:bg-white/5">
                                                    Export PDF / Print
                                                </Button>
                                                <Button size="sm" onClick={() => setIsFullTableOpen(false)} variant="default" className="h-8 bg-indigo-600">
                                                    Close Directory
                                                </Button>
                                            </div>
                                        </div>
                                    </DialogContent>
                                </Dialog>

                                <ScrollArea className="h-[500px] pr-4">
                                    <div className="space-y-2">
                                        {topUsers.map((user, idx) => (
                                            <div key={user.id} className="flex items-center justify-between p-3 bg-white/5 rounded-lg border border-white/5">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center font-bold text-black shadow-lg text-xs">
                                                        {(usersPage - 1) * PAGE_SIZE + idx + 1}
                                                    </div>
                                                    <div>
                                                        <p className="font-bold">{user.username || 'Anonymous'}</p>
                                                        <p className="text-xs text-gray-400">{user.email}</p>
                                                    </div>
                                                </div>
                                                <div className="text-right flex items-center gap-2">
                                                    <div>
                                                        <p className="text-xl font-bold text-yellow-500">{user.points.toLocaleString()}</p>
                                                    </div>
                                                    <div className="flex gap-1">
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            onClick={() => window.open(`/?impersonate=${user.id}`, '_blank')}
                                                            className="hover:bg-purple-500/20 text-purple-400 hover:text-purple-300"
                                                            title="Ghost Mode (Full View)"
                                                        >
                                                            <Ghost className="w-4 h-4" />
                                                        </Button>
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            onClick={() => handleResetUser(user.id)}
                                                            className="hover:bg-red-500/20 text-red-400 hover:text-red-300"
                                                        >
                                                            Reset
                                                        </Button>
                                                    </div>
                                                </div>
                                            </div>
                                        ))}

                                        {/* Pagination for Users */}
                                        <div className="flex items-center justify-between pt-4 border-t border-white/5 mt-2">
                                            <p className="text-xs text-gray-500">
                                                Page {usersPage} of {Math.ceil(totalUsersCount / PAGE_SIZE)} ({totalUsersCount} total)
                                            </p>
                                            <div className="flex gap-2">
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={usersPage <= 1}
                                                    onClick={() => setUsersPage(p => p - 1)}
                                                    className="h-8 bg-transparent border-white/10"
                                                >
                                                    Prev
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={usersPage >= Math.ceil(totalUsersCount / PAGE_SIZE)}
                                                    onClick={() => setUsersPage(p => p + 1)}
                                                    className="h-8 bg-transparent border-white/10"
                                                >
                                                    Next
                                                </Button>
                                            </div>
                                        </div>
                                    </div>
                                </ScrollArea>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Alerts Tab */}
                    <TabsContent value="alerts">
                        <Card className="bg-white/5 border-white/10 text-white">
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <AlertCircle className="w-5 h-5" />
                                    System Alerts
                                </CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-2">
                                    {stats.pendingPredictions > 50 && (
                                        <div className="p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
                                            <p className="font-bold text-yellow-500">High Pending Count</p>
                                            <p className="text-sm text-gray-400">{stats.pendingPredictions} predictions waiting for resolution</p>
                                        </div>
                                    )}

                                    {systemHealth.apiStatus === 'error' && (
                                        <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
                                            <p className="font-bold text-red-500">API Error</p>
                                            <p className="text-sm text-gray-400">Resolve API is not responding</p>
                                        </div>
                                    )}

                                    {systemHealth.latency > 1000 && (
                                        <div className="p-3 bg-orange-500/10 border border-orange-500/30 rounded-lg">
                                            <p className="font-bold text-orange-500">Slow Response</p>
                                            <p className="text-sm text-gray-400">API latency is {systemHealth.latency}ms</p>
                                        </div>
                                    )}

                                    {stats.pendingPredictions === 0 && systemHealth.apiStatus === 'healthy' && (
                                        <div className="p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
                                            <p className="font-bold text-green-500">All Systems Operational</p>
                                            <p className="text-sm text-gray-400">No issues detected</p>
                                        </div>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>
                </Tabs>

            </div >
        </div >
    );
}

function AdminHistoryRow({ pred }: { pred: any }) {
    const [isOpen, setIsOpen] = useState(false);

    const entry = pred.entry_price || 0;
    const close = pred.close_price || pred.actual_price || 0;
    const changePct = pred.actual_change_percent ?? (entry > 0 && close > 0 ? ((close - entry) / entry) * 100 : 0);
    const isTargetHit = pred.is_target_hit ?? (Math.abs(changePct) >= pred.target_percent);
    const directionCorrect = (pred.direction === 'UP' && close > entry) || (pred.direction === 'DOWN' && close < entry);
    const profitValue = pred.profit ?? pred.profit_loss ?? 0;
    const isPending = pred.status === 'pending';

    return (
        <>
            <tr
                onClick={() => setIsOpen(!isOpen)}
                className={cn(
                    "hover:bg-white/5 transition-colors cursor-pointer group",
                    isOpen ? "bg-white/5" : ""
                )}
            >
                <td className="px-6 py-4 text-muted-foreground whitespace-nowrap">
                    {dayjs(pred.created_at).format('MM/DD h:mm A')}
                </td>
                <td className="px-6 py-4">
                    <div className="flex flex-col">
                        <span className="font-bold text-white text-sm">{pred.profiles?.username || 'Unknown'}</span>
                        <div className="flex items-center gap-2 mt-1">
                            <Badge variant="outline" className={cn(
                                "text-[10px] min-w-[35px] justify-center border-2",
                                getZoneInfo(pred).color,
                                getZoneInfo(pred).border,
                                getZoneInfo(pred).bg
                            )}>{pred.timeframe}</Badge>
                            <span className="text-xs text-muted-foreground">{pred.asset_symbol}</span>
                        </div>
                    </div>
                </td>
                <td className="px-6 py-4 text-center">
                    {/* For Admin, show current user streak if possible or just - */}
                    {pred.profiles?.streak_count > 0 ? (
                        <div className="flex items-center justify-center gap-1 text-orange-500 font-bold">
                            <span>🔥</span>
                            <span>{pred.profiles.streak_count}</span>
                        </div>
                    ) : (
                        <span className="text-muted-foreground/30 font-mono">-</span>
                    )}
                </td>
                <td className="px-6 py-4">
                    <Badge variant="outline" className={cn(
                        "border-none font-bold",
                        pred.direction === 'UP' ? "bg-emerald-500/20 text-emerald-500" : "bg-red-500/20 text-red-500"
                    )}>
                        {pred.direction}
                    </Badge>
                </td>
                <td className="px-6 py-4 text-right">
                    {pred.target_percent}%
                </td>
                <td className="px-6 py-4 text-right">
                    <Badge variant="outline" className={cn(
                        "text-[10px] px-2 py-0.5 h-5 uppercase inline-flex",
                        pred.status === 'WIN' ? "border-emerald-500/50 text-emerald-500 bg-emerald-500/10" :
                            pred.status === 'LOSS' ? "border-red-500/50 text-red-500 bg-red-500/10" :
                                "border-yellow-500/50 text-yellow-500 bg-yellow-500/10"
                    )}>
                        {pred.status}
                    </Badge>
                </td>
                <td className="px-6 py-4 text-right font-mono font-bold">
                    {isPending ? (
                        <span className="text-amber-500/50">{pred.bet_amount}</span>
                    ) : (
                        <span className={cn(
                            profitValue > 0 ? "text-emerald-500" :
                                profitValue < 0 ? "text-red-500" : "text-muted-foreground"
                        )}>
                            {profitValue !== 0 ? (profitValue > 0 ? `+${Math.round(Number(profitValue))}` : Math.round(Number(profitValue))) : '-'}
                        </span>
                    )}
                </td>
            </tr>
            {isOpen && (
                <tr className="bg-white/[0.02]">
                    <td colSpan={7} className="px-6 py-4 border-t border-white/5 shadow-inner">
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-sm">
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Entry Price</div>
                                <div className="font-mono text-white">${Number(entry).toLocaleString(undefined, { minimumFractionDigits: 2 })}</div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Close Price</div>
                                <div className={cn("font-mono font-bold", close > entry ? "text-emerald-400" : close < entry ? "text-red-400" : "text-white")}>
                                    ${Number(close).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Actual Move</div>
                                <div className={cn("font-bold", changePct > 0 ? "text-emerald-400" : changePct < 0 ? "text-red-400" : "text-gray-400")}>
                                    {changePct > 0 ? "+" : ""}{changePct.toFixed(2)}%
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-muted-foreground uppercase mb-1">Details</div>
                                <div className="space-y-1 text-xs">
                                    <div className="flex justify-between w-32 border-b border-white/10 pb-1 mb-1">
                                        <span className="text-muted-foreground">Direction:</span>
                                        {directionCorrect ? <span className="text-emerald-500">Correct</span> : <span className="text-red-500">Wrong</span>}
                                    </div>
                                    <div className="flex justify-between w-32">
                                        <span className="text-muted-foreground">Target Hit:</span>
                                        {isTargetHit ? <span className="text-emerald-500">Yes</span> : <span className="text-red-500">No</span>}
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="mt-4 pt-3 border-t border-white/5 flex items-center justify-between">
                            <div className="text-[10px] text-muted-foreground flex items-center gap-1">
                                <span className="inline-block w-1.5 h-1.5 rounded-full bg-blue-500/50"></span>
                                Resolved using Binance {pred.timeframe} candle close price
                            </div>
                            {pred.candle_close_at && (
                                <div className="text-[10px] text-muted-foreground">
                                    Candle Time: {dayjs(new Date(new Date(pred.candle_close_at).getTime() - (pred.timeframe.includes('m') ? parseInt(pred.timeframe) * 60 : pred.timeframe.includes('h') ? parseInt(pred.timeframe) * 3600 : 86400) * 1000)).format('h:mm A')} – {dayjs(pred.candle_close_at).format('h:mm A')}
                                </div>
                            )}
                        </div>
                    </td>
                </tr>
            )}
        </>
    );
}
