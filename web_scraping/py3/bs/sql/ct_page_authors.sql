
CREATE TABLE IF NOT EXISTS page_authors (
    url TEXT,
    rid INTEGER,
    auth_id TEXT,
    FOREIGN KEY (url) REFERENCES pages(url)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (rid) REFERENCES pages(rid)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (auth_id) REFERENCES authors(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

