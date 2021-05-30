
CREATE TABLE IF NOT EXISTS pages (
    baseurl TEXT,
    host TEXT,
    rid INTEGER UNIQUE,
    url TEXT UNIQUE NOT NULL,
    date TEXT,
    title TEXT,
    title_h TEXT,
    site TEXT,
    ii TEXT,
    ii_num INTEGER,
    ii_full TEXT,
    author_id TEXT,
    author_id_first TEXT,
    author_bare TEXT,
    tags TEXT,
    encoding TEXT,
    ok INTEGER,
    phrases TEXT,
    notes TEXT
);

