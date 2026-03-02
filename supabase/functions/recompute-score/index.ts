import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const { postId } = await req.json();

        if (!postId) {
            throw new Error("Missing postId");
        }

        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseKey);

        // 1. Fetch Post Data with Joined Relations (Author, Counts)
        // Note: This assumes you have views or RPCs to get counts, 
        // or you query related tables. For optimized feed, 'likes_count' etc usually exist on posts table
        // via other triggers or are counted here. Given the user prompt assume columns exist.
        const { data: post, error: fetchError } = await supabase
            .from("posts")
            .select(`
        id,
        created_at,
        volatility_target,
        likes_count,
        comments_count,
        bookmarks_count,
        shares_count,
        author:profiles(tier, asset_accuracy)
      `)
            .eq("id", postId)
            .single();

        if (fetchError || !post) {
            console.error("Post not found or error:", fetchError);
            return new Response("Post not found", { status: 404, headers: corsHeaders });
        }

        // 2. Calculate Sub-Scores
        // 2.1 Freshness
        const hoursOld = (Date.now() - new Date(post.created_at).getTime()) / (1000 * 60 * 60);
        const freshnessScore = Math.max(0, 100 - hoursOld * 5);

        // 2.2 Engagement
        const engagementScore =
            (post.likes_count || 0) * 3 +
            (post.comments_count || 0) * 5 +
            (post.bookmarks_count || 0) * 4 +
            (post.shares_count || 0) * 6;

        // 2.3 Author Tier
        const tierMap: Record<string, number> = {
            Unranked: 0,
            Bronze: 20,
            Silver: 40,
            Gold: 60,
            Platinum: 75,
            Master: 90,
            Legend: 100,
            // Map user provided lowercase if needed
            novice: 5, pro: 15, elite: 30, master: 50 // Legacy
        };

        // Normalize tier string
        const tierKey = post.author?.tier || "Unranked";
        const baseAuthorScore = tierMap[tierKey] || tierMap[tierKey.toUpperCase()] || 0;

        const authorScore = baseAuthorScore + (post.author?.asset_accuracy || 0) * 20;

        // 2.4 Volatility (Risk)
        const riskScore = (post.volatility_target || 0) * 10;

        // 3. Final Feed Score
        // Weighting can be applied here or just sum if pre-weighted
        const feedScore = freshnessScore + engagementScore + authorScore + riskScore;

        // 4. Update Post
        const { error: updateError } = await supabase
            .from("posts")
            .update({
                feed_score: Math.round(feedScore),
                freshness_score: Math.round(freshnessScore),
                engagement_score: Math.round(engagementScore),
                author_score: Math.round(authorScore),
            })
            .eq("id", postId);

        if (updateError) {
            throw updateError;
        }

        console.log(`Recomputed score for post ${postId}: ${feedScore}`);

        return new Response(JSON.stringify({ success: true, score: feedScore }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        console.error("Error recomputing score:", error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
