---
# Spec: Delete Expense

## Overview
The delete expense feature allows users to remove an expense record from their profile. This is step 8 in the Spendly roadmap, enabling users to correct mistakes or remove outdated entries, thereby maintaining accurate expense tracking.

## Depends on
This feature depends on the existing expense model and the profile page where expenses are listed (step 4 and 5). It also depends on the authentication system (step 2 and 3) to ensure only the owner can delete their expenses.

## Routes
No new routes.

## Database changes
No database changes.

## Templates
- **Create:** `templates/delete_expense.html`
- **Modify:** `templates/profile.html` — Add delete button in the actions column of the recent transactions table.

## Files to change
- `app.py` — Implement delete expense logic (handle GET and POST on existing route)
- `templates/profile.html` — Add delete button in the actions column
- `templates/delete_expense.html` — New template for delete confirmation

## Files to create
- `templates/delete_expense.html`

## New dependencies
No new dependencies.

## Rules for implementation
- No SQLAlchemy or ORMs
- Parameterised queries only
- Passwords hashed with werkzeug
- Use CSS variables — never hardcode hex values
- All templates extend `base.html`

## Definition of done
- [ ] User can click a delete button next to an expense in the profile page.
- [ ] Clicking delete shows a confirmation page asking to confirm deletion.
- [ ] Upon confirmation, the expense is removed from the database and the user is redirected to the profile page.
- [ ] If the user cancels, they are redirected back to the profile page.
- [ ] Only the owner of the expense can delete it (validation).
- [ ] After deletion, the profile page updates to reflect the removed expense.
- [ ] Attempting to delete an expense that doesn't exist or belongs to another user shows an error (or redirects with a message).
- [ ] The delete operation uses parameterized queries to prevent SQL injection.