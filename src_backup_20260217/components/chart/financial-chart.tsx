"use client";

import { useEffect, useRef, useState } from "react";
import { createChart, ColorType, ISeriesApi, CandlestickData, Time, CandlestickSeries } from "lightweight-charts";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

interface FinancialChartProps {
    symbol?: string; // e.g. "btcusdt"
    interval?: string; // e.g. "1m", "15m"
    className?: string;
}

export function FinancialChart({
    symbol = "btcusdt",
    interval = "1m",
    className
}: FinancialChartProps) {
    const chartContainerRef = useRef<HTMLDivElement>(null);
    const chartRef = useRef<ReturnType<typeof createChart> | null>(null);
    const candlestickSeriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
    const [currentPrice, setCurrentPrice] = useState<number | null>(null);
    const [prevPrice, setPrevPrice] = useState<number | null>(null);
    const [socketStatus, setSocketStatus] = useState<"connecting" | "connected" | "disconnected">("connecting");

    useEffect(() => {
        if (!chartContainerRef.current) return;

        // Initialize Chart
        const chart = createChart(chartContainerRef.current, {
            layout: {
                background: { type: ColorType.Solid, color: 'transparent' },
                textColor: '#A1A1AA', // muted-foreground
            },
            grid: {
                vertLines: { color: 'rgba(255, 255, 255, 0.05)' },
                horzLines: { color: 'rgba(255, 255, 255, 0.05)' },
            },
            width: chartContainerRef.current.clientWidth,
            height: 400,
            timeScale: {
                timeVisible: true,
                secondsVisible: false,
                borderColor: 'rgba(255, 255, 255, 0.1)',
            },
            rightPriceScale: {
                borderColor: 'rgba(255, 255, 255, 0.1)',
            },
        });

        chartRef.current = chart;

        const newSeries = chart.addSeries(CandlestickSeries, {
            upColor: '#10B981', // emerald-500
            downColor: '#EF4444', // red-500
            borderVisible: false,
            wickUpColor: '#10B981',
            wickDownColor: '#EF4444',
        });

        candlestickSeriesRef.current = newSeries;

        // Fetch Initial Data (Mock or history API if available)
        fetch(`https://api.binance.com/api/v3/klines?symbol=${symbol.toUpperCase()}&interval=${interval}&limit=100`)
            .then(res => res.json())
            .then(data => {
                const candles = data.map((d: any) => ({
                    time: d[0] / 1000 as Time,
                    open: parseFloat(d[1]),
                    high: parseFloat(d[2]),
                    low: parseFloat(d[3]),
                    close: parseFloat(d[4]),
                }));
                newSeries.setData(candles);
                if (candles.length > 0) {
                    setCurrentPrice(candles[candles.length - 1].close);
                }
            })
            .catch(err => console.error("Failed to fetch initial data", err));

        // WebSocket Connection
        const ws = new WebSocket(`wss://stream.binance.com:9443/ws/${symbol}@kline_${interval}`);

        ws.onopen = () => setSocketStatus("connected");
        ws.onclose = () => setSocketStatus("disconnected");
        ws.onerror = () => setSocketStatus("disconnected");

        ws.onmessage = (event) => {
            const message = JSON.parse(event.data);
            if (message.k) {
                const candle = message.k;
                const candleData: CandlestickData<Time> = {
                    time: candle.t / 1000 as Time,
                    open: parseFloat(candle.o),
                    high: parseFloat(candle.h),
                    low: parseFloat(candle.l),
                    close: parseFloat(candle.c),
                };
                newSeries.update(candleData);

                setCurrentPrice(prev => {
                    setPrevPrice(prev);
                    return parseFloat(candle.c);
                });
            }
        };

        // Resize Observer
        const handleResize = () => {
            if (chartContainerRef.current) {
                chart.applyOptions({ width: chartContainerRef.current.clientWidth });
            }
        };

        window.addEventListener('resize', handleResize);

        return () => {
            ws.close();
            chart.remove();
            window.removeEventListener('resize', handleResize);
        };
    }, [symbol, interval]);

    const priceColor = currentPrice && prevPrice
        ? (currentPrice > prevPrice ? "text-emerald-500" : currentPrice < prevPrice ? "text-red-500" : "text-white")
        : "text-white";

    return (
        <Card className={cn("p-4 bg-card/50 backdrop-blur-md border-white/5", className)}>
            <div className="flex justify-between items-center mb-4">
                <div className="flex items-center gap-2">
                    <h2 className="text-xl font-bold uppercase tracking-widest">{symbol}</h2>
                    <Badge variant="outline" className={cn("text-xs border-primary/30 bg-primary/10", socketStatus === 'connected' ? "text-emerald-500 border-emerald-500/30 bg-emerald-500/10" : "text-yellow-500")}>
                        {socketStatus === 'connected' ? 'LIVE' : 'CONNECTING'}
                    </Badge>
                </div>
                <div className={cn("text-2xl font-mono font-bold transition-colors", priceColor)}>
                    ${currentPrice?.toLocaleString(undefined, { minimumFractionDigits: 2 }) || "---"}
                </div>
            </div>
            <div ref={chartContainerRef} className="w-full h-[400px]" />
        </Card>
    );
}
