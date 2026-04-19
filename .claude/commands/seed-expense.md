---
name: seed-expense
description: Seed realistic dummy expenses for a specific user
argument-hint: "<user_id> <months> <count>"
---

```bash
python - <<'PY'
"""Seed random expenses for a given user.
Usage: /seed-expense <user_id> <months> <count>
"""
import sys, random, datetime
from database.db import get_db

# Parse arguments
if len(sys.argv) != 4:
    print('Usage: /seed-expense <user_id> <months> <count>')
    sys.exit(1)
user_id = int(sys.argv[1])
months = int(sys.argv[2])
count = int(sys.argv[3])

conn = get_db()
cur = conn.cursor()
# Verify user exists
cur.execute('SELECT id FROM users WHERE id = ?', (user_id,))
if not cur.fetchone():
    print(f'No user found with id {user_id}.')
    sys.exit(0)

# Category definitions: (name, weight, (min, max))
categories = [
    ('Food & Dining', 30, (50, 800)),
    ('Transport', 15, (20, 500)),
    ('Bills', 10, (200, 3000)),
    ('Shopping', 12, (200, 5000)),
    ('Other', 8, (50, 1000)),
    ('Health', 5, (100, 2000)),
    ('Entertainment', 5, (100, 1500)),
]
weights = [c[1] for c in categories]

now = datetime.date.today()
start_date = now - datetime.timedelta(days=months * 30)
exp_records = []
for _ in range(count):
    cat, _, (low, high) = random.choices(categories, weights=weights, k=1)[0]
    amount = round(random.uniform(low, high), 2)
    rand_days = random.randint(0, (now - start_date).days)
    exp_date = start_date + datetime.timedelta(days=rand_days)
    description = f'Generated {cat.lower()} expense'
    exp_records.append((user_id, amount, cat, exp_date.isoformat(), description))

try:
    conn.execute('BEGIN')
    cur.executemany(
        'INSERT INTO expenses (user_id, amount, category, date, description) VALUES (?, ?, ?, ?, ?)',
        exp_records,
    )
    conn.commit()
except Exception as e:
    conn.rollback()
    print('Failed to insert expenses:', e)
    sys.exit(1)

# Confirmation
print(f'Inserted {len(exp_records)} expenses for user {user_id}.')
dates = [rec[3] for rec in exp_records]
print(f'Date range: {min(dates)} to {max(dates)}')
# Sample 5 recent records
cur.execute('SELECT id, amount, category, date, description FROM expenses WHERE user_id = ? ORDER BY date DESC LIMIT 5', (user_id,))
sample = cur.fetchall()
print('Sample records:')
for row in sample:
    print(dict(row))
PY
```
