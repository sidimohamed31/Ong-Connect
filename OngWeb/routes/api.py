"""
API Blueprint for ONG Connect - Mobile Application Endpoints
Handles all /api/*  routes for the mobile application.
"""

from routes import(
    Blueprint, request, jsonify, session, os, datetime,
    get_db, get_db_connection, check_and_migrate_password,
    TRANSLATIONS, check_api_auth, secure_filename, allowed_file
)

# Create blueprint
api_bp = Blueprint('api', __name__, url_prefix='/api')


@api_bp.route('/verify_ong_password', methods=['POST'])
def verify_ong_password():
    """Verify ONG password for mobile app."""
    data = request.get_json()
    ong_id = data.get('ong_id')
    password = data.get('password')
    
    if not ong_id or not password:
        return {'success': False, 'message': 'Missing data'}, 400
        
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id_ong, mot_de_passe FROM ong WHERE id_ong=%s", (ong_id,))
            result = cursor.fetchone()
            
            if result and check_and_migrate_password(conn, 'ong', 'id_ong', result['id_ong'], password, result['mot_de_passe']):
                session['authorized_ong_id'] = int(ong_id)
                return {'success': True}
            else:
                return {'success': False, 'message': 'Mot de passe incorrect'}, 401
    finally:
        conn.close()


@api_bp.route('/verify_admin_credentials', methods=['POST'])
def verify_admin_credentials():
    """Verify admin credentials for mobile app."""
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return {'success': False, 'message': 'Missing credentials'}, 400
        
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM administrateur WHERE email=%s", (email,))
            admin = cursor.fetchone()
            
            if admin and check_and_migrate_password(conn, 'administrateur', 'id_admin', admin['id_admin'], password, admin['mot_de_passe']):
                return {'success': True}
            else:
                return {'success': False, 'message': 'Invalid credentials'}, 401
    finally:
        conn.close()


# --- Mobile Admin API Endpoints ---

@api_bp.route('/admin/pending-ongs', methods=['GET'])
def admin_pending_ongs():
    """Get list of pending ONGs for admin approval."""
    if not check_api_auth():
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id_ong, nom_ong, email, telephone, adresse, 
                           domaine_intervation, logo_url, verification_doc_url, update_at
                    FROM ong 
                    WHERE statut_de_validation = 'enattente'
                    ORDER BY update_at DESC
                """)
                ongs = cursor.fetchall()
                
                ong_list = []
                for ong in ongs:
                    ong_list.append({
                        'id': ong['id_ong'],
                        'name': ong['nom_ong'],
                        'email': ong['email'],
                        'phone': ong['telephone'],
                        'address': ong['adresse'],
                        'domains': ong['domaine_intervation'],
                        'logo_url': ong['logo_url'],
                        'verification_doc_url': ong['verification_doc_url'],
                        'created_at': ong['update_at'].isoformat() if ong['update_at'] else None
                    })
                
                return jsonify({'success': True, 'data': ong_list})
    except Exception as e:
        print(f"Error fetching pending ONGs: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@api_bp.route('/admin/pending-cases', methods=['GET'])
def admin_pending_cases():
    """Get list of pending cases for admin approval."""
    if not check_api_auth():
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT c.id_cas_social, c.titre, c.description, c.wilaya, c.moughataa,
                           c.adresse, c.date_publication, c.statut, c.category_id,
                           o.nom_ong, cat.nomCategorie,
                           (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) as first_image
                    FROM cas_social c
                    LEFT JOIN ong o ON c.id_ong = o.id_ong
                    LEFT JOIN categorie cat ON c.category_id = cat.idCategorie
                    WHERE c.statut_approbation = 'en_attente'
                    ORDER BY c.date_publication DESC
                """)
                cases = cursor.fetchall()
                
                case_list = []
                for case in cases:
                    case_list.append({
                        'id': case['id_cas_social'],
                        'title': case['titre'],
                        'description': case['description'],
                        'wilaya': case['wilaya'],
                        'moughataa': case['moughataa'],
                        'address': case['adresse'],
                        'date': case['date_publication'].isoformat() if case['date_publication'] else None,
                        'status': case['statut'],
                        'category': case['nomCategorie'],
                        'ong_name': case['nom_ong'],
                        'image_url': case['first_image']
                    })
                
                return jsonify({'success': True, 'data': case_list})
    except Exception as e:
        print(f"Error fetching pending cases: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@api_bp.route('/admin/ong/<int:id>/approve', methods=['POST'])
def admin_approve_ong(id):
    """Approve an ONG registration."""
    if not check_api_auth():
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE ong SET statut_de_validation = 'validé' WHERE id_ong = %s", (id,))
            conn.commit()
        return jsonify({'success': True, 'message': 'ONG approved successfully'})
    except Exception as e:
        print(f"Error approving ONG: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@api_bp.route('/admin/ong/<int:id>/reject', methods=['POST'])
def admin_reject_ong(id):
    """Reject and delete an ONG registration."""
    if not check_api_auth():
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # Clean up cases and their media
                cursor.execute("SELECT id_cas_social FROM cas_social WHERE id_ong=%s", (id,))
                cases = cursor.fetchall()
                
                for case in cases:
                    case_id = case['id_cas_social']
                    
                    # Delete media files
                    cursor.execute("SELECT file_url FROM media WHERE id_cas_social=%s", (case_id,))
                    media_files = cursor.fetchall()
                    for media in media_files:
                        if media['file_url']:
                            file_path = os.path.join('static', media['file_url'])
                            if os.path.exists(file_path):
                                try: os.remove(file_path)
                                except: pass
                    cursor.execute("DELETE FROM media WHERE id_cas_social=%s", (case_id,))
                    cursor.execute("DELETE FROM beneficier WHERE id_cas_social=%s", (case_id,))
                    cursor.execute("DELETE FROM cas_social WHERE id_cas_social=%s", (case_id,))
                
                # Clean up ONG files
                cursor.execute("SELECT logo_url, verification_doc_url FROM ong WHERE id_ong=%s", (id,))
                ong_data = cursor.fetchone()
                if ong_data:
                    if ong_data.get('logo_url'):
                        logo_path = os.path.join('static', ong_data['logo_url'])
                        if os.path.exists(logo_path):
                            try: os.remove(logo_path)
                            except: pass
                    if ong_data.get('verification_doc_url'):
                        doc_path = os.path.join('static', ong_data['verification_doc_url'])
                        if os.path.exists(doc_path):
                            try: os.remove(doc_path)
                            except: pass
                
                # Delete ONG
                cursor.execute("DELETE FROM ong WHERE id_ong=%s", (id,))
                conn.commit()
            
            return jsonify({'success': True, 'message': 'ONG rejected and deleted'})
        finally:
            conn.close()
    except Exception as e:
        print(f"Error rejecting ONG: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@api_bp.route('/admin/case/<int:id>/approve', methods=['POST'])
def admin_approve_case(id):
    """Approve a social case."""
    if not check_api_auth():
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE cas_social SET statut_approbation = 'approuvé' WHERE id_cas_social = %s", (id,))
            conn.commit()
        return jsonify({'success': True, 'message': 'Case approved successfully'})
    except Exception as e:
        print(f"Error approving case: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@api_bp.route('/admin/case/<int:id>/reject', methods=['POST'])
def admin_reject_case(id):
    """Reject and delete a social case."""
    if not check_api_auth():
        return jsonify({'success': False, 'message': 'Unauthorized'}), 401
    
    try:
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
            
            return jsonify({'success': True, 'message': 'Case rejected and deleted'})
        finally:
            conn.close()
    except Exception as e:
        print(f"Error rejecting case: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


# Note: Additional API routes for stats, cases, categories, NGO registration,
# etc. will be added from app.py systematically
