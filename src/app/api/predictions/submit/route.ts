import { createClient } from "@/lib/supabase/server";
import { createClient as createServiceClient } from "@supabase/supabase-js";
import { NextRequest, NextResponse } from "next/server";
import { ASSETS, TIMEFRAMES } from "@/lib/constants";

export const dynamic = "force-dynamic";

const VALID_ASSETS = new Set(Object.values(ASSETS).flat().map((asset) => asset.symbol));
const VALID_DIRECTIONS = new Set(["UP", "DOWN"]);
const VALID_TIMEFRAMES = new Set(TIMEFRAMES);
const TX_HASH_PATTERN = /^0x[a-fA-F0-9]{64}$/;

const serviceSupabase = createServiceClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

function getTimestamp() {
    return `[${new Date().toLocaleTimeString()}]`;
}

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const {
            data: { user },
            error: authError,
        } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json({ success: false, error: "Unauthorized" }, { status: 401 });
        }

        const {
            p_asset_symbol,
            p_timeframe,
            p_direction,
            p_entry_price,
            p_bet_amount,
            p_candle_close_at,
            p_tx_hash,
        } = await req.json();

        const assetSymbol = String(p_asset_symbol || "").trim().toUpperCase();
        const timeframe = String(p_timeframe || "").trim();
        const direction = String(p_direction || "").trim().toUpperCase();
        const entryPrice = Number(p_entry_price);
        const betAmount = Number(p_bet_amount);
        const txHash = String(p_tx_hash || "").trim();
        const candleCloseAt = new Date(String(p_candle_close_at || ""));

        if (!VALID_ASSETS.has(assetSymbol)) {
            return NextResponse.json({ success: false, error: "Unsupported asset" }, { status: 400 });
        }

        if (!VALID_TIMEFRAMES.has(timeframe)) {
            return NextResponse.json({ success: false, error: "Unsupported timeframe" }, { status: 400 });
        }

        if (!VALID_DIRECTIONS.has(direction)) {
            return NextResponse.json({ success: false, error: "Invalid direction" }, { status: 400 });
        }

        if (!Number.isFinite(entryPrice) || entryPrice <= 0) {
            return NextResponse.json({ success: false, error: "Invalid entry price" }, { status: 400 });
        }

        if (!Number.isInteger(betAmount) || betAmount <= 0) {
            return NextResponse.json({ success: false, error: "Invalid bet amount" }, { status: 400 });
        }

        if (!TX_HASH_PATTERN.test(txHash)) {
            return NextResponse.json({ success: false, error: "Invalid tx hash" }, { status: 400 });
        }

        if (Number.isNaN(candleCloseAt.getTime())) {
            return NextResponse.json({ success: false, error: "Invalid candle close time" }, { status: 400 });
        }

        const comment = `tx:${txHash}`;

        const { data: existing } = await serviceSupabase
            .from("predictions")
            .select("id")
            .eq("user_id", user.id)
            .eq("asset_symbol", assetSymbol)
            .eq("timeframe", timeframe)
            .eq("direction", direction)
            .eq("candle_close_at", candleCloseAt.toISOString())
            .eq("comment", comment)
            .maybeSingle();

        if (existing?.id) {
            return NextResponse.json({
                success: true,
                data: { prediction_id: existing.id, mirrored: true },
            });
        }

        console.log(
            `${getTimestamp()} [BET MIRROR] User: ${user.id}, Symbol: ${assetSymbol}, TF: ${timeframe}, Dir: ${direction}, Amount: ${betAmount}, Tx: ${txHash}`
        );

        const { data, error } = await serviceSupabase
            .from("predictions")
            .insert({
                user_id: user.id,
                asset_symbol: assetSymbol,
                timeframe,
                direction,
                target_percent: 0,
                entry_price: entryPrice,
                bet_amount: betAmount,
                status: "pending",
                candle_close_at: candleCloseAt.toISOString(),
                comment,
            })
            .select("id")
            .single();

        if (error) {
            console.error(`${getTimestamp()} [BET MIRROR FAILED] User: ${user.id}, Error: ${error.message}`);
            return NextResponse.json({ success: false, error: error.message }, { status: 400 });
        }

        return NextResponse.json({
            success: true,
            data: { prediction_id: data.id, mirrored: true },
        });
    } catch (err: any) {
        console.error(`${getTimestamp()} [BET MIRROR CRITICAL ERROR]`, err);
        return NextResponse.json({ success: false, error: err.message }, { status: 500 });
    }
}
