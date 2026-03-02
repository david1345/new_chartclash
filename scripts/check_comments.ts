import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

dotenv.config({ path: ".env.local" });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error("Missing Supabase credentials");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function main() {
    console.log("🔍 Checking Comments in Database...");

    // 1. Count total predictions
    const { count: total, error: err1 } = await supabase
        .from("predictions")
        .select("*", { count: 'exact', head: true });

    // 2. Count predictions with comments
    const { data: commented, error: err2 } = await supabase
        .from("predictions")
        .select("id, comment, created_at, asset_symbol")
        .not("comment", "is", null)
        .order("created_at", { ascending: false });

    if (err1 || err2) {
        console.error("❌ Error fetching data:", err1 || err2);
        return;
    }

    console.log(`📊 Total Predictions: ${total}`);
    console.log(`💬 Predictions with Comments: ${commented?.length}`);

    if (commented && commented.length > 0) {
        console.log("\n--- Recent Comments ---");
        commented.forEach((p, i) => {
            console.log(`${i + 1}. [${p.asset_symbol}] ${p.created_at}: "${p.comment}"`);
        });
    } else {
        console.log("⚠️ No comments found in DB. Previous saves likely failed.");
    }
}

main();
