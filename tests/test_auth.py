import pytest
from flask_login import current_user


def test_landing_page(client):
    """Test that the landing page loads successfully."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Spendly' in response.data or b'landing' in response.data.lower()


def test_register_page_get(client):
    """Test that the registration page loads via GET."""
    response = client.get('/register')
    assert response.status_code == 200
    assert b'Register' in response.data or b'register' in response.data.lower()


def test_register_success(client):
    """Test successful user registration."""
    response = client.post('/register', data={
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'password123'
    }, follow_redirects=True)

    # Should redirect to login page after successful registration
    assert response.status_code == 200
    assert b'Registration successful' in response.data or b'success' in response.data.lower()


def test_register_validation_errors(client):
    """Test registration validation errors."""
    # Test missing fields
    response = client.post('/register', data={
        'name': '',
        'email': '',
        'password': ''
    })
    assert response.status_code == 200
    assert b'All fields are required' in response.data

    # Test short password
    response = client.post('/register', data={
        'name': 'Test User',
        'email': 'test2@example.com',
        'password': '123'
    })
    assert response.status_code == 200
    assert b'Password must be at least 8 characters' in response.data


def test_register_duplicate_email(client):
    """Test registration with duplicate email."""
    # First registration
    client.post('/register', data={
        'name': 'Test User',
        'email': 'duplicate@example.com',
        'password': 'password123'
    })

    # Second registration with same email
    response = client.post('/register', data={
        'name': 'Test User 2',
        'email': 'duplicate@example.com',
        'password': 'password456'
    })
    assert response.status_code == 200
    assert b'An account with that email already exists' in response.data


def test_login_page_get(client):
    """Test that the login page loads via GET."""
    response = client.get('/login')
    assert response.status_code == 200
    assert b'Login' in response.data or b'login' in response.data.lower()


def test_login_success(client):
    """Test successful login with demo user (seeded in conftest)."""
    response = client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    }, follow_redirects=True)

    # Should redirect to landing page after successful login
    assert response.status_code == 200
    assert b'Successfully logged in' in response.data or b'success' in response.data.lower()


def test_login_invalid_credentials(client):
    """Test login with invalid credentials."""
    response = client.post('/login', data={
        'email': 'wrong@example.com',
        'password': 'wrongpassword'
    })
    assert response.status_code == 200
    assert b'Invalid email or password' in response.data


def test_login_redirect_if_authenticated(client):
    """Test that authenticated users are redirected from login page."""
    # First login
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })

    # Try to access login page while logged in
    response = client.get('/login')
    # Should redirect to landing page
    assert response.status_code == 302 or b'landing' in response.data.lower()


def test_logout(client):
    """Test logout functionality."""
    # First login
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })

    # Then logout
    response = client.get('/logout', follow_redirects=True)
    assert response.status_code == 200
    assert b'You have been logged out' in response.data or b'success' in response.data.lower()