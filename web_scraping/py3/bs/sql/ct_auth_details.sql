
CREATE TABLE IF NOT EXISTS auth_details (
    id TEXT NOT NULL,
    telegram TEXT,
    instagram TEXT,
    twitter TEXT,
    www TEXT,
    pic_portrait TEXT,
    -- facebook data
    fb_url TEXT,
    fb_id TEXT,
    fb_desc TEXT,
    fb_front TEXT,
    fb_pic_portrait TEXT,
    fb_pic_background TEXT,
    fb_pic_other TEXT,
    -- yandex zen id
    yz_id TEXT
);
