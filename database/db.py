# Database setup for Spendly application
# Implements SQLite connection, schema creation, and demo data seeding.

import os
import sqlite3
from werkzeug.security import generate_password_hash

# Path to the SQLite database file (project root)
_DB_PATH = os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")), "spendly.db")


def _execute(sql, params=()):
    """Helper to execute a parameterized query and return the cursor."""
    conn = get_db()
    cur = conn.cursor()
    cur.execute(sql, params)
    conn.commit()
    return cur


def get_db():
    """Return a SQLite connection with row_factory set and foreign keys enabled."""
    conn = sqlite3.connect(_DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db():
    """Create users and expenses tables if they do not exist."""
    conn = get_db()
    cur = conn.cursor()
    # Users table
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        )
        """
    )
    # Expenses table
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            description TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        """
    )
    conn.commit()


def seed_db():
    """Insert a demo user and sample expenses if they are not already present."""
    conn = get_db()
    cur = conn.cursor()
    # Check for existing demo user
    cur.execute("SELECT id FROM users WHERE email = ?", ("demo@spendly.com",))
    row = cur.fetchone()
    if row:
        return  # Demo data already seeded

    # Insert demo user
    password_hash = generate_password_hash("demo123")
    cur.execute(
        "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)",
        ("Demo User", "demo@spendly.com", password_hash),
    )
    user_id = cur.lastrowid

    # Sample expenses across categories
    sample_expenses = [
        (user_id, 2500.0, "Food", "2026-04-01", "Groceries"),
        (user_id, 1200.0, "Transport", "2026-04-03", "Metro pass"),
        (user_id, 3000.0, "Bills", "2026-04-05", "Electricity bill"),
        (user_id, 1500.0, "Health", "2026-04-07", "Pharmacy"),
        (user_id, 2000.0, "Entertainment", "2026-04-10", "Movie tickets"),
        (user_id, 3500.0, "Shopping", "2026-04-12", "Clothes"),
        (user_id, 800.0, "Other", "2026-04-14", "Gift"),
        (user_id, 500.0, "Food", "2026-04-15", "Lunch"),
    ]
    cur.executemany(
        "INSERT INTO expenses (user_id, amount, category, date, description) VALUES (?, ?, ?, ?, ?)",
        sample_expenses,
    )
    conn.commit()

