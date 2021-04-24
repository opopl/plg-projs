
CREATE TABLE IF NOT EXISTS page_pics (
    rid INTEGER,
    url TEXT,
    pic_url TEXT,
    FOREIGN KEY (rid) REFERENCES pages(rid)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (url) REFERENCES pages(url)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);
