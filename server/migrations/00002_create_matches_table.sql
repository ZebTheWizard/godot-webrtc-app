-- Up
CREATE TABLE matches (
    id TEXT PRIMARY KEY NOT NULL UNIQUE,
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    map TEXT NOT NULL,
    status TEXT NOT NULL,
    type TEXT NOT NULL,
	host_id TEXT NOT NULL,
	FOREIGN KEY (host_id) REFERENCES players(id) ON DELETE CASCADE
);

-- Down
DROP TABLE matches;
