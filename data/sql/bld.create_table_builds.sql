
CREATE TABLE IF NOT EXISTS builds (
    -- mandatory
    bid INTEGER UNIQUE NOT NULL PRIMARY KEY,
    
    cmd TEXT NOT NULL,
    proj TEXT NOT NULL,
    target TEXT NOT NULL,
    target_ext TEXT NOT NULL,
    plan TEXT NOT NULL,
    status TEXT NOT NULL,
    duration INTEGER NOT NULL,
    start INTEGER NOT NULL,

    -- optional
    sec  TEXT
);
