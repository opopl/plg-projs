
CREATE TABLE IF NOT EXISTS tree_children (
    file_parent   TEXT NOT NULL,
    file_child    TEXT NOT NULL,
    FOREIGN KEY(file_parent) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(file_child) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE
);
