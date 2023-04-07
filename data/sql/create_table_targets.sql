
CREATE TABLE IF NOT EXISTS targets (
    tid INTEGER PRIMARY KEY,
    proj TEXT NOT NULL,
    target TEXT NOT NULL,
    options TEXT
);
