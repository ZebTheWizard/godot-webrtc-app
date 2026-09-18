-- Up
CREATE TABLE players (
    id TEXT PRIMARY KEY NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password TEXT NOT NULL,
    client_id INTEGER UNIQUE,
	is_host BOOLEAN NOT NULL DEFAULT 0,
    team INTEGER,
    match_id TEXT,
    FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE SET NULL
);

-- Down
DROP TABLE players;
