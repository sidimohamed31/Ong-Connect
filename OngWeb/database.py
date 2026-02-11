"""
Database utilities and initialization for ONG Connect.

This module contains all database-related functions including:
- Connection management
- Password migration utilities
- Database schema initialization and migrations
"""

import pymysql
import pymysql.cursors
from contextlib import contextmanager
from werkzeug.security import generate_password_hash, check_password_hash


# Database configuration - imported from config at runtime
DB_HOST = None
DB_USER = None
DB_PASSWORD = None
DB_NAME = None


def init_config(config):
    """Initialize database configuration from Flask config."""
    global DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
    DB_HOST = config['DB_HOST']
    DB_USER = config['DB_USER']
    DB_PASSWORD = config['DB_PASSWORD']
    DB_NAME = config['DB_NAME']


@contextmanager
def get_db():
    """Context manager for database connections."""
    conn = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    try:
        yield conn
    finally:
        conn.close()


def get_db_connection():
    """Legacy wrapper for database connections."""
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def check_and_migrate_password(conn, table, id_column, id_value, plain_password, db_password_value):
    """
    Checks password against DB value.
    If DB value is plain text and matches, it generates a hash, updates DB, and returns True.
    If DB value is a hash, it verifies it and returns result.
    """
    # 1. Check if it looks like a hash (Werkzeug hashes start with method:)
    if db_password_value.startswith('scrypt:') or db_password_value.startswith('pbkdf2:'):
        return check_password_hash(db_password_value, plain_password)
    
    # 2. Fallback: Check as plaintext (Legacy)
    if db_password_value == plain_password:
        # Migrate to Hash
        print(f"Migrating password for {table} {id_value}")
        new_hash = generate_password_hash(plain_password)
        with conn.cursor() as cursor:
            cursor.execute(f"UPDATE {table} SET mot_de_passe=%s WHERE {id_column}=%s", (new_hash, id_value))
        conn.commit()
        return True
        
    return False


def init_db():
    """Initialize database schema and perform migrations."""
    # Connect without database first to create it if it doesn't exist
    conn = pymysql.connect(host="localhost", user="root", password="sidimedtop1")
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
    finally:
        conn.close()

    # Now connect to the database and create tables
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # --- NEW: Users Table (Unified Authentication) ---
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    email VARCHAR(150) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    role ENUM('admin', 'ong') NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    must_change_password BOOLEAN DEFAULT FALSE
                )
            """)
            
            # Administrateur
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS administrateur (
                    id_admin INT AUTO_INCREMENT PRIMARY KEY,
                    nom VARCHAR(100) NOT NULL,
                    email VARCHAR(150) UNIQUE NOT NULL,
                    mot_de_passe VARCHAR(255) NOT NULL,
                    must_change_password BOOLEAN DEFAULT FALSE,
                    user_id INT,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
                )
            """)
            
            # Ong
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS ong (
                    id_ong INT AUTO_INCREMENT PRIMARY KEY,
                    nom_ong VARCHAR(150) NOT NULL,
                    adresse VARCHAR(255) NOT NULL,
                    telephone VARCHAR(20) NOT NULL,
                    email VARCHAR(100) NOT NULL,
                    domaine_intervation VARCHAR(200) NOT NULL,
                    statut_de_validation ENUM('enattente', 'validé', 'rejetée') DEFAULT 'enattente',
                    update_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    logo_url VARCHAR(255),
                    verification_doc_url VARCHAR(255),
                    mot_de_passe VARCHAR(255) NOT NULL,
                    must_change_password BOOLEAN DEFAULT FALSE,
                    user_id INT,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
                )
            """)

            # CasSocial
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS cas_social (
                    id_cas_social INT AUTO_INCREMENT PRIMARY KEY,
                    titre VARCHAR(150) NOT NULL,
                    description TEXT,
                    adresse VARCHAR(255),
                    date_publication DATE,
                    statut ENUM('En cours', 'Résolu', 'Urgent') DEFAULT 'En cours',
                    statut_approbation ENUM('en_attente', 'approuvé', 'rejeté') DEFAULT 'en_attente',
                    id_ong INT,
                    FOREIGN KEY (id_ong) REFERENCES ong(id_ong) ON DELETE CASCADE
                )
            """)

            # Beneficier
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS beneficier (
                    id_beneficiaire INT AUTO_INCREMENT PRIMARY KEY,
                    nom VARCHAR(100) NOT NULL,
                    prenom VARCHAR(100),
                    adresse VARCHAR(255),
                    description_situation TEXT,
                    id_cas_social INT,
                    FOREIGN KEY (id_cas_social) REFERENCES cas_social(id_cas_social) ON DELETE CASCADE
                )
            """)

            # Categorie
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS categorie (
                    idCategorie INT AUTO_INCREMENT PRIMARY KEY,
                    nomCategorie VARCHAR(100) NOT NULL,
                    description TEXT NOT NULL
                )
            """)

            # Media
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS media (
                    id_media INT AUTO_INCREMENT PRIMARY KEY,
                    id_cas_social INT,
                    file_url VARCHAR(255) NOT NULL,
                    description_media TEXT,
                    FOREIGN KEY (id_cas_social) REFERENCES cas_social(id_cas_social) ON DELETE CASCADE
                )
            """)

            # --- Fix/Enforce UTF8MB4 for Arabic Support ---
            cursor.execute(f"ALTER DATABASE {DB_NAME} CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci")
            
            # Convert all specific tables to utf8mb4
            tables_to_fix = ['users', 'administrateur', 'ong', 'cas_social', 'beneficier', 'categorie', 'media']
            for table in tables_to_fix:
                try:
                    cursor.execute(f"ALTER TABLE {table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
                except Exception as e:
                    print(f"Warning: Could not alter table {table}. It might not exist yet. Error: {e}")
            
            # --- Specific Fixes ---
            try:
                cursor.execute("ALTER TABLE ong MODIFY logo_url VARCHAR(255)")
            except Exception as e:
                print(f"Warning: Could not resize logo_url. Error: {e}")

            # Add verification_doc_url column if not exists
            try:
                cursor.execute("SELECT verification_doc_url FROM ong LIMIT 1")
            except Exception:
                try:
                    cursor.execute("ALTER TABLE ong ADD COLUMN verification_doc_url VARCHAR(255)")
                    print("Added verification_doc_url column to ong table.")
                except Exception as e:
                    print(f"Warning: Could not add verification_doc_url column. Error: {e}")

            # Add statut_approbation column to cas_social if not exists
            try:
                cursor.execute("SELECT statut_approbation FROM cas_social LIMIT 1")
            except Exception:
                try:
                    cursor.execute("ALTER TABLE cas_social ADD COLUMN statut_approbation ENUM('en_attente', 'approuvé', 'rejeté') DEFAULT 'en_attente'")
                    print("Added statut_approbation column to cas_social table.")
                    cursor.execute("UPDATE cas_social SET statut_approbation = 'approuvé' WHERE statut_approbation IS NULL OR statut_approbation = 'en_attente'")
                    print("Migrated existing social cases to 'approuvé' status.")
                except Exception as e:
                    print(f"Warning: Could not add statut_approbation column. Error: {e}")

            # Add wilaya and moughataa columns to cas_social if not exists
            try:
                cursor.execute("SELECT wilaya FROM cas_social LIMIT 1")
            except Exception:
                try:
                    cursor.execute("ALTER TABLE cas_social ADD COLUMN wilaya VARCHAR(100)")
                    cursor.execute("ALTER TABLE cas_social ADD COLUMN moughataa VARCHAR(100)")
                    print("Added wilaya and moughataa columns to cas_social table.")
                except Exception as e:
                    print(f"Warning: Could not add location columns. Error: {e}")

            # Add must_change_password column if not exists (legacy tables)
            for table in ['ong', 'administrateur']:
                try:
                    cursor.execute(f"SELECT must_change_password FROM {table} LIMIT 1")
                except Exception:
                    try:
                        cursor.execute(f"ALTER TABLE {table} ADD COLUMN must_change_password BOOLEAN DEFAULT FALSE")
                        print(f"Added must_change_password column to {table} table.")
                    except Exception as e:
                        print(f"Warning: Could not add must_change_password column to {table}. Error: {e}")
            
            # --- NEW: Add category_id to cas_social ---
            try:
                cursor.execute("SELECT category_id FROM cas_social LIMIT 1")
            except Exception:
                try:
                    cursor.execute("ALTER TABLE cas_social ADD COLUMN category_id INT")
                    cursor.execute("ALTER TABLE cas_social ADD CONSTRAINT fk_cas_social_categorie FOREIGN KEY (category_id) REFERENCES categorie(idCategorie) ON DELETE SET NULL")
                    print("Added category_id column to cas_social table.")
                    
                    # Migrate Data: Infer category or set default 'Autre'
                    print("Migrating social cases to have a category...")
                    cursor.execute("SELECT id_cas_social, titre, description, id_ong FROM cas_social")
                    cases = cursor.fetchall()
                    
                    cursor.execute("SELECT idCategorie, nomCategorie FROM categorie")
                    categories = cursor.fetchall()
                    
                    cursor.execute("SELECT id_ong, domaine_intervation FROM ong")
                    ongs = {o['id_ong']: o['domaine_intervation'] for o in cursor.fetchall()}
                    
                    for case in cases:
                        assigned_cat_id = None
                        text = (case['titre'] + " " + (case['description'] or "")).lower()
                        
                        # 1. Try to match text with category name
                        for cat in categories:
                            if cat['nomCategorie'].lower() in text:
                                assigned_cat_id = cat['idCategorie']
                                break
                        
                        # 2. If no match, try ONG domain
                        if not assigned_cat_id and case['id_ong'] in ongs:
                            ong_domains = ongs[case['id_ong']].split(',')
                            for domain in ong_domains:
                                domain = domain.strip()
                                for cat in categories:
                                    if cat['nomCategorie'].lower() == domain.lower():
                                        assigned_cat_id = cat['idCategorie']
                                        break
                                if assigned_cat_id: break
                                
                        # 3. Default to 'Autre' or first category
                        if not assigned_cat_id:
                            autre = next((c for c in categories if c['nomCategorie'].lower() == 'autre'), None)
                            if autre:
                                assigned_cat_id = autre['idCategorie']
                            else:
                                assigned_cat_id = categories[0]['idCategorie'] if categories else None
                        
                        if assigned_cat_id:
                            cursor.execute("UPDATE cas_social SET category_id = %s WHERE id_cas_social = %s", (assigned_cat_id, case['id_cas_social']))
                            
                    print("Social cases migration completed.")
                    
                except Exception as e:
                    print(f"Warning: Could not add category_id column or migrate data. Error: {e}")

            # --- NEW: Add user_id column to ong and administrateur if not exists ---
            for table, id_col in [('ong', 'id_ong'), ('administrateur', 'id_admin')]:
                try:
                    cursor.execute(f"SELECT user_id FROM {table} LIMIT 1")
                except Exception:
                    try:
                        cursor.execute(f"ALTER TABLE {table} ADD COLUMN user_id INT")
                        cursor.execute(f"ALTER TABLE {table} ADD CONSTRAINT fk_{table}_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL")
                        print(f"Added user_id column to {table} table.")
                    except Exception as e:
                        print(f"Warning: Could not add user_id column to {table}. Error: {e}")

            # --- NEW: Migrate existing accounts to users table ---
            cursor.execute("SELECT id_admin, email, mot_de_passe, must_change_password FROM administrateur WHERE user_id IS NULL")
            admins_to_migrate = cursor.fetchall()
            for admin in admins_to_migrate:
                try:
                    cursor.execute("SELECT id FROM users WHERE email = %s", (admin['email'],))
                    existing_user = cursor.fetchone()
                    if existing_user:
                        cursor.execute("UPDATE administrateur SET user_id = %s WHERE id_admin = %s", (existing_user['id'], admin['id_admin']))
                    else:
                        cursor.execute(
                            "INSERT INTO users (email, password_hash, role, must_change_password) VALUES (%s, %s, 'admin', %s)",
                            (admin['email'], admin['mot_de_passe'], admin.get('must_change_password', False))
                        )
                        new_user_id = cursor.lastrowid
                        cursor.execute("UPDATE administrateur SET user_id = %s WHERE id_admin = %s", (new_user_id, admin['id_admin']))
                    print(f"Migrated admin {admin['email']} to users table.")
                except Exception as e:
                    print(f"Warning: Could not migrate admin {admin['email']}. Error: {e}")

            # Migrate ONGs
            cursor.execute("SELECT id_ong, email, mot_de_passe, must_change_password FROM ong WHERE user_id IS NULL")
            ongs_to_migrate = cursor.fetchall()
            for ong in ongs_to_migrate:
                try:
                    cursor.execute("SELECT id FROM users WHERE email = %s", (ong['email'],))
                    existing_user = cursor.fetchone()
                    if existing_user:
                        cursor.execute("UPDATE ong SET user_id = %s WHERE id_ong = %s", (existing_user['id'], ong['id_ong']))
                    else:
                        cursor.execute(
                            "INSERT INTO users (email, password_hash, role, must_change_password) VALUES (%s, %s, 'ong', %s)",
                            (ong['email'], ong['mot_de_passe'], ong.get('must_change_password', False))
                        )
                        new_user_id = cursor.lastrowid
                        cursor.execute("UPDATE ong SET user_id = %s WHERE id_ong = %s", (new_user_id, ong['id_ong']))
                    print(f"Migrated ONG {ong['email']} to users table.")
                except Exception as e:
                    print(f"Warning: Could not migrate ONG {ong['email']}. Error: {e}")

            # Seed Default Categories if empty
            cursor.execute("SELECT COUNT(*) as count FROM categorie")
            if cursor.fetchone()['count'] == 0:
                default_categories = [
                    ('Santé', 'Domaine de la santé'), 
                    ('Éducation', 'Domaine de l\'éducation'), 
                    ('Logement', 'Domaine du logement'), 
                    ('Alimentation', 'Domaine de l\'alimentation'),
                    ('Eau', 'Domaine de l\'eau')
                ]
                cursor.executemany("INSERT INTO categorie (nomCategorie, description) VALUES (%s, %s)", default_categories)
                print("Default categories seeded.")

        conn.commit()
    finally:
        conn.close()
