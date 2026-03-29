"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { connectWallet, placeBetOnChain } from "@/lib/contract";
import { cn } from "@/lib/utils";
import { ASSETS, type Asset } from "@/lib/constants";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { RoundStatus } from "@/components/battle/round-status";
import { BattleMeter } from "@/components/battle/battle-meter";
import { TimeframeSelector } from "@/components/battle/timeframe-selector";
import { BetInput } from "@/components/battle/bet-input";
import { RewardDisplay } from "@/components/battle/reward-display";
import { ActionButtons } from "@/components/battle/action-buttons";
import { ActivePositionPanel } from "@/components/battle/active-position-panel";

interface OrderPanelProps {
    user: any;
    userPoints: number;
    selectedAsset: Asset;
    setSelectedAsset: (asset: Asset) => void;
    selectedTimeframe: string;
    setSelectedTimeframe: (tf: string) => void;
    marketStatus: { isOpen: boolean; reason?: string };
    isLocked: boolean;
    isAlreadyBet: boolean;
    refreshPredictions: () => void;
    fetchUserStats: () => void;
    onBetSuccess?: () => void;
    isLoaded: boolean;
    activePrediction?: any;
    roundOpenPrice?: number | null;
    serverTimeOffset: number;
}

export function OrderPanel({
    user,
    userPoints,
    selectedAsset,
    setSelectedAsset,
    selectedTimeframe,
    setSelectedTimeframe,
    marketStatus,
    isLocked,
    isAlreadyBet,
    refreshPredictions,
    fetchUserStats,
    onBetSuccess,
    isLoaded,
    activePrediction,
    roundOpenPrice,
    serverTimeOffset
}: OrderPanelProps) {
    const assetOptions = Object.entries(ASSETS).flatMap(([category, assets]) =>
        assets.map((asset) => ({
            ...asset,
            categoryLabel:
                category === "STOCKS"
                    ? "STOCK"
                    : category === "COMMODITIES"
                        ? "COMMODITY"
                        : category,
        }))
    );

    const [betAmount, setBetAmount] = useState(10);
    const [selectedDirection, setSelectedDirection] = useState<"UP" | "DOWN" | null>(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [walletAddress, setWalletAddress] = useState<string | null>(null);
    const [candleElapsed, setCandleElapsed] = useState<number | null>(null);
    const [localElapsed, setLocalElapsed] = useState<number>(0);
    const [upPercent, setUpPercent] = useState(62.5);
    const [downPercent, setDownPercent] = useState(37.5);

    useEffect(() => {
        if (candleElapsed !== null) {
            setLocalElapsed(candleElapsed);
        }
    }, [candleElapsed]);

    useEffect(() => {
        const interval = setInterval(() => {
            setLocalElapsed((prev) => prev + 1);
        }, 1000);

        return () => clearInterval(interval);
    }, []);

    useEffect(() => {
        if (typeof window === "undefined" || !window.ethereum) return;

        let active = true;
        const ethereum = window.ethereum;

        const syncWallet = async () => {
            try {
                const accounts = await ethereum.request({ method: "eth_accounts" }) as string[];
                if (!active) return;
                setWalletAddress(accounts[0] || null);
            } catch {
                if (!active) return;
                setWalletAddress(null);
            }
        };

        const handleAccountsChanged = (accounts: string[]) => {
            setWalletAddress(accounts[0] || null);
            fetchUserStats();
        };

        syncWallet();
        ethereum.on?.("accountsChanged", handleAccountsChanged);

        return () => {
            active = false;
            ethereum.removeListener?.("accountsChanged", handleAccountsChanged);
        };
    }, [fetchUserStats]);

    useEffect(() => {
        const fetchInitialPrice = async () => {
            try {
                const res = await fetch("/api/market/entry-price", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        symbol: selectedAsset.symbol,
                        timeframe: selectedTimeframe,
                        type: selectedAsset.type,
                    })
                });
                const json = await res.json();
                if (json.success && json.data?.candleElapsedSeconds !== undefined) {
                    setCandleElapsed(json.data.candleElapsedSeconds);
                }
            } catch (error) {
                console.error("Server price API error", error);
            }
        };

        fetchInitialPrice();
    }, [selectedAsset.symbol, selectedAsset.type, selectedTimeframe]);

    useEffect(() => {
        if (!isLoaded) return;
        if (userPoints <= 0) {
            setBetAmount(1);
            return;
        }

        setBetAmount((current) => {
            if (current > userPoints) {
                return Math.max(1, Math.floor(userPoints));
            }
            return current;
        });
    }, [isLoaded, userPoints]);

    const totalSeconds = selectedTimeframe === "1h" ? 3600 : selectedTimeframe === "4h" ? 14400 : 3600;
    const displaySymbol = selectedAsset.symbol.endsWith("USDT")
        ? `${selectedAsset.symbol.slice(0, -4)}/USDT`
        : selectedAsset.symbol;
    const isSubmissionBlocked = isSubmitting || isLocked || isAlreadyBet || !marketStatus.isOpen || !user || !walletAddress || !isLoaded;

    const fetchCandleData = async () => {
        try {
            const res = await fetch("/api/market/entry-price", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    symbol: selectedAsset.symbol,
                    timeframe: selectedTimeframe,
                    type: selectedAsset.type,
                })
            });
            const json = await res.json();
            if (!json.success || !json.data) return null;
            return json.data;
        } catch {
            return null;
        }
    };

    const handleAssetChange = (symbol: string) => {
        const asset = assetOptions.find((item) => item.symbol === symbol);
        if (asset) {
            setSelectedAsset(asset);
        }
    };

    const handleConnectWallet = async () => {
        if (!user) {
            toast.error("Sign in first to place real-money bets.");
            return;
        }

        try {
            const address = await connectWallet();
            setWalletAddress(address);
            await fetchUserStats();
            toast.success("Wallet connected for USDT staking.");
        } catch (error: any) {
            toast.error(error?.message || "Failed to connect wallet.");
        }
    };

    const handlePredict = async (direction: "UP" | "DOWN") => {
        setSelectedDirection(direction);

        if (isSubmitting) return;
        if (!user) {
            toast.error("Sign in to place a live USDT bet.");
            return;
        }
        if (!walletAddress) {
            toast.error("Connect MetaMask before staking.");
            return;
        }
        if (!Number.isInteger(betAmount) || betAmount <= 0) {
            toast.warning("Minimum bet is 1 USDT");
            return;
        }
        if (betAmount > userPoints) {
            toast.warning("Insufficient contract balance");
            return;
        }
        if (isLocked) {
            toast.error("Round is locked. Wait for the next market window.");
            return;
        }
        if (!marketStatus.isOpen) {
            toast.error(marketStatus.reason || `${selectedAsset.name} market is currently closed.`);
            return;
        }

        setIsSubmitting(true);

        try {
            const candleData = await fetchCandleData();
            if (!candleData) {
                toast.error("Could not fetch market data. Try again.");
                return;
            }

            const now = Date.now();
            const adjustedNow = now + serverTimeOffset;
            const roundCloseTime = Math.floor(adjustedNow / (totalSeconds * 1000)) * (totalSeconds * 1000) + (totalSeconds * 1000);
            const roundOpenTime = roundCloseTime - totalSeconds * 1000;

            const roundRes = await fetch("/api/rounds/get-or-create", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    asset: selectedAsset.symbol,
                    timeframe: selectedTimeframe,
                    openTime: roundOpenTime,
                    closeTime: roundCloseTime,
                    openPrice: candleData.openPrice
                })
            });

            const roundJson = await roundRes.json();
            if (!roundRes.ok || !roundJson.onChainId) {
                throw new Error(roundJson.error || "Failed to open market on-chain");
            }

            const txHash = await placeBetOnChain(roundJson.onChainId, direction === "UP", betAmount);

            try {
                const mirrorRes = await fetch("/api/predictions/submit", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        p_asset_symbol: selectedAsset.symbol,
                        p_timeframe: selectedTimeframe,
                        p_direction: direction,
                        p_entry_price: candleData.openPrice,
                        p_bet_amount: betAmount,
                        p_candle_close_at: new Date(roundCloseTime).toISOString(),
                        p_tx_hash: txHash,
                    })
                });

                const mirrorJson = await mirrorRes.json();
                if (!mirrorRes.ok || !mirrorJson.success) {
                    toast.warning("On-chain bet succeeded, but history sync is delayed.");
                }
            } catch {
                toast.warning("On-chain bet succeeded, but history sync is delayed.");
            }

            await fetchUserStats();
            refreshPredictions();
            onBetSuccess?.();
            toast.success("USDT bet submitted on-chain.");
        } catch (error: any) {
            toast.error(error?.message || "An unexpected error occurred.");
        } finally {
            setIsSubmitting(false);
            setSelectedDirection(null);

            const newUp = Math.random() * 40 + 30;
            setUpPercent(newUp);
            setDownPercent(100 - newUp);
        }
    };

    return (
        <div className="flex flex-col h-full bg-[#080C14] rounded-2xl p-2 lg:p-3 border border-[#1E2D45] overflow-y-auto no-scrollbar relative lg:min-h-0">
            <div className="mb-2 space-y-2 rounded-2xl border border-[#1E2D45] bg-[#0F1623] p-3">
                <div className="flex items-start justify-between gap-3">
                    <div>
                        <div className="text-[10px] font-black uppercase tracking-[0.18em] text-[#5A7090]">
                            Battle Market
                        </div>
                        <div className="mt-1 text-sm font-black text-white">
                            {selectedAsset.name}
                        </div>
                        <div className="text-[11px] font-mono text-[#00E5B4]">{displaySymbol}</div>
                    </div>
                    <div className={cn(
                        "rounded-full border px-2.5 py-1 text-[10px] font-black uppercase tracking-wider",
                        marketStatus.isOpen
                            ? "border-[#00E5B4]/30 bg-[#00E5B4]/10 text-[#00E5B4]"
                            : "border-[#FF4560]/30 bg-[#FF4560]/10 text-[#FF4560]"
                    )}>
                        {marketStatus.isOpen ? "Open" : "Closed"}
                    </div>
                </div>

                <div id="tutorial-market-select">
                    <Select value={selectedAsset.symbol} onValueChange={handleAssetChange}>
                        <SelectTrigger className="h-10 border-[#1E2D45] bg-[#080C14] text-white focus:ring-0 focus:ring-offset-0">
                            <SelectValue placeholder="Select asset" />
                        </SelectTrigger>
                        <SelectContent className="border-[#1E2D45] bg-[#0F1623] text-white">
                            {assetOptions.map((asset) => (
                                <SelectItem key={asset.symbol} value={asset.symbol}>
                                    {asset.symbol} · {asset.categoryLabel} · {asset.name}
                                </SelectItem>
                            ))}
                        </SelectContent>
                    </Select>
                </div>

                {!marketStatus.isOpen && (
                    <div className="rounded-xl border border-[#FF4560]/20 bg-[#FF4560]/10 px-3 py-2 text-[11px] text-[#F6B5BE]">
                        {marketStatus.reason || `${selectedAsset.name} market is currently closed.`}
                    </div>
                )}
            </div>

            <RoundStatus
                timeframe={selectedTimeframe}
                referencePrice={roundOpenPrice ?? null}
                candleElapsed={localElapsed}
                isLocked={isLocked}
            />

            {!isAlreadyBet ? (
                <>
                    <BattleMeter upPercent={upPercent} downPercent={downPercent} />

                    <div className="flex gap-2 mb-1.5 items-stretch">
                        <div className="w-[48px] shrink-0">
                            <TimeframeSelector selectedTimeframe={selectedTimeframe} onSelect={setSelectedTimeframe} />
                        </div>

                        <div className="flex-1" id="tutorial-bet">
                            <BetInput
                                amount={betAmount}
                                maxAmount={userPoints}
                                onChange={(value) => setBetAmount(Math.min(Math.max(1, Math.floor(value || 0)), Math.max(1, Math.floor(userPoints || 0))))}
                                disabled={isSubmitting || !user}
                            />
                        </div>
                    </div>

                    <RewardDisplay
                        betAmount={betAmount}
                        upPercent={upPercent}
                        downPercent={downPercent}
                    />

                    {!user ? (
                        <div className="mt-2 rounded-xl border border-[#1E2D45] bg-[#0F1623] px-3 py-3 text-xs text-[#8BA3BF]">
                            <div className="font-bold uppercase tracking-wide text-white">Account required</div>
                            <div className="mt-1 text-[11px]">
                                Real-money staking is available only for signed-in accounts with a connected wallet.
                            </div>
                            <Link href="/login" className="mt-3 inline-flex rounded-lg border border-[#00E5B4]/40 px-3 py-2 font-bold text-[#00E5B4] hover:bg-[#00E5B4]/10 transition-colors">
                                Sign In
                            </Link>
                        </div>
                    ) : (
                        <div
                            id="tutorial-wallet-connect"
                            className={cn(
                            "mt-2 rounded-xl border px-3 py-2 text-xs",
                            walletAddress
                                ? "border-[#00E5B4]/30 bg-[#00E5B4]/10 text-[#00E5B4]"
                                : "border-[#1E2D45] bg-[#0F1623] text-[#8BA3BF]"
                        )}>
                            <div className="flex items-center justify-between gap-3">
                                <div>
                                    <div className="font-bold uppercase tracking-wide">USDT Contract Balance</div>
                                    <div className="mt-0.5 text-[11px]">
                                        {walletAddress
                                            ? `${walletAddress.slice(0, 6)}...${walletAddress.slice(-4)} · ${userPoints.toFixed(2)} USDT ready`
                                            : "Connect MetaMask to stake from your contract balance."}
                                    </div>
                                </div>
                                {!walletAddress ? (
                                    <button
                                        type="button"
                                        onClick={handleConnectWallet}
                                        className="shrink-0 rounded-lg border border-[#00E5B4]/40 px-3 py-2 font-bold text-[#00E5B4] hover:bg-[#00E5B4]/10 transition-colors"
                                    >
                                        Connect
                                    </button>
                                ) : (
                                    <Link
                                        href="/deposit"
                                        className="shrink-0 rounded-lg border border-[#00E5B4]/40 px-3 py-2 font-bold text-[#00E5B4] hover:bg-[#00E5B4]/10 transition-colors"
                                    >
                                        Deposit
                                    </Link>
                                )}
                            </div>
                        </div>
                    )}

                    <div className="pt-2 z-10 lg:static lg:bg-none lg:pt-0 pb-2 lg:pb-0" id="tutorial-direction">
                        <ActionButtons
                            selectedDirection={selectedDirection}
                            isSubmitting={isSubmissionBlocked}
                            onPredict={handlePredict}
                        />
                    </div>
                </>
            ) : (
                <div className="flex-1 mt-2 mb-2 lg:mb-0">
                    <ActivePositionPanel
                        prediction={activePrediction}
                        currentPrice={roundOpenPrice ?? null}
                    />
                </div>
            )}
        </div>
    );
}
