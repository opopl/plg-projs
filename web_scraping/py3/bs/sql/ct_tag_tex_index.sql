

CREATE TABLE IF NOT EXISTS tag_tex_index (
    tag TEXT NOT NULL,
-- e.g. rus, names.rus
    ind_name TEXT,
-- e.g. aa!bb
    ind_entry TEXT
);
