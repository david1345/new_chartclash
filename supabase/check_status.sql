-- Check status of supposedly resolved predictions
SELECT id, status, resolved_at, profit 
FROM predictions 
WHERE id IN (9, 10);

-- Check if notifications were created for them
SELECT * FROM notifications WHERE prediction_id IN (9, 10);
