"""
Routes package for ONG Connect.

This package contains all Flask blueprint modules organized by functionality.
"""

# Common imports used across all blueprints
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify, Response, abort
import json
import os
from datetime import datetime
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash

# Import from our modules
from database import get_db, get_db_connection, check_and_migrate_password
from translations import TRANSLATIONS
from auth import admin_required
from config import Config
from locations_data import MAURITANIA_LOCATIONS

# Helper function for session checking
def get_current_lang():
    """Get current language from session."""
    return session.get('lang', 'ar')

def get_translation(key):
    """Get translation for current language."""
    lang = get_current_lang()
    return TRANSLATIONS[lang].get(key, key)

# File upload helper
def allowed_file(filename, allowed_extensions={'png', 'jpg', 'jpeg', 'gif', 'pdf'}):
    """Check if file extension is allowed."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_extensions

# Auth helper for API
def check_api_auth():
    """Check API authorization header."""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return False
    return True
