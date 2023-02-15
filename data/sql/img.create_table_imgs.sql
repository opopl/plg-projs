
CREATE TABLE IF NOT EXISTS imgs (
     url TEXT UNIQUE,
     url_parent TEXT,
     inum INTEGER UNIQUE,
     tags TEXT,
     rootid TEXT,
     proj TEXT,
     sec TEXT,
     img TEXT,
     caption TEXT,
     ext TEXT,
     type TEXT,
     md5 TEXT UNIQUE,
     name TEXT,
     name_uniq TEXT UNIQUE,
     width INTEGER,
     height INTEGER,
     width_tex TEXT,
     size INTEGER,
     mtime INTEGER
);
