"use client";

import { useEffect, useRef, memo } from 'react';

interface TradingViewWidgetProps {
    symbol: string;
    theme?: 'light' | 'dark';
    className?: string;
    interval?: string;
}

function convertIntervalToTradingView(interval: string): string {
    if (interval === '1d') return 'D';
    if (interval.endsWith('m')) return interval.replace('m', '');
    if (interval.endsWith('h')) {
        const hours = parseInt(interval.replace('h', ''));
        return (hours * 60).toString();
    }
    return interval;
}

function TradingViewWidget({ symbol, theme = 'dark', className, interval = '60' }: TradingViewWidgetProps) {
    const container = useRef<HTMLDivElement>(null);

    useEffect(
        () => {
            if (!container.current) return;

            // Clean up previous widget
            container.current.innerHTML = '';

            const script = document.createElement("script");
            script.src = "https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js";
            script.type = "text/javascript";
            script.async = true;
            script.innerHTML = JSON.stringify({
                "autosize": true,
                "symbol": symbol,
                "interval": convertIntervalToTradingView(interval),
                "timezone": Intl.DateTimeFormat().resolvedOptions().timeZone,
                "theme": theme,
                "style": "1",
                "locale": "en",
                "enable_publishing": false,
                "hide_top_toolbar": false,
                "hide_legend": false,
                "allow_symbol_change": true,
                "save_image": false,
                "calendar": false,
                "hide_volume": false,
                "support_host": "https://www.tradingview.com",
                "studies": [
                    "RSI@tv-basicstudies",
                    "EMA@tv-basicstudies",
                    {
                        "id": "EMA@tv-basicstudies",
                        "inputs": {
                            "length": 50
                        }
                    },
                    {
                        "id": "EMA@tv-basicstudies",
                        "inputs": {
                            "length": 20
                        }
                    }
                ]
            });
            container.current.appendChild(script);
        },
        [symbol, theme, interval]
    );

    return (
        <div className={className} style={{ height: "100%", width: "100%" }}>
            <div className="tradingview-widget-container" ref={container} style={{ height: "100%", width: "100%" }}>
                <div className="tradingview-widget-container__widget" style={{ height: "100%", width: "100%" }}></div>
            </div>
        </div>
    );
}

export default memo(TradingViewWidget);
