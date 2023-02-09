
CREATE TABLE IF NOT EXISTS projs (
    -- project id
    pid INTEGER,
    -- file id
    fid INTEGER PRIMARY KEY,
    -- project name
    proj TEXT NOT NULL,
    file TEXT NOT NULL UNIQUE,
    sec TEXT NOT NULL,
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
    date TEXT,
    options TEXT,
    bookmark TEXT
);

-- ALTER TABLE projs ADD COLUMN options TEXT;
