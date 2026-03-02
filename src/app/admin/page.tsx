"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import {
    Activity,
    Users,
    TrendingUp,
    DollarSign,
    AlertCircle,
    RefreshCw,
    BarChart3
} from "lucide-react";
import { toast } from "sonner";

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
    const [systemHealth, setSystemHealth] = useState<any>({});
    const [isLoading, setIsLoading] = useState(false);

    // Initial Auth Check
    useEffect(() => {
        const adminPass = localStorage.getItem('admin_auth');
        if (adminPass === 'your-secret-password') {
            setIsAuthorized(true);
            fetchAllData(); // Fetch immediately if authorized
        }
    }, []);

    // Polling Effect (only when authorized)
    useEffect(() => {
        if (!isAuthorized) return;

        // Initial fetch if not already done by auth check (handled by separate call usually, but safe to call here)
        if (stats.totalUsers === 0) fetchAllData();

        // Auto-refresh every 30 seconds
        const interval = setInterval(fetchAllData, 30000);
        return () => clearInterval(interval);
    }, [isAuthorized]);

    const handleLogin = () => {
        if (password === 'your-secret-password') {
            localStorage.setItem('admin_auth', password);
            setIsAuthorized(true);
            toast.success("Welcome back, Admin");
            fetchAllData();
        } else {
            toast.error('Invalid password');
        }
    };

    const fetchAllData = async () => {
        setIsLoading(true);
        await Promise.all([
            fetchStats(),
            fetchRecentPredictions(),
            fetchTopUsers(),
            checkSystemHealth()
        ]);
        setIsLoading(false);
    };

    const fetchStats = async () => {
        // Total users
        const { count: userCount } = await supabase
            .from('profiles')
            .select('*', { count: 'exact', head: true });

        // Total predictions
        const { count: predCount } = await supabase
            .from('predictions')
            .select('*', { count: 'exact', head: true });

        // Pending predictions
        const { count: pendingCount } = await supabase
            .from('predictions')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'pending');

        // Total points
        const { data: pointsData } = await supabase
            .from('profiles')
            .select('points');
        const totalPoints = pointsData?.reduce((sum, u) => sum + (u.points || 0), 0) || 0;

        // Win rate calculation
        const { data: resolved } = await supabase
            .from('predictions')
            .select('status')
            .in('status', ['WIN', 'LOSS']);

        const wins = resolved?.filter(p => p.status === 'WIN').length || 0;
        const total = resolved?.length || 1;
        const winRate = (wins / total) * 100;

        // Recently active users (last 1h)
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
        const { data } = await supabase
            .from('predictions')
            .select(`
        *,
        profiles (username, email)
      `)
            .order('created_at', { ascending: false })
            .limit(20);

        setRecentPredictions(data || []);
    };

    const fetchTopUsers = async () => {
        const { data } = await supabase
            .from('profiles')
            .select('id, username, email, points')
            .order('points', { ascending: false })
            .limit(10);

        setTopUsers(data || []);
    };

    const checkSystemHealth = async () => {
        try {
            // API response test
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
                toast.success(`Force resolve complete: ${data.resolved || 0} resolved, ${data.errors || 0} errors`);
                fetchAllData();
            } else {
                toast.error('Resolution failed: ' + (data.error || 'Unknown error'));
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
                        <TabsTrigger value="alerts">Alerts</TabsTrigger>
                    </TabsList>

                    {/* Recent Predictions Tab */}
                    <TabsContent value="predictions">
                        <Card className="bg-white/5 border-white/10 text-white">
                            <CardHeader>
                                <CardTitle>Recent Predictions</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-2">
                                    {recentPredictions.map((pred) => (
                                        <div key={pred.id} className="flex items-center justify-between p-3 bg-white/5 rounded-lg border border-white/5">
                                            <div className="flex-1">
                                                <p className="font-bold flex items-center gap-2">
                                                    {pred.profiles?.username || 'Unknown'}
                                                    <span className="text-xs font-normal text-gray-500">({pred.asset_symbol})</span>
                                                </p>
                                                <p className="text-sm text-gray-400">
                                                    {pred.direction} {pred.target_percent}%
                                                    · <span className="text-yellow-400">{pred.bet_amount} pts</span>
                                                </p>
                                            </div>
                                            <div className="text-right">
                                                <Badge variant={
                                                    pred.status === 'pending' ? 'outline' :
                                                        pred.status === 'WIN' ? 'default' : 'destructive'
                                                } className={
                                                    pred.status === 'WIN' ? 'bg-green-600' :
                                                        pred.status === 'LOSS' ? 'bg-red-600' : 'text-gray-400'
                                                }>
                                                    {pred.status}
                                                </Badge>
                                                <p className="text-xs text-gray-400 mt-1">
                                                    {new Date(pred.created_at).toLocaleTimeString()}
                                                </p>
                                            </div>
                                        </div>
                                    ))}
                                    {recentPredictions.length === 0 && (
                                        <div className="text-center text-gray-500 py-4">No recent predictions</div>
                                    )}
                                </div>
                            </CardContent>
                        </Card>
                    </TabsContent>

                    {/* Top Users Tab */}
                    <TabsContent value="users">
                        <Card className="bg-white/5 border-white/10 text-white">
                            <CardHeader>
                                <CardTitle>Top Users by Points</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-2">
                                    {topUsers.map((user, idx) => (
                                        <div key={user.id} className="flex items-center justify-between p-3 bg-white/5 rounded-lg border border-white/5">
                                            <div className="flex items-center gap-3">
                                                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center font-bold text-black shadow-lg">
                                                    {idx + 1}
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
                                    ))}
                                </div>
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

            </div>
        </div>
    );
}
