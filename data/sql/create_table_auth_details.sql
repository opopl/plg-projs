
CREATE TABLE IF NOT EXISTS auth_details (
    id  TEXT NOT NULL,
    telegram    TEXT,
    instagram   TEXT,
    twitter TEXT,
    www TEXT,
    pic_portrait    TEXT,
    fb_url  TEXT,
    fb_id   TEXT,
    fb_desc TEXT,
    fb_front    TEXT,
    fb_pic_portrait TEXT,
    fb_pic_background   TEXT,
    fb_pic_other    TEXT,
    yz_id   TEXT,
    fb_group_id TEXT,
    FOREIGN KEY(id) REFERENCES authors(id) ON DELETE CASCADE ON UPDATE CASCADE
);
