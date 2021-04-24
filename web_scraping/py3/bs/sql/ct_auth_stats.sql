
CREATE TABLE IF NOT EXISTS auth_stats (
    auth_id TEXT NOT NULL UNIQUE,
    rank INTEGER,
    rids TEXT,
    FOREIGN KEY (auth_id) REFERENCES page_authors(auth_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
