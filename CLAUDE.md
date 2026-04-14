# Spendly - Project Guide

## Project Overview

**Spendly** is a Flask-based expense tracking web application for the Indian market. It allows users to log expenses, categorize them, and visualize spending patterns over time.

- **Target Users**: Individuals who want to track personal expenses
- **Market**: India (rupees as currency)
- **Pricing**: Free forever

---

## Project Structure

```
spendly/
├── app.py                    # Main Flask application entry point
├── requirements.txt          # Python dependencies
├── CLAUDE.md                 # This file
├── database/
│   ├── __init__.py
│   └── db.py                 # Database models and initialization
├── static/
│   ├── css/
│   │   └── style.css        # Global styles
│   └── js/
│       └── main.js          # Frontend JavaScript
└── templates/
    ├── base.html            # Base layout template
    ├── landing.html         # Landing/marketing page
    ├── login.html           # Login page
    ├── register.html        # Registration page
    ├── terms.html           # Terms of service
    └── privacy.html         # Privacy policy
```

---

## Technology Stack

- **Backend**: Flask 3.x (Python)
- **Database**: SQLite with SQLAlchemy
- **Authentication**: Flask-Login
- **Forms**: Flask-WTF
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Font**: DM Sans (Google Fonts)
- **Icons**: None (text-based for simplicity)

---

## Design System

### Colors (CSS Variables)

```css
:root {
    --color-primary: #0F172A;      /* Dark slate - headings, text */
    --color-primary-light: #1E293B;
    --color-background: #F8FAFC;  /* Page background */
    --color-surface: #FFFFFF;     /* Card backgrounds */
    --color-accent: #22C55E;      /* Green - primary actions */
    --color-accent-hover: #16A34A;
    --color-accent-light: #DCFCE7;
    --color-secondary: #3B82F6;  /* Blue - secondary actions */
    --color-secondary-light: #DBEAFE;
    --color-text: #0F172A;
    --color-text-secondary: #64748B;
    --color-text-muted: #94A3B8;
    --color-border: #E2E8F0;
    --color-danger: #EF4444;     /* Red - delete, errors */
}
```

### Typography

- **Font Family**: DM Sans (Google Fonts)
- **Headings**: 700 weight
- **Body**: 400 weight, 16px base
- **Small**: 14px

### Spacing

- **Base unit**: 4px
- **Common values**: 8px, 12px, 16px, 24px, 32px, 48px

### Border Radius

- `--radius-sm`: 6px
- `--radius-md`: 8px
- `--radius-lg`: 12px
- `--radius-xl`: 16px

### Shadows

- `--shadow-sm`: 0 1px 2px rgba(0,0,0,0.05)
- `--shadow-md`: 0 4px 6px -1px rgba(0,0,0,0.1)
- `--shadow-lg`: 0 10px 15px -3px rgba(0,0,0,0.1)

---

## Database Schema

### User Model

| Field | Type | Constraints |
|-------|------|-------------|
| id | Integer | Primary Key, Auto-increment |
| username | String(80) | Unique, Not Null |
| email | String(120) | Unique, Not Null |
| password_hash | String(256) | Not Null |
| created_at | DateTime | Default: now() |

### Expense Model

| Field | Type | Constraints |
|-------|------|-------------|
| id | Integer | Primary Key, Auto-increment |
| user_id | Integer | Foreign Key → User.id |
| amount | Float | Not Null |
| category | String(50) | Not Null |
| description | String(200) | Optional |
| date | Date | Not Null |
| created_at | DateTime | Default: now() |

### Default Categories

1. Food & Dining
2. Transport
3. Shopping
4. Entertainment
5. Bills & Utilities
6. Healthcare
7. Education
8. Other

---

## Coding Conventions

### Python

- Use f-strings for string formatting
- Use type hints where helpful
- 4 spaces for indentation
- Snake_case for variables and functions
- PascalCase for classes

### HTML/Jinja2

- Use semantic HTML5 elements
- Include proper meta tags for accessibility
- Inline page-specific CSS in `{% block extra_head %}` when needed

### CSS

- Use CSS custom properties (variables) for colors, spacing
- Follow BEM-like naming for complex components
- Mobile-first responsive design

### Forms

- Use Flask-WTF for form handling
- Include CSRF protection
- Show validation errors inline

---

## Common Tasks

### Running the App

```bash
# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Run development server
python app.py
```

The app runs at `http://127.0.0.1:5000`

### Creating a New Template

1. Create HTML file in `templates/`
2. Extend `base.html`
3. Use Jinja2 blocks: `{% block content %}{% endblock %}`

### Adding a New Route

```python
@app.route('/path')
@login_required  # If authentication needed
def view_name():
    return render_template('template.html', data=...)
```

### Adding a New Model

1. Add class to `database/db.py`
2. Import and use in routes: `from database.db import User, Expense`
3. Create tables: `with app.app_context(): db.create_all()`

### Adding CSS Styles

1. Edit `static/css/style.css` for global styles
2. Or add page-specific styles in template's `{% block extra_head %}`

---

## Routes

| Route | Method | Auth | Description |
|-------|--------|------|-------------|
| `/` | GET | No | Landing page |
| `/register` | GET/POST | No | User registration |
| `/login` | GET/POST | No | User login |
| `/logout` | GET | Yes | Logout |
| `/dashboard` | GET | Yes | Main dashboard |
| `/add` | GET/POST | Yes | Add new expense |
| `/delete/<id>` | POST | Yes | Delete expense |

---

## Important Notes

- All monetary amounts are in **Indian Rupees (₹)**
- Date format: `DD MMMM YYYY` (e.g., "15 November 2024")
- Passwords are hashed using Werkzeug's security functions
- Session-based authentication with Flask-Login
- Flash messages for user feedback (success/error)

---

## Future Enhancements (Suggested)

- Edit expense functionality
- Monthly/yearly summary reports
- Export data to CSV
- Budget setting and alerts
- Recurring expenses
- Multiple currencies
- Dark mode
- Mobile app (PWA)

---

## Troubleshooting

### Database Issues

```python
# Recreate database
from app import app
from database.db import db

with app.app_context():
    db.drop_all()
    db.create_all()
```

### Port Already in Use

Change port in `app.py`:
```python
app.run(debug=True, port=5001)
```