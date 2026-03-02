-- Drop old functions before creating new versions
DROP FUNCTION IF EXISTS get_live_rounds_with_stats(TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_trending_by_category();
