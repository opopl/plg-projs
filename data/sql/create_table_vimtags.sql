
CREATE TABLE IF NOT EXISTS vimtags (
    tag TEXT,
    tag_id INTEGER PRIMARY KEY,
    proj TEXT NOT NULL, 
    rootid TEXT
);
