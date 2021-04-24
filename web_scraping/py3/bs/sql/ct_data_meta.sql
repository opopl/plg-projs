
CREATE TABLE IF NOT EXISTS data_meta (
    rid INTEGER UNIQUE,
    url TEXT UNIQUE NOT NULL,
    src TEXT,
    og_url TEXT
);
