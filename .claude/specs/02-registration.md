---
# Spec: Registration

## Overview
Implement user registration allowing new users to create an account with name, email, and password. This enables onboarding for the Spendly expense tracker.

## Depends on
Step 01 – Database setup (users table must exist).

## Routes
- `GET /register` — render registration page — public
- `POST /register` — process registration form, create user, redirect to login — public

## Database changes
No database changes needed; uses existing `users` table.

## Templates
- **Modify:** `templates/register.html` — ensure it displays validation errors and retains submitted values.

## Files to change
- `app.py` — add POST handling for `/register`, validate input, hash password, insert user with parameterised query, flash messages, and redirect.

## Files to create
- None

## New dependencies
No new dependencies.

## Rules for implementation
- No SQLAlchemy or ORMs; use raw parameterised SQLite queries via helper functions.
- Parameterised queries only.
- Passwords must be hashed with `werkzeug.security.generate_password_hash`.
- Use CSS variables — never hardcode hex values.
- All templates extend `base.html`.

## Definition of done
- [ ] Visiting `/register` shows the registration form.
- [ ] Submitting valid data creates a new user in the database.
- [ ] Password is stored hashed, not plain text.
- [ ] Duplicate email shows an error message.
- [ ] After successful registration, user is redirected to `/login`.
- [ ] All new code passes linting and the app runs without errors.
---