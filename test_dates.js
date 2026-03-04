const totalSeconds = 3600;
const now = Date.now();
const roundCloseTime = Math.floor(now / (totalSeconds * 1000)) * (totalSeconds * 1000) + (totalSeconds * 1000);
const candle_close_at = new Date(roundCloseTime).toISOString();

console.log("Now:", new Date(now).toISOString());
console.log("Candle Close At:", candle_close_at);
console.log("Is Close in the future? (now):", new Date(candle_close_at).getTime() > now);

const serverTimeOffset = -1000 * 60 * 60 * 5; // Simulating a large server offset (e.g., -5 hours)
const adjustedNow = now + serverTimeOffset;

console.log("Adjusted Now:", new Date(adjustedNow).toISOString());
console.log("Is Close in the future? (adjusted):", new Date(candle_close_at).getTime() > adjustedNow);
