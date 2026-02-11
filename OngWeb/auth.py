"""
Authentication utilities and decorators for ONG Connect.

This module contains authentication-related helpers including:
- Admin access control decorators
- Password verification functions
"""

from flask import session, redirect, url_for, flash
from functools import wraps
from database import get_db, check_and_migrate_password


def admin_required(f):
    """Decorator to require admin authentication for routes."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('user_type') != 'admin':
            flash("Accès réservé aux administrateurs.", "danger")
            return redirect(url_for('admin_login'))
        return f(*args, **kwargs)
    return decorated_function


def verify_ong_password():
    """Verify ONG password from database - placeholder for future use."""
    # This function was part of the unified login
    # Kept as a stub for potential future use
    pass


def verify_admin_credentials():
    """Verify admin credentials from database - placeholder for future use."""
    # This function was part of the unified login
    # Kept as a stub for potential future use
    pass
