---
# Spec: Edit Expense

## Overview
Allow users to edit an existing expense entry. This feature provides a form pre‑filled with the expense details, validates input, updates the database, and returns the user to their profile with updated totals.

## Depends on
Completion of steps 05 (Add Expense) and 06 (View Profile) as they provide the expense model and profile page where the edit link will appear.

## Routes
- `GET /expenses/<int:id>/edit` — render edit form for the specified expense — logged‑in
- `POST /expenses/<int:id>/edit` — process form submission, validate and update expense — logged‑in

## Database changes
No new tables or columns are required. Existing `expenses` table will be updated via an `UPDATE` statement.

## Templates
- **Create:** `templates/edit_expense.html` — extends `base.html` and contains a pre‑filled form mirroring the add‑expense form.
- **Modify:** `templates/profile.html` — add an “Edit” button/link next to each expense row pointing to the edit route.

## Files to change
- `app.py` — implement the two new route handlers.
- `templates/profile.html` — add edit link/button.

## Files to create
- `templates/edit_expense.html`

## New dependencies
No new dependencies.

## Rules for implementation
- No SQLAlchemy or ORMs
- Parameterised queries only
- Passwords hashed with werkzeug (already in place)
- Use CSS variables — never hardcode hex values
- All templates extend `base.html`

## Definition of done
- [ ] Edit button appears on each expense row in the profile page.
- [ ] Clicking the button loads a form pre‑filled with the expense data.
- [ ] Submitting valid changes updates the expense in the SQLite DB.
- [ ] Invalid input shows appropriate flash messages.
- [ ] After successful edit, user is redirected to the profile page with updated totals.
- [ ] Manual testing confirms the edited expense reflects in recent transactions and category breakdown.
---