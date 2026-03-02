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
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseKey);

        // Calculate cutoff for "Freshness decay candidates"
        // e.g., posts created in the last 48 hours need freshness updates
        const twoDaysAgo = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();

        const { data: posts, error } = await supabase
            .from("posts")
            .select("id")
            .gt("created_at", twoDaysAgo);

        if (error) throw error;

        console.log(`Found ${posts?.length ?? 0} posts to decay freshness.`);

        const functionUrl = `${supabaseUrl}/functions/v1/recompute-score`;

        // Process in batches or parallel
        // Ideally use a queue, but for scheduler calling individual function is okay for medium scale
        const promises = (posts ?? []).map(async (post) => {
            try {
                await fetch(functionUrl, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${supabaseKey}`
                    },
                    body: JSON.stringify({ postId: post.id }),
                });
            } catch (e) {
                console.error(`Failed to trigger recompute for ${post.id}`, e);
            }
        });

        await Promise.all(promises);

        return new Response(JSON.stringify({ success: true, processed: posts?.length }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        console.error("Error in decay-freshness:", error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});
