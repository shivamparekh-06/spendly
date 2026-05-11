---
description: Write and run a full pytest suite for all Spendly features
---

# /test_feature

Runs a two-agent pipeline that first writes a complete pytest test suite for all implemented Spendly features, then executes it and produces a structured pass/fail report.

## Pipeline

**Step 1 — Test Writer** (`test-writer` agent)
- Reads `app.py`, `database/db.py`, and `requirements.txt`
- Writes `tests/conftest.py`, `tests/test_auth.py`, `tests/test_expenses.py`, `tests/test_routes.py`, `tests/test_models.py`
- Covers: authentication, expense CRUD, dashboard, public routes, DB models

**Step 2 — Test Runner** (`test-runner` agent)
- Installs pytest dependencies if missing
- Runs the full suite with coverage: `pytest tests/ -v --tb=short --cov=.`
- Re-runs each failed test in isolation for clean error output
- Writes `test-report.md` with root cause analysis and exact line-level fixes

## Output

- `tests/` — complete pytest suite (created by test-writer)
- `test-report.md` — structured report with pass/fail summary, coverage table, and actionable fixes

## Usage

```bash
claude /test_feature
```

## Steps

1. Use the agent `test-writer` to analyse the codebase and write the full pytest suite.
2. Pass the test-writer summary to the agent `test-runner` to execute all tests and produce `test-report.md`.
