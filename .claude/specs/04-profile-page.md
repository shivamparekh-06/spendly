---
# Spec: Profile Page

## Overview
This feature replaces the /profile stub with a fully designed profile page showing static, hardcoded data. The goal is to establish the complete UI layout — user info card, transaction history table, summary stats, and category breakdown — before any real database queries are wired up in Step 5. Building the UI first lets the team validate the design in isolation and ensures the templates are ready for the backend-connection step.

## Depends on
- Step 1: Database setup (schema must exist)
- Step 2: Registration (user accounts must be creatable)
- Step 3: Login + Logout (session must be set; /profile must be a protected route)

## Routes
- `GET /profile` — renders the profile page — access level: logged‑in (requires `@login_required`).

## Database changes
No database changes.The existing users and expenses tables are sufficient.

## Templates
- Create: templates/profile.html — full profile page extending base.html; contains four sections:
  1.User info card — avatar initials, name, email, member-since date (all hardcoded)
  2.Summary stats row — total spent, number of transactions, top category (hardcoded)
  3.Transaction history table — list of recent expenses with date, description, category badge, amount (hardcoded rows)
  4.Category breakdown — per-category totals displayed as a simple list or progress-bar rows (hardcoded)

## Files to change
- `app.py` — import `login_required`, add `@login_required` to the `/profile` route, and render `profile.html` passing `current_user`.

## Files to create
- `templates/profile.html`

## New dependencies
No new dependencies.

## Rules for implementation
    - No SQLAlchemy or ORMs — use raw sqlite3 via get_db() if any DB call is ever needed
    - Parameterised queries only — never string-format SQL
    - Passwords hashed with werkzeug (no changes to auth in this step)
    -Use CSS variables — never hardcode hex values
    -All templates extend base.html
    -No inline styles
    -Authentication guard: check session.get("user_id"); if absent, redirect(url_for("login"))
    -All data passed to the template must be hardcoded Python dicts/lists in app.py — no DB queries in this step
    -Category badges must use a CSS class, not inline colour styles

## Definition of done
- [ ] `/profile` route returns `render_template('profile.html', user=current_user)` and is protected with `@login_required`.
- [ ] `profile.html` extends `base.html` and displays the logged‑in user's `name` and `email`.
- [ ] Manual test: log in, navigate to `/profile`, and verify the displayed information matches the logged‑in user.

-[]   Visiting /profile without being logged in redirects to /login
-[]   Visiting /profile while logged in returns HTTP 200
-[]   The page displays a user info card with a name and email
-[]   The page displays at least three summary stat values (e.g. total spent, transaction count, top category)
-[]   The page displays a transaction history table with at least three hardcoded rows
-[]   The page displays a category breakdown section with at least three categories
-[]   The navbar shows the logged-in state (username + logout link)
-[]   No hex colour values appear in profile.html — only CSS variables
---