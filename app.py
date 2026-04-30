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

@app.route("/profile")
@login_required
def profile():
    return render_template('profile.html', user=current_user)

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
