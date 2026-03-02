-- 1. Add Score Columns to Posts Table
-- These store the pre-calculated components for O(1) sorting
ALTER TABLE posts 
ADD COLUMN feed_score INT DEFAULT 0,       -- Total Base Score (Server Side)
ADD COLUMN engagement_score INT DEFAULT 0, -- Sub-score: Engagement
ADD COLUMN author_score INT DEFAULT 0,     -- Sub-score: Tier
ADD COLUMN freshness_score INT DEFAULT 0;  -- Sub-score: Time Decay

-- 2. Index for Feed Query
-- Critical for "ORDER BY feed_score DESC" performance
CREATE INDEX idx_posts_feed_score ON posts (feed_score DESC);

-- 3. Trigger Function: Auto-Calculate on Insert/Update (Optional DB-side logic)
-- Note: User prefers Server-Side logic (TS), but this is a DB safeguard example.
/*
CREATE OR REPLACE FUNCTION update_feed_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Simplified example: just sum the parts (actual logic is complex/business specific)
    NEW.feed_score := NEW.author_score + NEW.engagement_score + NEW.freshness_score;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_feed_score
BEFORE INSERT OR UPDATE OF author_score, engagement_score, freshness_score ON posts
FOR EACH ROW EXECUTE FUNCTION update_feed_score();
*/
