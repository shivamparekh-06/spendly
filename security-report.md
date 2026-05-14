# Security Review Report for Spendly

## Overview
This report outlines the security findings from an OWASP Top 10 (2021) review of the Spendly Flask application.

## Findings

### 1. Broken Access Control
- **Status**: Low
- **Location**: `/profile`, `/analytics`, `/expenses/add` routes
- **Description**: These routes are protected by `@login_required` which is correct. However, there is no explicit check that the user owns the resources they are accessing (e.g., in `/profile` we filter by `current_user.id` which is good). The delete and edit routes are not yet implemented (placeholders).
- **Fix**: Ensure that when implementing edit and delete, we check that the expense belongs to the current user.

### 2. Cryptographic Failures
- **Status**: Medium
- **Location**: `app.py` line 7: `app.secret_key = 'dev-secret'`
- **Description**: The secret key is hard-coded and weak. In production, this should be a strong, random key stored in an environment variable.
- **Fix**: Use a strong secret key from environment variable: `app.secret_key = os.environ.get('SECRET_KEY')` and set a strong key in production.

### 3. Injection
- **Status**: Low
- **Location**: Throughout the code where SQL queries are built using string formatting (f-strings) or concatenation.
- **Description**: The code uses parameterized queries (with `?` placeholders) in most places, which is safe. However, in the `/profile` route, the date filter clause is built by string concatenation and then used in an f-string. This could be risky if the clause is not properly sanitized, but note that the clause is built from fixed strings and the parameters are passed separately. The actual SQL is built as:
      f'SELECT ... WHERE user_id = ?{clause}'
  and then executed with `(user_id, *params)`. Since `clause` is built from fixed strings and the parameters are passed as separate arguments, this is safe from SQL injection.
- **Fix**: Continue using parameterized queries. Consider using an ORM or query builder for more complex queries to avoid mistakes.

### 4. Insecure Design
- **Status**: Low
- **Location**: Application flow
- **Description**: The application does not appear to have significant design flaws. However, note that the `/logout` route redirects to the landing page, which is acceptable.
- **Fix**: No immediate fixes needed.

### 5. Security Misconfiguration
- **Status**: Medium
- **Location**: `app.py` line 293: `app.run(debug=True, port=5001)`
- **Description**: The application is run with debug mode enabled. This should never be used in production as it can leak sensitive information.
- **Fix**: Set `debug=False` in production, or better, set it from an environment variable: `debug=os.environ.get('FLASK_DEBUG') == 'True'`.

### 6. Vulnerable and Outdated Components
- **Status**: Low
- **Location**: `requirements.txt`
- **Description**: The dependencies are pinned to specific versions. However, we should check for known vulnerabilities.
  - Flask 3.1.3: No known critical vulnerabilities at the time of writing.
  - Werkzeug 3.1.6: No known critical vulnerabilities.
  - pytest and pytest-flask: Testing tools, not exposed in production.
  - Flask-Login 0.6.3: No known critical vulnerabilities.
- **Fix**: Regularly update dependencies and use a service like Dependabot or `pip audit` to check for vulnerabilities.

### 7. Identification and Authentication Failures
- **Status**: Low
- **Location**: `app.py` login and registration routes
- **Description**: 
  - Passwords are hashed using Werkzeug's `generate_password_hash` (which uses PBKDF2-SHA256 by default) and checked with `check_password_hash`. This is strong.
  - The registration form requires a minimum password length of 8 characters, which is acceptable but could be strengthened (e.g., require complexity).
  - There is no rate limiting on login attempts, which could allow brute force attacks.
- **Fix**: 
  - Consider adding rate limiting on login attempts (e.g., using Flask-Limiter).
  - Consider requiring stronger passwords (e.g., minimum length 12, or use a password strength estimator).

### 8. Software and Data Integrity Failures
- **Status**: Low
- **Location**: Not applicable in the current codebase (no deserialization of untrusted data, no auto-updating code).
- **Fix**: No immediate fixes needed.

### 9. Security Logging and Monitoring Failures
- **Status**: Medium
- **Location**: Throughout the application
- **Description**: The application uses `flash` messages for user feedback but does not log security-relevant events (e.g., failed logins, registration attempts, access control violations).
- **Fix**: 
  - Add logging for failed login attempts, successful logins, and registration attempts.
  - Consider logging access to sensitive routes (like profile) for audit trails.

### 10. Server-Side Request Forgery (SSRF)
- **Status**: Low
- **Location**: Not applicable (the application does not fetch external URLs based on user input).
- **Fix**: No immediate fixes needed.

## Summary
The application has a good security foundation but requires improvements in:
- Secret key management (use environment variable)
- Disabling debug mode in production
- Adding rate limiting for login attempts
- Adding security logging
- Ensuring proper access control in edit/delete routes (when implemented)

## Recommendations
1. Move secret key and debug flag to environment variables.
2. Implement rate limiting on authentication endpoints.
3. Add logging for security events.
4. When implementing edit and delete, add ownership checks.
5. Regularly update dependencies and monitor for vulnerabilities.
