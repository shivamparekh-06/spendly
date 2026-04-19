---
name: init-db
description: Initialize the SQLite database schema for Spendly
---

```bash
python - <<'PY'
"""Create the SQLite tables for Spendly if they don't exist.
Uses the `init_db` function from `database/db.py`.
"""
from database.db import init_db
init_db()
print('Database schema initialized.')
PY
```
