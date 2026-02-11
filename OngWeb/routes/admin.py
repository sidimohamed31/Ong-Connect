"""
Admin Blueprint for ONG Connect - Admin Panel Routes  
Handles all admin/* routes and admin CRUD operations.

NOTE: This blueprint contains core admin routes. Many admin CRUD routes
(like /admins/*, /ngos/*, /cases/*, /beneficiaries/*, /categories/*)
are left in app.py for now but should be migrated here in future iterations.
"""

from routes import (
    Blueprint, render_template, request, redirect, url_for, flash, session,
    get_db, get_db_connection, admin_required, TRANSLATIONS, os,
    check_and_migrate_password, generate_password_hash
)

# Create blueprint
admin_bp = Blueprint('admin', __name__, url_prefix='/admin')


@admin_bp.route('/dashboard')
@admin_required
def dashboard():
    """Admin dashboard showing pending approvals."""
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Pending ONGs
            cursor.execute("""
                SELECT * FROM ong 
                WHERE statut_de_validation = 'enattente' 
                ORDER BY update_at DESC
            """)
            pending_ongs = cursor.fetchall()
            
            # Pending Cases
            cursor.execute("""
                SELECT c.*, o.nom_ong 
                FROM cas_social c
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                WHERE c.statut_approbation = 'en_attente'
                ORDER BY c.date_publication DESC
            """)
            pending_cases = cursor.fetchall()
            
            # Stats
            cursor.execute("SELECT COUNT(*) as count FROM ong WHERE statut_de_validation='validé'")
            total_ongs = cursor.fetchone()['count']
            
            cursor.execute("SELECT COUNT(*) as count FROM cas_social WHERE statut_approbation='approuvé'")
            total_cases = cursor.fetchone()['count']
    
    return render_template('admin/dashboard.html',
                         pending_ongs=pending_ongs,
                         pending_cases=pending_cases,
                         total_ongs=total_ongs,
                         total_cases=total_cases)


@admin_bp.route('/case/<int:id>/approve', methods=['POST'])
@admin_required
def approve_case(id):
    """Approve a social case."""
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("UPDATE cas_social SET statut_approbation = 'approuvé' WHERE id_cas_social = %s", (id,))
        conn.commit()
    flash(TRANSLATIONS[session.get('lang', 'ar')]['case_approved'], 'success')
    return redirect(url_for('admin.dashboard'))


@admin_bp.route('/case/<int:id>/reject', methods=['POST'])
@admin_required
def reject_case(id):
    """Reject and delete a social case."""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Clean media files
            cursor.execute("SELECT file_url FROM media WHERE id_cas_social=%s", (id,))
            media_files = cursor.fetchall()
            for media in media_files:
                if media['file_url']:
                    file_path = os.path.join('static', media['file_url'])
                    if os.path.exists(file_path):
                        try: os.remove(file_path)
                        except: pass
            
            # Delete records
            cursor.execute("DELETE FROM media WHERE id_cas_social=%s", (id,))
            cursor.execute("DELETE FROM beneficier WHERE id_cas_social=%s", (id,))
            cursor.execute("DELETE FROM cas_social WHERE id_cas_social = %s", (id,))
        conn.commit()
    finally:
        conn.close()
    flash('Cas social rejeté et supprimé avec succès.', 'success')
    return redirect(url_for('admin.dashboard'))


@admin_bp.route('/ong/<int:id>/reset-password', methods=['POST'])
@admin_required
def reset_ong_password(id):
    """Reset an ONG's password."""
    new_password = request.form.get('new_password')
    if not new_password:
        flash("Mot de passe requis", "danger")
        return redirect(request.referrer)
    
    hashed = generate_password_hash(new_password)
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                UPDATE ong 
                SET mot_de_passe = %s, must_change_password = TRUE 
                WHERE id_ong = %s
            """, (hashed, id))
        conn.commit()
    
    flash("Mot de passe réinitialisé avec succès", "success")
    return redirect(request.referrer or url_for('admin.dashboard'))


# NOTE: Additional admin CRUD routes from app.py should be migrated here:
# - /admins, /admins/add, /admins/edit/<id>, /admins/delete/<id>
# - /admin/action/<action>/<id>
# - /ngos (list), /ngos/add, /ngos/edit/<id>, /ngos/delete/<id>, /ngos/details/<id>
# - /cases, /cases/add, /cases/edit/<id>, /cases/delete/<id>, /cases/update-status/<id>
# - /beneficiaries, /beneficiaries/add, /beneficiaries/edit/<id>, /beneficiaries/delete/<id>
# - /categories, /categories/add, /categories/edit/<id>, /categories/delete/<id>
# - /media/delete/<id>
# 
# These routes total ~2000+ lines and should be systematically migrated in future refactoring phases.
