"""
ONG Blueprint for ONG Connect - ONG-specific Routes
Handles all /ong/* routes for ONG management.

NOTE: This blueprint contains the core ONG routes. Additional routes from app.py
(like /ngos/*, /cases/*, etc.) should be migrated here or to admin.py as appropriate.
"""

from routes import (
    Blueprint, render_template, request, redirect, url_for, flash, session,
    get_db, get_db_connection, TRANSLATIONS, os, datetime, secure_filename,
    allowed_file, generate_password_hash
)

# Create blueprint
ong_bp = Blueprint('ong', __name__)

# Note: Login/logout routes are handled in app.py's unified login system

@ong_bp.route('/ong/profile')
def profile():
    """ONG profile view/edit."""
    if session.get('user_type') != 'ong':
        flash("Accès réservé aux ONGs.", "danger")
        return redirect(url_for('unified_login'))
    
    ong_id = session.get('user_id')
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (ong_id,))
            ong = cursor.fetchone()
            if not ong:
                flash("ONG introuvable", "danger")
                return redirect(url_for('unified_login'))
    finally:
        conn.close()
    
    return render_template('ong/profile.html', ong=ong)


@ong_bp.route('/ong/dashboard')
def dashboard():
    """ONG dashboard."""
    if session.get('user_type') != 'ong':
        flash("Accès réservé aux ONGs.", "danger")
        return redirect(url_for('unified_login'))
    
    ong_id = session.get('user_id')
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Fetch ONG info
            cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (ong_id,))
            ong = cursor.fetchall()[0] if cursor.rowcount > 0 else None
            
            # Fetch ONG's cases
            cursor.execute("""
                SELECT * FROM cas_social 
                WHERE id_ong=%s 
                ORDER BY date_publication DESC
            """, (ong_id,))
            cases = cursor.fetchall()
            
            # Stats
            total_cases = len(cases)
            approved_cases = sum(1 for c in cases if c['statut_approbation'] == 'approuvé')
            pending_cases = sum(1 for c in cases if c['statut_approbation'] == 'en_attente')
    
    return render_template('ong/dashboard.html', 
                         ong=ong,
                         cases=cases,
                         total_cases=total_cases,
                         approved_cases=approved_cases,
                         pending_cases=pending_cases)


@ong_bp.route('/ong/case/<int:id>')
def case_view(id):
    """View ONG's specific case."""
    if session.get('user_type') != 'ong':
        flash("Accès réservé aux ONGs.", "danger")
        return redirect(url_for('unified_login'))
    
    ong_id = session.get('user_id')
    
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Verify ownership
            cursor.execute("""
                SELECT c.*, o.nom_ong 
                FROM cas_social c
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                WHERE c.id_cas_social=%s AND c.id_ong=%s
            """, (id, ong_id))
            case = cursor.fetchone()
            
            if not case:
                flash("Cas introuvable ou accès non autorisé", "danger")
                return redirect(url_for('ong.dashboard'))
            
            # Fetch media
            cursor.execute("SELECT * FROM media WHERE id_cas_social=%s", (id,))
            media_list = cursor.fetchall()
            
    finally:
        conn.close()
    
    return render_template('ong/case_details.html', case=case, media_list=media_list)


# NOTE: Additional ONG routes from app.py should be migrated here:
# - /ngos/add, /ngos/edit/<id>, /ngos/delete/<id> (admin functions -> move to admin.py)
# - /cases/add, /cases/edit/<id>, /cases/delete/<id> (ONG functions -> add here)
# - /api/ngos/register (already in api.py)
# - /change_password (could be shared or in app.py)
