
CREATE TABLE IF NOT EXISTS _info_projs_author_id (
    file TEXT NOT NULL,
    author_id TEXT NOT NULL,
    FOREIGN KEY(file) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE
);
