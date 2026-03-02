SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'predictions'; 

-- check indexes as well
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'predictions';
