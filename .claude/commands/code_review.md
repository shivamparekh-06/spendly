---
description: Run security audit + code quality review on the Spendly codebase
---

# /code_review

Runs a two-agent pipeline that first performs a full OWASP-aligned security audit, then does a code quality and maintainability review. Each agent produces its own report.

## Pipeline

**Step 1 — Security Reviewer** (`security-reviewer` agent)
- Reads `app.py`, `database/db.py`, all templates, `.gitignore`, `requirements.txt`, `static/js/main.js`
- Audits against OWASP Top 10 (2021): broken access control, cryptographic failures, injection, insecure design, misconfiguration, auth failures, logging gaps
- Writes `security-report.md` with severity-rated findings, exploit scenarios, and copy-paste fixes

**Step 2 — Quality Reviewer** (`quality-reviewer` agent)
- Receives security report context — does NOT duplicate security findings
- Reviews: Flask best practices, Blueprint structure, DB layer, template quality, frontend consistency, project structure, error handling
- Writes `quality-report.md` with a scored card per category and a prioritised refactoring roadmap

## Output

- `security-report.md` — OWASP findings rated CRITICAL / HIGH / MEDIUM / LOW with fixes
- `quality-report.md` — quality score per category + week-by-week refactoring roadmap

## Usage

```bash
claude /code_review
```

## Steps

1. Use the agent `security-reviewer` to audit the full codebase and write `security-report.md`.
2. Pass the security report to the agent `quality-reviewer` to review code quality and write `quality-report.md`.
