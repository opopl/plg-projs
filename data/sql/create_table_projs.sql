
CREATE TABLE IF NOT EXISTS projs (
    -- project id
    pid INTEGER,
    -- file id
    fid INTEGER PRIMARY KEY,
    -- project name
    proj TEXT NOT NULL, 
    file TEXT NOT NULL UNIQUE,
    sec TEXT, 
    tags TEXT, 
    -- parent section name
    parent TEXT,
    projtype TEXT,
    author_id TEXT,
    -- section id
    id TEXT,
    pic TEXT,
    rootid TEXT,
    url TEXT,
    title TEXT,
    date TEXT
);

-- ALTER TABLE projs ADD COLUMN url TEXT;
-- ALTER TABLE projs ADD COLUMN fid INTEGER;
-- ALTER TABLE projs ADD COLUMN pid INTEGER;
-- ALTER TABLE projs ADD COLUMN projtype TEXT;
