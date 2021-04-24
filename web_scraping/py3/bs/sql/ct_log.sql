
CREATE TABLE IF NOT EXISTS log (
     engine TEXT DEFAULT 'bs',
     rid INTEGER,
     url TEXT,
     site TEXT,
     msg TEXT,
     time TEXT
);
