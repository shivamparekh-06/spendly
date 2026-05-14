import pytest
from flask_login import current_user


def test_add_expense_get(client):
    """Test that the add expense form loads via GET."""
    # Need to be logged in to access the add expense page
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })
    response = client.get('/expenses/add')
    assert response.status_code == 200
    assert b'Add Expense' in response.data or b'add' in response.data.lower()


def test_add_expense_success(client):
    """Test successful expense submission."""
    # Login first
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })

    # Submit a valid expense
    response = client.post('/expenses/add', data={
        'amount': '100.50',
        'category': 'Food & Dining',
        'date': '2026-05-12',
        'description': 'Test expense'
    }, follow_redirects=True)

    # Should redirect to profile page after success
    assert response.status_code == 200
    assert b'Expense added successfully' in response.data or b'success' in response.data.lower()


def test_add_expense_validation_errors(client):
    """Test validation errors in add expense form."""
    # Login first
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })

    # Test invalid amount (non-numeric)
    response = client.post('/expenses/add', data={
        'amount': 'abc',
        'category': 'Food & Dining',
        'date': '2026-05-12',
        'description': 'Test'
    })
    assert response.status_code == 200
    assert b'Please enter a valid positive amount' in response.data

    # Test negative amount
    response = client.post('/expenses/add', data={
        'amount': '-10',
        'category': 'Food & Dining',
        'date': '2026-05-12',
        'description': 'Test'
    })
    assert response.status_code == 200
    assert b'Please enter a valid positive amount' in response.data

    # Test invalid category
    response = client.post('/expenses/add', data={
        'amount': '100',
        'category': 'Invalid Category',
        'date': '2026-05-12',
        'description': 'Test'
    })
    assert response.status_code == 200
    assert b'Invalid category selected' in response.data

    # Test invalid date
    response = client.post('/expenses/add', data={
        'amount': '100',
        'category': 'Food & Dining',
        'date': 'invalid-date',
        'description': 'Test'
    })
    assert response.status_code == 200
    assert b'Please provide a valid date' in response.data


def test_edit_expense_placeholder(client):
    """Test that the edit expense placeholder route returns the placeholder message."""
    # Need to be logged in
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })
    response = client.get('/expenses/1/edit')
    assert response.status_code == 200
    assert b'Edit expense - coming in Step 8' in response.data


def test_delete_expense_placeholder(client):
    """Test that the delete expense placeholder route returns the placeholder message."""
    # Need to be logged in
    client.post('/login', data={
        'email': 'demo@spendly.com',
        'password': 'demo123'
    })
    response = client.get('/expenses/1/delete')
    assert response.status_code == 200
    assert b'Delete expense - coming in Step 9' in response.data