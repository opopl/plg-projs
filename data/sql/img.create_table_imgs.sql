
CREATE TABLE IF NOT EXISTS imgs (
     url TEXT UNIQUE,
     url_parent TEXT,
     inum INTEGER,
     tags TEXT,
     rootid TEXT,
     proj TEXT,
     sec TEXT,
     img TEXT,
     caption TEXT,
     ext TEXT,
     type TEXT,
     md5 TEXT,
     name TEXT,
     name_uniq TEXT UNIQUE,
     WIDTH INTEGER,
     HEIGHT INTEGER,
     WIDTH_TEX TEXT,
     size INTEGER,
     mtime INTEGER
);
