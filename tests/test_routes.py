import pytest
from flask_login import current_user


def test_landing_page(client):
    """Test that the landing page is accessible."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Spendly' in response.data or b'landing' in response.data.lower()


def test_terms_page(client):
    """Test that the terms page is accessible."""
    response = client.get('/terms')
    assert response.status_code == 200
    assert b'Terms' in response.data or b'terms' in response.data.lower()


def test_privacy_page(client):
    """Test that the privacy page is accessible."""
    response = client.get('/privacy')
    assert response.status_code == 200
    assert b'Privacy' in response.data or b'privacy' in response.data.lower()


def test_profile_page_redirect_when_not_logged_in(client):
    """Test that accessing profile without login redirects to login page."""
    response = client.get('/profile', follow_redirects=False)
    # Should redirect to login page because profile requires login
    assert response.status_code == 302
    assert '/login' in response.location


def test_analytics_page_redirect_when_not_logged_in(client):
    """Test that accessing analytics without login redirects to login page."""
    response = client.get('/analytics', follow_redirects=False)
    # Should redirect to login page because analytics requires login
    assert response.status_code == 302
    assert '/login' in response.location


def test_profile_page_access_when_logged_in(client):
    """Test that logged-in user can access profile page."""
    # Login first
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })
    response = client.get('/profile')
    assert response.status_code == 200
    assert b'Profile' in response.data or b'profile' in response.data.lower()


def test_analytics_page_access_when_logged_in(client):
    """Test that logged-in user can access analytics page."""
    # Login first
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })
    response = client.get('/analytics')
    assert response.status_code == 200
    assert b'Analytics' in response.data or b'analytics' in response.data.lower()