CREATE TABLE IF NOT EXISTS page_tags (
    url TEXT,
    rid INTEGER,
    tag TEXT,
    FOREIGN KEY (url) REFERENCES pages(url)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (rid) REFERENCES pages(rid)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
