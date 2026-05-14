import pytest
from database import db


def test_init_db_creates_tables(app):
    """Test that init_db creates the required tables."""
    with app.app_context():
        # Check that users table exists
        conn = db.get_db()
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        assert cur.fetchone() is not None

        # Check that expenses table exists
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'")
        assert cur.fetchone() is not None

        conn.close()


def test_seed_db_creates_demo_user_and_expenses(app):
    """Test that seed_db creates a demo user and sample expenses."""
    with app.app_context():
        # Check that demo user exists
        user = db.get_user_by_email("demo@spendly.com")
        assert user is not None
        assert user['name'] == "Demo User"
        assert user['email'] == "demo@spendly.com"
        # Check that password_hash exists (sqlite3.Row supports key access but not 'in' operator)
        assert user['password_hash'] is not None
        assert len(user['password_hash']) > 0

        # Check that sample expenses were created
        conn = db.get_db()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) as count FROM expenses WHERE user_id = ?", (user['id'],))
        count = cur.fetchone()['count']
        assert count > 0  # Should have seeded expenses

        # Check a few specific sample expenses
        cur.execute("SELECT amount, category, date, description FROM expenses WHERE user_id = ? LIMIT 1", (user['id'],))
        expense = cur.fetchone()
        assert expense is not None
        assert expense['amount'] == 2500.0
        assert expense['category'] == "Food & Dining"
        assert expense['date'] == "2026-04-01"
        assert expense['description'] == "Groceries"

        conn.close()


def test_get_user_by_email_returns_none_for_nonexistent_user(app):
    """Test that get_user_by_email returns None for non-existent email."""
    with app.app_context():
        user = db.get_user_by_email("nonexistent@example.com")
        assert user is None


def test_user_model_init():
    """Test User model initialization."""
    from database.db import User
    user = User(1, "Test User", "test@example.com", "hash123")
    assert user.id == 1
    assert user.name == "Test User"
    assert user.email == "test@example.com"
    assert user.password_hash == "hash123"


def test_user_model_check_password():
    """Test User model password checking."""
    from database.db import User
    from werkzeug.security import generate_password_hash

    password_hash = generate_password_hash("testpassword")
    user = User(1, "Test User", "test@example.com", password_hash)

    assert user.check_password("testpassword") == True
    assert user.check_password("wrongpassword") == False