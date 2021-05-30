
CREATE TABLE IF NOT EXISTS authors (
    id TEXT NOT NULL UNIQUE,
    url TEXT,
    name TEXT,
    plain TEXT,
    description TEXT
);
