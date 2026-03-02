import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

dayjs.extend(utc);
dayjs.extend(timezone);

const ET_TIMEZONE = 'America/New_York';

export const isMarketOpen = (symbol: string, type: string) => {
    // 1. CRYPTO: Always Open
    if (type === 'CRYPTO') return { isOpen: true, nextOpen: null };

    const now = dayjs().tz(ET_TIMEZONE);
    const day = now.day(); // 0=Sun, 6=Sat
    const hour = now.hour();
    const minute = now.minute();
    const minutesOfDay = hour * 60 + minute;

    // 2. FOREX (24/5)
    // Opens Sunday 5PM ET -> Closes Friday 5PM ET
    if (type === 'FOREX') {
        if (day === 6) return { isOpen: false, reason: "Market Closed (Weekend)" }; // Saturday
        if (day === 5 && hour >= 17) return { isOpen: false, reason: "Market Closed (Fri evening)" }; // Fri > 5PM
        if (day === 0 && hour < 17) return { isOpen: false, reason: "Market Closed (Sun morning)" }; // Sun < 5PM
        return { isOpen: true };
    }

    // 3. US STOCKS (NYSE/NASDAQ)
    // Mon-Fri 9:30 AM - 4:00 PM ET
    if (type === 'STOCK') {
        if (day === 0 || day === 6) return { isOpen: false, reason: "Market Closed (Weekend)" };

        // Check Holidays (Simplified)
        // TODO: Add proper holiday calendar lookup

        // Standard Hours: 9:30 AM (570m) - 4:00 PM (960m)
        const startMinutes = 9 * 60 + 30;
        const endMinutes = 16 * 60;

        if (minutesOfDay >= startMinutes && minutesOfDay < endMinutes) {
            return { isOpen: true };
        }
        return { isOpen: false, reason: "Market Closed (9:30 AM - 4:00 PM ET)" };
    }

    // 4. COMMODITIES
    if (type === 'COMMODITY') {
        if (day === 6) return { isOpen: false, reason: "Market Closed (Weekend)" }; // Saturday closed

        // A. GRAINS (Corn, Soybeans, Wheat) - CBOT
        // Trading: Sun-Fri 8:00 PM - 2:20 PM (Next Day)
        // Break: 2:20 PM - 8:00 PM ET
        if (['CORN', 'SOY', 'WHEAT'].includes(symbol)) {
            // Check Break Time (14:20 - 20:00)
            const breakStart = 14 * 60 + 20; // 14:20
            const breakEnd = 20 * 60;        // 20:00

            if (minutesOfDay >= breakStart && minutesOfDay < breakEnd) {
                return { isOpen: false, reason: "Daily Break (2:20 PM - 8:00 PM ET)" };
            }

            // Friday Close at 2:20 PM
            if (day === 5 && minutesOfDay >= breakStart) {
                return { isOpen: false, reason: "Market Closed (Weekend)" };
            }

            // Sunday Open at 8:00 PM
            if (day === 0 && minutesOfDay < breakEnd) {
                return { isOpen: false, reason: "Market Closed (Opens Sun 8PM ET)" };
            }

            return { isOpen: true };
        }

        // B. METALS & ENERGY (Gold, Silver, Oil, Gas) - CME Globex / NYMEX
        // Trading: Sun-Fri 6:00 PM - 5:00 PM (Next Day)
        // Break: 5:00 PM - 6:00 PM ET

        // Daily Break (17:00 - 18:00)
        if (hour === 17) return { isOpen: false, reason: "Daily Maintenance (5PM-6PM ET)" };

        // Friday Close at 5:00 PM
        if (day === 5 && hour >= 17) return { isOpen: false, reason: "Market Closed (Weekend)" };

        // Sunday Open at 6:00 PM
        if (day === 0 && hour < 18) return { isOpen: false, reason: "Market Closed (Opens Sun 6PM ET)" };

        return { isOpen: true };
    }

    return { isOpen: true }; // Default open
};
