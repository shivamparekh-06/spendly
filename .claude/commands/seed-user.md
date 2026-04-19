---
name: seed-user
description: Seed the SQLite database with dummy users and expenses for development/testing
---

```bash
python - <<'PY'
"""Insert dummy data into the Spendly SQLite database.
Uses the helper functions defined in `database/db.py` (sqlite3 based).
"""
import sqlite3
from werkzeug.security import generate_password_hash
from datetime import date
from pathlib import Path

# Resolve DB path (same logic as in db.py)
BASE_DIR = Path(__file__).resolve().parents[2]
DB_PATH = BASE_DIR / "spendly.db"

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# Optional: clear existing data
cur.execute("DELETE FROM expenses")
cur.execute("DELETE FROM users")
conn.commit()

# Insert dummy users
users = [
    ("alice", "alice@example.com", generate_password_hash("password123")),
    ("bob", "bob@example.com", generate_password_hash("securepass")),
]
cur.executemany("INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)", users)
conn.commit()

# Get inserted user ids
cur.execute("SELECT id, name FROM users")
user_map = {name: uid for uid, name in cur.fetchall()}

# Insert dummy expenses
expenses = [
    (user_map["alice"], 125.5, "Food & Dining", date.today().isoformat(), "Dinner at restaurant"),
    (user_map["alice"], 45.0, "Transport", date.today().isoformat(), "Taxi"),
    (user_map["bob"], 300.0, "Shopping", date.today().isoformat(), "Clothes"),
    (user_map["bob"], 80.0, "Entertainment", date.today().isoformat(), "Movie tickets"),
]
cur.executemany(
    "INSERT INTO expenses (user_id, amount, category, date, description) VALUES (?, ?, ?, ?, ?)",
    expenses,
)
conn.commit()
print("Database seeded with dummy users and expenses.")
PY
```
