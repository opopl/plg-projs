

CREATE TABLE IF NOT EXISTS tag_details (
-- e.g. ukraina
    tag TEXT NOT NULL,
-- e.g. Украина
    name TEXT,
-- e.g. rus, ukr, eng
    lang TEXT,
    detail TEXT
);
