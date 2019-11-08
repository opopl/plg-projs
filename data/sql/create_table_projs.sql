
CREATE TABLE IF NOT EXISTS projs (
    proj text not null, 
    file text not null unique,
    root text not null,
    sec text, 
    tags text, 
    parent text,
    author text,
    pic text,
    rootid text 
);
