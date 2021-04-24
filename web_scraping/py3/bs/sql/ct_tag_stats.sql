
CREATE TABLE IF NOT EXISTS tag_stats (
    tag TEXT NOT NULL UNIQUE,
    rank INTEGER,
    rids TEXT,
    FOREIGN KEY (tag) REFERENCES page_tags(tag)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
