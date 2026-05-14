import os
import tempfile
import pytest
from app import app as flask_app
from database import db as database_module


@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    # Create a temporary database file
    db_fd, db_path = tempfile.mkstemp()
    database_module._DB_PATH = db_path

    # Override the app's database path
    with flask_app.app_context():
        # Reinitialize the database with our temporary path
        database_module.init_db()
        database_module.seed_db()

    yield flask_app

    # Teardown: close and remove the temporary database
    # Close any open database connections
    try:
        conn = database_module.get_db()
        conn.close()
    except:
        pass
    os.close(db_fd)
    try:
        os.unlink(db_path)
    except PermissionError:
        # On Windows, sometimes the file is still locked; try again after a brief moment
        import time
        time.sleep(0.1)
        try:
            os.unlink(db_path)
        except PermissionError:
            pass  # If it still fails, we'll leave cleanup to the OS


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture
def runner(app):
    """A test runner for the app's Click commands."""
    return app.test_cli_runner()