"""
Public Blueprint for ONG Connect - Public-facing Web Routes
Handles all public routes like dashboard, statistics, case details, etc.
"""

from routes import (
    Blueprint, render_template, request, redirect, url_for, session,
    get_db, get_db_connection, TRANSLATIONS, MAURITANIA_LOCATIONS
)

# Create blueprint
public_bp = Blueprint('public', __name__, url_prefix='/public')


def get_pagination_iter(current_page, total_pages, left_edge=1, right_edge=1, left_current=1, right_current=1):
    """Generate pagination iterator with ellipses."""
    if total_pages <= 1:
        return []
    
    if total_pages <= 7:
        return list(range(1, total_pages + 1))

    pages = []
    last = 0

    for num in range(1, total_pages + 1):
        if (num <= left_edge) or \
           (num > total_pages - right_edge) or \
           (abs(num - current_page) <= left_current):
            
            if last + 1 != num:
                pages.append(None)  # Ellipsis
            pages.append(num)
            last = num
            
    return pages


@public_bp.route('/dashboard')
def dashboard():
    """Public dashboard showing approved cases."""
    page = request.args.get('page', 1, type=int)
    per_page = 3
    offset = (page - 1) * per_page
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Count total approved cases only
            cursor.execute("SELECT COUNT(*) as count FROM cas_social WHERE statut_approbation = 'approuvé'")
            total_cases = cursor.fetchone()['count']
            total_pages = (total_cases + per_page - 1) // per_page
            
            if page < 1: page = 1
            if total_pages > 0 and page > total_pages: page = total_pages
            offset = (page - 1) * per_page

            # Fetch approved cases for current page
            sql = """
                SELECT c.*, o.nom_ong, o.logo_url, o.domaine_intervation, m.file_url 
                FROM cas_social c 
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                LEFT JOIN (
                    SELECT id_cas_social, MIN(file_url) as file_url 
                    FROM media 
                    GROUP BY id_cas_social
                ) m ON c.id_cas_social = m.id_cas_social
                WHERE c.statut_approbation = 'approuvé'
                ORDER BY c.date_publication DESC
                LIMIT %s OFFSET %s
            """
            cursor.execute(sql, (per_page, offset))
            cases = cursor.fetchall()

            # Fetch ONGs
            cursor.execute("SELECT * FROM ong ORDER BY update_at DESC LIMIT 6")
            ongs = cursor.fetchall()

            cursor.execute("SELECT id_ong, nom_ong FROM ong ORDER BY nom_ong")
            all_ongs = cursor.fetchall()

            cursor.execute("SELECT * FROM categorie")
            categories = cursor.fetchall()

            # All cases for client-side filtering
            sql_all = """
                SELECT c.*, o.nom_ong, o.logo_url, o.domaine_intervation, m.file_url 
                FROM cas_social c 
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                LEFT JOIN (
                    SELECT id_cas_social, MIN(file_url) as file_url 
                    FROM media 
                    GROUP BY id_cas_social
                ) m ON c.id_cas_social = m.id_cas_social
                WHERE c.statut_approbation = 'approuvé'
                ORDER BY c.date_publication DESC
            """
            cursor.execute(sql_all)
            all_cases = cursor.fetchall()

            # Dashboard Statistics
            cursor.execute("SELECT COUNT(*) as count FROM ong")
            stats_nb_ongs = cursor.fetchone()['count']

            cursor.execute("SELECT COUNT(*) as count FROM cas_social WHERE statut='Résolu'")
            stats_resolved = cursor.fetchone()['count']
    
    pagination_iter = get_pagination_iter(page, total_pages)

    return render_template('public/dashboard.html', 
                         cases=cases,
                         all_cases=all_cases,
                         all_ongs=all_ongs,
                         categories=categories,
                         page=page, 
                         current_page=page, 
                         total_pages=total_pages,
                         pagination_iter=pagination_iter,
                         ongs=ongs,
                         stats_nb_ongs=stats_nb_ongs,
                         stats_resolved=stats_resolved,
                         stats_total_cases=total_cases)


@public_bp.route('/statistics')
def statistics():
    """Public statistics page."""
    with get_db() as conn:
        with conn.cursor() as cursor:
            sql = """
                SELECT c.*, o.nom_ong, o.logo_url
                FROM cas_social c 
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                WHERE c.statut_approbation = 'approuvé'
                ORDER BY c.date_publication DESC
            """
            cursor.execute(sql)
            cases = cursor.fetchall()
            
            total_cases = len(cases)
            urgent_cases = sum(1 for case in cases if case['statut'] == 'Urgent')
            resolved_cases = sum(1 for case in cases if case['statut'] == 'Résolu')
            
            cursor.execute("""
                SELECT COUNT(*) as count FROM ong WHERE statut_de_validation = 'validé'
            """)
            total_ongs = cursor.fetchone()['count']
    
    return render_template('public/statistics.html', 
                          cases=cases,
                          total_cases=total_cases,
                          urgent_cases=urgent_cases,
                          resolved_cases=resolved_cases,
                          total_ongs=total_ongs)


@public_bp.route('/beneficiaries')
def beneficiaries():
    """Public beneficiaries page."""
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    (SELECT COUNT(*) 
                     FROM beneficier b 
                     JOIN cas_social c ON b.id_cas_social = c.id_cas_social 
                     WHERE c.statut = 'Résolu') + 
                    (SELECT COUNT(*) FROM cas_social 
                     WHERE statut = 'Résolu' 
                     AND id_cas_social NOT IN (SELECT DISTINCT id_cas_social FROM beneficier)) 
                as count
            """)
            total_beneficiaries = cursor.fetchone()['count']
            
            cursor.execute("SELECT id_ong, nom_ong FROM ong ORDER BY nom_ong")
            ongs = cursor.fetchall()
            
            cursor.execute("SELECT nomCategorie FROM categorie ORDER BY nomCategorie")
            categories = [c['nomCategorie'] for c in cursor.fetchall()]
            
            cursor.execute("SELECT DISTINCT adresse FROM beneficier WHERE adresse IS NOT NULL AND adresse != ''")
            locations = [l['adresse'] for l in cursor.fetchall()]
            
    return render_template('public/beneficiaries.html', 
                         total_beneficiaries=total_beneficiaries,
                         filter_ongs=ongs,
                         filter_categories=categories,
                         filter_locations=locations)


@public_bp.route('/case/<int:id>')
def case_details(id):
    """View a specific case's details."""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT c.*, o.nom_ong, o.logo_url, o.email as ong_email, o.telephone as ong_phone, o.adresse as ong_address
                FROM cas_social c
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                WHERE c.id_cas_social = %s
            """
            cursor.execute(sql, (id,))
            case = cursor.fetchone()
            
            if not case:
                return "Case not found", 404
            
            # Check visibility
            is_approved = case.get('statut_approbation') == 'approuvé'
            is_admin = session.get('user_type') == 'admin'
            is_owner = session.get('user_type') == 'ong' and session.get('user_id') == case['id_ong']
            
            if not (is_approved or is_admin or is_owner):
                return "Case not found", 404

            cursor.execute("SELECT * FROM media WHERE id_cas_social = %s", (id,))
            media_list = cursor.fetchall()
            
    finally:
        conn.close()
    return render_template('public/case_details.html', case=case, media_list=media_list)
