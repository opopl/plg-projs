
-- drop table tags; 
CREATE TABLE IF NOT EXISTS tags (
   tag TEXT NOT NULL UNIQUE,
   -- list of file ids (fid)
   fids TEXT,
   pids TEXT
);
