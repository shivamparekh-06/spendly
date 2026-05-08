from flask import Flask, render_template, request, redirect, url_for, flash
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from database.db import init_db, seed_db, get_db, login_manager, User, get_user_by_email

app = Flask(__name__)
app.secret_key = 'dev-secret'  # In production, use a secure env variable

# Initialize Flask-Login
login_manager.init_app(app)

# Initialize database
with app.app_context():
    init_db()
    seed_db()

# ------------------------------------------------------------------ #
# Routes                                                              #
# ------------------------------------------------------------------ #

@app.route("/")
def landing():
    return render_template("landing.html")

@app.route("/register", methods=["GET", "POST"])
def register():
    # Allow access to registration page even if already logged in
    if request.method == "POST":
        name = request.form.get('name', '').strip()
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')

        # Basic validation
        if not name or not email or not password:
            flash('All fields are required.', 'error')
            return render_template('register.html')
        if len(password) < 8:
            flash('Password must be at least 8 characters.', 'error')
            return render_template('register.html')

        db = get_db()
        # Check for existing email
        existing = db.execute('SELECT id FROM users WHERE email = ?', (email,)).fetchone()
        if existing:
            flash('An account with that email already exists.', 'error')
            return render_template('register.html')

        # Insert new user
        password_hash = generate_password_hash(password)
        db.execute(
            'INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)',
            (name, email, password_hash)
        )
        db.commit()
        flash('Registration successful. Please log in.', 'success')
        return redirect(url_for('login'))
    # GET request
    return render_template('register.html')

@app.route("/login", methods=["GET", "POST"])
def login():
    # Redirect authenticated users away from login page
    if current_user.is_authenticated:
        return redirect(url_for('landing'))
    if request.method == "POST":
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')
        user_row = get_user_by_email(email)
        if user_row and check_password_hash(user_row['password_hash'], password):
            login_user(User(user_row['id'], user_row['name'], user_row['email'], user_row['password_hash']))
            flash('Successfully logged in', 'success')
            return redirect(url_for('landing'))
        else:
            flash('Invalid email or password.', 'error')
    return render_template("login.html")

# ------------------------------------------------------------------ #
# Placeholder routes — students will implement these                  #
# ------------------------------------------------------------------ #

@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash('You have been logged out.', 'success')
    return redirect(url_for('landing'))

from datetime import datetime, timedelta

@app.route("/profile")
@login_required
def profile():
    # Gather statistics for the logged‑in user with optional date filter
    db = get_db()
    user_id = current_user.id

    # Parse and validate date range from query parameters
    date_from_str = request.args.get('date_from')
    date_to_str = request.args.get('date_to')
    date_from = None
    date_to = None
    error = None
    if date_from_str:
        try:
            date_from = datetime.strptime(date_from_str, "%Y-%m-%d").date()
        except ValueError:
            date_from = None
    if date_to_str:
        try:
            date_to = datetime.strptime(date_to_str, "%Y-%m-%d").date()
        except ValueError:
            date_to = None
    if date_from and date_to and date_from > date_to:
        error = "Start date must be before end date."
        date_from = date_to = None
    if error:
        flash(error, 'error')

    # Helper to add date filter clause
    def date_clause():
        if date_from and date_to:
            return " AND date BETWEEN ? AND ?", (date_from_str, date_to_str)
        if date_from and not date_to:
            return " AND date >= ?", (date_from_str,)
        if date_to and not date_from:
            return " AND date <= ?", (date_to_str,)
        return "", ()

    # Total spent & transaction count
    clause, params = date_clause()
    total_row = db.execute(
        f'SELECT SUM(amount) AS total, COUNT(*) AS cnt FROM expenses WHERE user_id = ?{clause}',
        (user_id, *params)
    ).fetchone()
    total_spent = total_row['total'] or 0
    tx_count = total_row['cnt'] or 0

    # Recent transactions (latest 5)
    clause, params = date_clause()
    recent_tx_rows = db.execute(
        f'SELECT date, description, category, amount FROM expenses WHERE user_id = ?{clause} ORDER BY date DESC LIMIT 5',
        (user_id, *params)
    ).fetchall()
    recent_tx = [dict(row) for row in recent_tx_rows]
    # Fallback to unfiltered if filtered result empty
    if date_from and date_to and not recent_tx:
        recent_tx_rows = db.execute(
            'SELECT date, description, category, amount FROM expenses WHERE user_id = ? ORDER BY date DESC LIMIT 5',
            (user_id,)
        ).fetchall()
        recent_tx = [dict(row) for row in recent_tx_rows]

    # Category breakdown – amount and percentage
    clause, params = date_clause()
    cat_rows = db.execute(
        f'SELECT category, SUM(amount) AS amt FROM expenses WHERE user_id = ?{clause} GROUP BY category',
        (user_id, *params)
    ).fetchall()
    # Fallback to unfiltered if filtered result empty
    if date_from and date_to and not cat_rows:
        cat_rows = db.execute(
            'SELECT category, SUM(amount) AS amt FROM expenses WHERE user_id = ? GROUP BY category',
            (user_id,)
        ).fetchall()
    total_for_pct = total_spent or 1  # avoid division by zero
    category_breakdown = []
    for row in cat_rows:
        pct = round((row['amt'] / total_for_pct) * 100, 1)
        category_breakdown.append((row['category'], row['amt'], pct))

    # Top category (by amount)
    top_category = max(cat_rows, key=lambda r: r['amt'])['category'] if cat_rows else '—'

    # Compute preset date ranges for template
    today = datetime.today().date()
    start_of_month = today.replace(day=1)
    three_months_ago = (today - timedelta(days=90)).replace(day=1)
    six_months_ago = (today - timedelta(days=180)).replace(day=1)

    return render_template(
        'profile.html',
        user=current_user,
        total_spent=total_spent,
        tx_count=tx_count,
        top_category=top_category,
        recent_tx=recent_tx,
        category_breakdown=category_breakdown,
        # Pass date filter state
        date_from=date_from_str or '',
        date_to=date_to_str or '',
        # Preset ranges
        this_month_start=start_of_month.isoformat(),
        this_month_end=today.isoformat(),
        last_3_months_start=three_months_ago.isoformat(),
        last_3_months_end=today.isoformat(),
        last_6_months_start=six_months_ago.isoformat(),
        last_6_months_end=today.isoformat(),
    )

@app.route("/analytics")
@login_required
def analytics():
    return render_template("analytics.html")

@app.route("/expenses/add")
def add_expense():
    return "Add expense — coming in Step 7"

@app.route("/expenses/<int:id>/edit")
def edit_expense(id):
    return "Edit expense — coming in Step 8"

@app.route("/expenses/<int:id>/delete")
def delete_expense(id):
    return "Delete expense — coming in Step 9"

@app.route("/terms")
def terms():
    return render_template("terms.html")

@app.route("/privacy")
def privacy():
    return render_template("privacy.html")

if __name__ == "__main__":
    app.run(debug=True, port=5001)
