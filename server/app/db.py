# SQLite setup. The database file is created automatically on first start.
#
# To add your own entity: add a CREATE TABLE below, then copy the pattern
# of app/notes.py for its routes.

import sqlite3
import os
from datetime import datetime, timezone
from pathlib import Path

# The project folder (the one holding requirements.txt), regardless of the
# current working directory — so app.db always lands in the same place.
BASE_DIR = Path(os.environ.get('PAM_DATA_DIR', Path(__file__).resolve().parent.parent)).resolve()
BASE_DIR.mkdir(parents=True, exist_ok=True)

_SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  email         TEXT    NOT NULL UNIQUE,
  password_hash TEXT    NOT NULL,
  name          TEXT    NOT NULL,
  created_at    TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users (id),
  title      TEXT    NOT NULL,
  content    TEXT    NOT NULL DEFAULT '',
  created_at TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS files (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users (id),
  name       TEXT    NOT NULL,
  mime_type  TEXT    NOT NULL,
  size       INTEGER NOT NULL,
  path       TEXT    NOT NULL,
  created_at TEXT    NOT NULL
);
"""

# The single database connection, opened (and the schema applied) at import
# time. All route handlers are `async def`, so they all run on the event
# loop's single thread — one shared connection is safe here.
# isolation_level=None = autocommit: every INSERT/UPDATE/DELETE is written
# to disk immediately, which is what gives persistence across restarts.
conn = sqlite3.connect(
    BASE_DIR / "app.db", check_same_thread=False, isolation_level=None
)
conn.row_factory = sqlite3.Row  # rows behave like dicts: row["title"]
conn.executescript(_SCHEMA)


def now_iso():
    """Current UTC time in ISO-8601, the format used for all timestamps."""
    return (
        datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )

# LostFound additions. Existing template tables/routes stay compatible.
conn.execute("PRAGMA foreign_keys = ON")
conn.create_function("casefold", 1, lambda value: (value or "").casefold(), deterministic=True)
conn.executescript("""
CREATE TABLE IF NOT EXISTS items (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user_id INTEGER NOT NULL REFERENCES users(id),
 type TEXT NOT NULL CHECK(type IN ('lost','found')),
 title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '',
 image_url TEXT NOT NULL DEFAULT '', location TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','returned')),
 created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS claims (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
 user_id INTEGER NOT NULL REFERENCES users(id),
 message TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','discussion','closed'))
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_claim
 ON claims(item_id,user_id) WHERE status != 'closed';
CREATE TABLE IF NOT EXISTS messages (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 claim_id INTEGER NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
 sender_id INTEGER NOT NULL REFERENCES users(id),
 text TEXT NOT NULL, sent_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS items_place_type ON items(location,type,id);
CREATE INDEX IF NOT EXISTS messages_thread ON messages(claim_id,id);
""")
