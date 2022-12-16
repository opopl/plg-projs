
CREATE TABLE IF NOT EXISTS saved (
    file TEXT NOT NULL UNIQUE,

    done INTEGER DEFAULT 0,
    done_html_orig INTEGER DEFAULT 0,
    done_html_view INTEGER DEFAULT 0,
    done_html_unwrap INTEGER DEFAULT 0,
    done_html_parse INTEGER DEFAULT 0,
    done_html_content INTEGER DEFAULT 0,
    -- optional - there may be no comments
    done_html_comments INTEGER DEFAULT 0,

    -- ? inserted content into tex-section
    done_tex_content_insert INTEGER DEFAULT 0,

    --- import imgs into db
    done_import_img INTEGER DEFAULT 0,

    FOREIGN KEY(file) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE
);
