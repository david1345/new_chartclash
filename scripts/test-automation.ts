import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

dotenv.config({ path: ".env.local" });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error("Missing Supabase credentials in .env.local");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function main() {
    console.log("🧪 Starting Force Resolution Test...");

    // 1. Get the latest pending prediction
    const { data: preds, error } = await supabase
        .from("predictions")
        .select("*")
        .eq("status", "pending")
        .order("created_at", { ascending: false })
        .limit(1);

    if (error || !preds || preds.length === 0) {
        console.error("❌ No pending predictions found to test. Please create one in the UI first.");
        return;
    }

    const target = preds[0];
    console.log(`🎯 Found Target Prediction: ${target.asset_symbol} (${target.timeframe}) created at ${target.created_at}`);

    // 2. "Time Travel": Update created_at to be in the past (e.g., 2 hours ago)
    // This forces it to be "expired" regardless of timeframe (unless > 2h timeframe, but assuming 15m/1h here)
    const pastDate = new Date();
    pastDate.setHours(pastDate.getHours() - 2);

    const { error: updateError } = await supabase
        .from("predictions")
        .update({ created_at: pastDate.toISOString() })
        .eq("id", target.id);

    if (updateError) {
        console.error("❌ Failed to update timestamp:", updateError.message);
        return;
    }

    console.log(`✅ Time Travel Successful! Updated created_at to ${pastDate.toISOString()}`);
    console.log("⏳ Now simulating API call to /api/resolve logic...");

    // 3. Trigger Resolution Logic (Simulating what the API does)
    // We can just call the API endpoint via fetch if running, or replicate logic.
    // Let's assume user is running local server on 3000, try to hit it.
    try {
        const res = await fetch("http://localhost:3000/api/resolve");
        const json = await res.json();
        console.log("📡 API Response:", JSON.stringify(json, null, 2));

        if (json.resolvedCount > 0) {
            console.log("🎉 SUCCESS! Prediction resolved.");
        } else {
            console.log("⚠️ API returned success but no resolutions. Check logic or server logs.");
        }
    } catch (e) {
        console.error("❌ Failed to call API (Is localhost:3000 running?):", e);
        console.log("💡 Tip: Open http://localhost:3000/api/resolve in your browser manually.");
    }
}

main();
