---
name: Database Setup Feature Specification
description: Specification document for implementing the database system setup UI in Spendly expense‑tracker.
type: reference
---

# Database System Setup Feature Specification

**Feature Title:** Database System Setup UI

**Owner:** (Assign owner)

**Target Release:** (Specify version or sprint)

---

## Overview

The **Database System Setup** feature adds a user‑friendly interface that allows administrators to configure, initialize, and manage the SQLite database used by the Spendly expense‑tracker application. This UI will provide the following capabilities:

1. **Initialize Database** – Create all tables defined in the data model.
2. **Migrate / Reset** – Drop and recreate the schema (useful during development or when performing a clean start).
3. **View Schema** – Display a read‑only overview of the current tables, columns, and constraints.
4. **Backup / Restore** – Export the SQLite file and import a previously exported backup.

The UI will be accessible via a new route **`/admin/db-setup`** and will be protected by **admin‑only** authentication (Flask‑Login with a role check).

---

## Requirements

### Functional Requirements

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| FR‑001 | Add **Database Setup** page under the admin dashboard. | The page loads at `/admin/db-setup` and displays the controls outlined below. |
| FR‑002 | Initialize database tables from models. | Clicking **"Initialize Database"** creates all tables if they do not exist and shows a success toast. |
| FR‑003 | Reset database (drop & recreate). | Clicking **"Reset Database"** prompts for confirmation, then drops all tables and runs `db.create_all()`. |
| FR‑004 | Show current schema. | A read‑only table lists each model, its columns, data types, and constraints. |
| FR‑005 | Backup database to a downloadable file. | Clicking **"Backup"** generates a `.sqlite` file download named `spendly_backup_<timestamp>.sqlite`. |
| FR‑006 | Restore database from uploaded file. | Uploading a valid `.sqlite` file replaces the current DB after confirmation and shows a success toast. |
| FR‑007 | Only users with `admin` role can access the page. | Non‑admin users are redirected to the login page with an error flash message. |

### Non‑Functional Requirements

* **Security:** All actions must be CSRF‑protected and require admin authentication.
* **Usability:** UI follows the existing design system (CSS variables from `style.css`). Buttons use the accent colors.
* **Performance:** Backup/restore operations must complete within 5 seconds for a DB ≤ 5 MB.
* **Reliability:** Errors (e.g., file upload failure) are presented via flash messages and logged.

---

## UI Mockup (Wireframe)

```
+-------------------------------------------+
| Admin Dashboard                           |
+-------------------------------------------+
| ▸ Database Setup                         |
+-------------------------------------------+

[Database Setup]

+-------------------------------------------+
| Current Schema                            |
|-------------------------------------------|
| User      | id, username, email, …        |
| Expense   | id, user_id, amount, …         |
+-------------------------------------------+

[Initialize Database]  [Reset Database]
[Backup]  [Restore (file upload)]
```

*(Replace with actual HTML/Jinja template when implemented.)*

---

## Database Schema (Reference)

The feature works with the existing models defined in `database/db.py`:

* **User** – `id`, `username`, `email`, `password_hash`, `created_at`
* **Expense** – `id`, `user_id`, `amount`, `category`, `description`, `date`, `created_at`

Any future schema changes should automatically appear in the **Current Schema** section because it queries the SQLAlchemy metadata.

---

## API / Backend Changes

1. **Routes** (`app.py` or a new blueprint `admin.py`)
   ```python
   @admin_bp.route('/db-setup', methods=['GET', 'POST'])
   @login_required
   @admin_required  # custom decorator that checks `current_user.is_admin`
   def db_setup():
       # Render template, handle form actions (init, reset, backup, restore)
       ...
   ```
2. **Helper Functions** (in `database/utils.py`)
   * `initialize_db()` – Calls `db.create_all()`.
   * `reset_db()` – Drops all tables then calls `initialize_db()`.
   * `backup_db()` – Copies `spendly.db` to a temporary file and streams it.
   * `restore_db(file_path)` – Replaces `spendly.db` with the uploaded file.
3. **Templates** – `templates/admin/db_setup.html` extending `base.html`.
4. **Static Assets** – Add any required JavaScript for confirmation dialogs.

---

## Testing Plan

* **Unit Tests** – Add tests for each helper function in `tests/test_db_utils.py`.
* **Integration Tests** – Use Flask’s test client to POST to `/admin/db-setup` actions and verify DB state.
* **Security Tests** – Ensure non‑admin users receive 302 redirects.

---

## Release Checklist

- [ ] Add admin role field to `User` model (if not existing).
- [ ] Implement `admin_required` decorator.
- [ ] Create blueprint `admin` and register it in `app.py`.
- [ ] Add HTML template `db_setup.html`.
- [ ] Write unit and integration tests.
- [ ] Update documentation (`README.md` → *Database Setup UI* section).
- [ ] Perform manual QA on Windows and Linux dev environments.

---

*Document created by Claude Code on 2026‑04‑14.*
