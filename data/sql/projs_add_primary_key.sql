
CREATE TABLE IF NOT EXISTS projs_new (
    -- project id
    pid INTEGER PRIMARY KEY,
    -- file id
    fid INTEGER,
    -- project name
    proj TEXT NOT NULL, 
    file TEXT NOT NULL UNIQUE,
    root TEXT NOT NULL,
    sec TEXT, 
    tags TEXT, 
    parent TEXT,
    author TEXT,
    pic TEXT,
    rootid TEXT,
    url TEXT
);

INSERT INTO projs_new (
   	pid,fid,proj,file,root,sec,tags,parent,author,pic,rootid,url)
SELECT 
	pid,fid,proj,file,root,sec,tags,parent,author,pic,rootid,url
FROM projs
