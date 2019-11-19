
CREATE TABLE IF NOT EXISTS projs (
    -- project id
    pid INTEGER,
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
    rootid TEXT 
);
