from flask import Flask, render_template, request, redirect, url_for, flash, session, abort, jsonify, Response
import json
import pymysql
import pymysql.cursors
from datetime import datetime
import os
import uuid

from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import secrets
import random
import smtplib
from email.mime.text import MIMEText
from flask_cors import CORS


from config import Config

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})
app.config.from_object(Config)

import jwt
from datetime import timedelta

# JWT Secret Key
JWT_SECRET = app.config.get('SECRET_KEY', 'mobile_app_secret_key')

def token_required(f):
    """Decorator to require valid JWT token for ONG API endpoints"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
        
        if not token:
            return jsonify({'error': 'Token is missing'}), 401
        
        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            current_ong_id = data['ong_id']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        
        return f(current_ong_id, *args, **kwargs)
    return decorated

def admin_token_required(f):
    """Decorator to require valid Admin JWT token for Admin API endpoints"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
        
        if not token:
            return jsonify({'success': False, 'message': 'Token is missing'}), 401
        
        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            if data.get('role') != 'admin':
                return jsonify({'success': False, 'message': 'Admin access required'}), 403
            current_user_id = data['user_id']
        except jwt.ExpiredSignatureError:
            return jsonify({'success': False, 'message': 'Token has expired'}), 401
        except Exception as e:
            return jsonify({'success': False, 'message': 'Invalid token'}), 401
        
        return f(current_user_id, *args, **kwargs)
    return decorated

# Ensure directories exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['LOGO_FOLDER'], exist_ok=True)
os.makedirs(app.config['DOCS_FOLDER'], exist_ok=True)

# Database Configuration (Now from Config)
DB_HOST = app.config['DB_HOST']
DB_USER = app.config['DB_USER']
DB_PASSWORD = app.config['DB_PASSWORD']
DB_NAME = app.config['DB_NAME']
from locations_data import MAURITANIA_LOCATIONS

from contextlib import contextmanager

# ... imports ...

@contextmanager
def get_db():
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

def get_db_connection():
    # Legacy wrapper for parts not yet refactored or manual usage
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )



def init_db():
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

            # ... (Beneficier, Categorie, Media - No changes)
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

            # Notifications
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id_notification INT AUTO_INCREMENT PRIMARY KEY,
                    id_cas_social INT,
                    message_fr VARCHAR(255) NOT NULL,
                    message_ar VARCHAR(255) NOT NULL,
                    date_notification DATETIME DEFAULT CURRENT_TIMESTAMP,
                    is_read BOOLEAN DEFAULT FALSE,
                    FOREIGN KEY (id_cas_social) REFERENCES cas_social(id_cas_social) ON DELETE CASCADE
                )
            """)

            # --- Fix/Enforce UTF8MB4 for Arabic Support ---
            # Ensure the database itself uses utf8mb4
            cursor.execute(f"ALTER DATABASE {DB_NAME} CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci")
            
            # Convert all specific tables to utf8mb4 to fix "Incorrect string value" errors
            tables_to_fix = ['users', 'administrateur', 'ong', 'cas_social', 'beneficier', 'categorie', 'media', 'notifications']
            for table in tables_to_fix:
                try:
                    cursor.execute(f"ALTER TABLE {table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
                except Exception as e:
                    print(f"Warning: Could not alter table {table}. It might not exist yet. Error: {e}")
            
            # --- Specific Fixes ---
            # Increase logo_url size to 255
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
                    # Migrate existing cases to 'approuvé' status (backward compatibility)
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
                    
                    # Fetch categories map
                    cursor.execute("SELECT idCategorie, nomCategorie FROM categorie")
                    categories = cursor.fetchall() # [{'idCategorie': 1, 'nomCategorie': 'Santé'}, ...]
                    
                    # Fetch ONGs map (to use domain as fallback)
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
                            # Find 'Autre'
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
            # Migrate Admins
            cursor.execute("SELECT id_admin, email, mot_de_passe, must_change_password FROM administrateur WHERE user_id IS NULL")
            admins_to_migrate = cursor.fetchall()
            for admin in admins_to_migrate:
                try:
                    # Check if email already exists in users
                    cursor.execute("SELECT id FROM users WHERE email = %s", (admin['email'],))
                    existing_user = cursor.fetchone()
                    if existing_user:
                        # Link to existing user
                        cursor.execute("UPDATE administrateur SET user_id = %s WHERE id_admin = %s", (existing_user['id'], admin['id_admin']))
                    else:
                        # Create new user
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


# --- Translations ---

TRANSLATIONS = {
    'ar': {
        'title': 'ONG Connect',
        'dashboard': 'لوحة التحكم',
        'administrators': 'المسؤولون',
        'ngos': 'المنظمات الخيرية',
        'social_cases': 'الحالات الاجتماعية',
        'beneficiaries': 'المستفيدون',
        'categories': 'الفئات',
        'media': 'الوسائط',
        'add_new': 'إضافة جديد',
        'edit': 'تعديل',
        'delete': 'حذف',
        'save': 'حفظ',
        'cancel': 'إلغاء',
        'confirm_delete': 'هل أنت متأكد أنك تريد حذف هذا العنصر؟',
        'actions': 'إجراءات',
        'name': 'الاسم',
        'email': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'address': 'العنوان',
        'phone': 'الهاتف',
        'domain': 'مجالات التدخل',
        'status': 'الحالة',
        'description': 'الوصف',
        'date': 'التاريخ',
        'title_field': 'العنوان',
        'first_name': 'الاسم الأول',
        'last_name': 'الاسم الأخير',
        'file_url': 'رابط الملف',
        'verification_doc': 'وثيقة التحقق',
        'current_doc': 'عرض الوثيقة الحالية',
        'doc_help': 'يرجى تحميل وثيقة رسمية تثبت وجود المنظمة (PDF, Image).',
        'welcome': 'مرحباً بك في ONG Connect',
        'language': 'اللغة',
        'switch_lang': 'Français',
        'home': 'الرئيسية',
        'no_records': 'لا توجد سجلات.',
        'success_add': 'تمت الإضافة بنجاح',
        'success_edit': 'تم التعديل بنجاح',
        'success_delete': 'تم الحذف بنجاح',
        'select_domain': '-- اختر المجال --',
        'select_domains': 'اختر مجالاً واحداً أو أكثر',
        'Santé': 'الصحة',
        'Éducation': 'التعليم',
        'Logement': 'الإسكان',
        'Alimentation': 'التغذية',
        # Status - ONG
        'enattente': 'قيد الانتظار',
        'validé': 'تم التوثيق',
        'rejetée': 'مرفوض',
        # Status - Case
        'En cours': 'قيد الإنجاز',
        'Résolu': 'تم الإنجاز',
        'Urgent': 'عاجل',
        # Approval Status
        'en_attente': 'في انتظار الموافقة',
        'approuvé': 'تمت الموافقة',
        'rejeté': 'مرفوض',
        'approval_pending': 'في انتظار موافقة المسؤول',
        'approval_approved': 'تمت الموافقة',
        'approval_rejected': 'مرفوض من قبل المسؤول',
        'awaiting_admin_approval': 'تم إرسال الحالة الاجتماعية بنجاح! في انتظار موافقة المسؤول قبل النشر.',
        'case_approved': 'تمت الموافقة على الحالة الاجتماعية بنجاح.',
        'case_rejected': 'تم رفض الحالة الاجتماعية.',
        'pending_cases': 'الحالات قيد المراجعة',
        'pending_ongs': 'المنظمات قيد المراجعة',
        'approve': 'موافقة',
        'reject': 'رفض',
        # General
        'search': 'بحث...',
        'logout': 'تسجيل الخروج',
        'profile': 'الملف الشخصي',
        'view_details': 'عرض التفاصيل',
        'donor_visitor': 'متبرع / زائر',
        'donor_desc': 'تصفح الحالات الاجتماعية وساهم في إحداث تغيير.',
        'enter': 'دخول',
        'ong_access': 'فضاء المنظمات',
        'ong_desc': 'سجل الدخول لإدارة منظمتك ونشر الحالات.',
        'connect': 'تسجيل الدخول',
        'login_desc': 'أدخل بيانات الاعتماد للوصول إلى مساحتك.',
        'no_account': 'ليس لديك حساب؟',
        'register_now': 'سجل الآن',
        'dashboard_intro': 'تصفح أحدث الحالات الاجتماعية التي تم الإبلاغ عنها من قبل شركائنا.',
        'current_logo': 'الشعار الحالي',
        'impact_tracking': 'تتبع أثرنا',
        'impact_desc': 'انظر كم عدد الأرواح التي لمستها جهودنا المشتركة.',
        'view_beneficiaries_stats': 'عرض إحصائيات المستفيدين',
        'total_beneficiaries': 'إجمالي المستفيدين',
        'top_ongs_impact': 'المنظمات الأكثر تأثيراً',
        'my_profile': 'ملفي الشخصي',
        'my_cases': 'حالاتي الاجتماعية',
        'add_case': 'إضافة حالة جديدة',
        'total_cases': 'إجمالي الحالات',
        'urgent_cases': 'الحالات العاجلة',
        'resolved_cases': 'الحالات المحلولة',
        'case_details': 'تفاصيل الحالة',
        'back_to_profile': 'العودة للملف الشخصي',
        'no_cases': 'لا توجد حالات اجتماعية بعد',
        'start_adding': 'ابدأ بإضافة حالتك الأولى',
        'publication_date': 'تاريخ النشر',
        'beneficiaries_list': 'قائمة المستفيدين',
        'media_gallery': 'معرض الوسائط',
        'latest_cases': 'أحدث الحالات',
        'all': 'الكل',
        'by_category': 'التوزيع حسب القطاع',
        'by_ong': 'التوزيع حسب المنظمة',
        'beneficiary_subtitle': 'متابعة وإدارة المستفيدين المساعدين',
        'ong_subtitle': 'نظرة عامة وإحصائيات المنظمات الشريكة',
        'filters': 'المرشحات',
        'filters_desc': 'استخدم المرشحات لتحديث الرسوم البيانية في الوقت الفعلي.',
        'reset_filters': 'إعادة تعيين',
        'reset_filters_long': 'إعادة تعيين المرشحات',
        'registered_orgs': 'المنظمات المسجلة',
        'validated_ongs': 'المنظمات الموثقة',
        'verification_req': 'مراجعة مطلوبة',
        'sector_impact': 'الأثر حسب القطاع',
        'validation_state': 'حالة التوثيق',
        'detailed_registry': 'السجل التفصيلي',
        'total_ongs': 'إجمالي المنظمات',
        'active': 'نشطة',
        'verification': 'التحقق',
        'contact': 'معلومات الاتصال',
        'admin_login': 'تسجيل دخول المسؤول',
        'admin_login_desc': 'المساحة المخصصة للمسؤولين',
        'feature_unavailable': 'هذه الميزة غير متوفرة بعد. يرجى الاتصال بالمسؤول.',
        'forgot_password': 'نسيت كلمة المرور؟',
        'reset_subtitle': 'أدخل بريدك الإلكتروني لاستلام كلمة مرور جديدة.',
        'send_reset': 'إرسال كلمة مرور جديدة',
        'back_login': 'العودة لتسجيل الدخول',
        'email_not_found': 'البريد الإلكتروني غير موجود.',
        'password_reset_success': 'تم إعادة تعيين كلمة المرور. تحقق من بريدك الإلكتروني.',
        'hero_title': 'معاً من أجل عالم أفضل',
        'hero_subtitle': 'المنصة التي تربط المنظمات غير الحكومية بالاحتياجات الحقيقية للمجتمع.',
        'join_movement': 'انضم إلينا',
        'active_ongs': 'منظمة نشطة',
        'search_placeholder': 'ابحث عن حالة...',
        'filter_by': 'فرز حسب',
        'all_statuses': 'جميع الحالات',
        'all_ongs_filter': 'جميع المنظمات',
        'all_domains': 'جميع المجالات',
        'clear_filters': 'مسح الفلاتر',
        'showing_results': 'عرض النتائج',
        'no_results_found': 'لم يتم العثور على نتائج',
        'change_password_title': 'تغيير كلمة المرور',
        'new_password': 'كلمة المرور الجديدة',
        'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
        'passwords_do_not_match': 'كلمات المرور غير متطابقة',
        'wilaya': 'الولاية',
        'moughataa': 'المقاطعة',
        'select_wilaya': '-- اختر ولاية --',
        'select_moughataa': '-- اختر مقاطعة --',
        'specific_location_details': 'تفاصيل الموقع المحددة...',
        'select_category': '-- اختر فئة --',
        'allowed_formats': 'الصيغ المسموح بها: صور، فيديوهات.',
        'attached_media': 'الوسائط المرفقة',
        'view': 'عرض',
        'call_ong': 'اتصل بالمنظمة',
        'email': 'البريد الإلكتروني',
    },
    'fr': {
        'title': 'ONG Connect',
        'dashboard': 'Tableau de bord',
        'administrators': 'Administrateurs',
        'ngos': 'ONGs',
        'social_cases': 'Cas Sociaux',
        'beneficiaries': 'Bénéficiaires',
        'categories': 'Catégories',
        'media': 'Médias',
        'add_new': 'Ajouter nouveau',
        'edit': 'Modifier',
        'delete': 'Supprimer',
        'save': 'Enregistrer',
        'cancel': 'Annuler',
        'confirm_delete': 'Êtes-vous sûr de vouloir supprimer cet élément ?',
        'actions': 'Actions',
        'name': 'Nom',
        'email': 'Email',
        'password': 'Mot de passe',
        'address': 'Adresse',
        'phone': 'Téléphone',
        'domain': 'Domaines d\'intervention',
        'status': 'Statut',
        'description': 'Description',
        'date': 'Date',
        'title_field': 'Titre',
        'first_name': 'Prénom',
        'last_name': 'Nom',
        'file_url': 'URL du fichier',
        'verification_doc': 'Document de Vérification',
        'current_doc': 'Voir le document actuel',
        'doc_help': 'Veuillez télécharger un document officiel prouvant l\'existence de votre ONG (PDF, Image).',
        'welcome': 'Bienvenue sur ONG Connect',
        'language': 'Langue',
        'switch_lang': 'العربية',
        'home': 'Accueil',
        'no_records': 'Aucun enregistrement.',
        'success_add': 'Ajouté avec succès',
        'success_edit': 'Modifié avec succès',
        'success_delete': 'Supprimé avec succès',
        'select_domain': '-- Sélectionner le domaine --',
        'select_domains': 'Sélectionnez un ou plusieurs domaines',
        'Santé': 'Santé',
        'Éducation': 'Éducation',
        'Logement': 'Logement',
        'Alimentation': 'Alimentation',
        # Status - ONG
        'enattente': 'En attente',
        'validé': 'Validé',
        'rejetée': 'Rejeté',
        # Status - Case
        'En cours': 'En cours',
        'Résolu': 'Résolu',
        'Urgent': 'Urgent',
        # Approval Status
        'en_attente': 'En attente d\'approbation',
        'approuvé': 'Approuvé',
        'rejeté': 'Rejeté',
        'approval_pending': 'En attente d\'approbation',
        'approval_approved': 'Approuvé',
        'approval_rejected': 'Rejeté par l\'administrateur',
        'awaiting_admin_approval': 'Cas social soumis avec succès ! En attente d\'approbation par un administrateur avant publication.',
        'case_approved': 'Cas social approuvé avec succès.',
        'case_rejected': 'Cas social rejeté.',
        'pending_cases': 'Cas en attente de révision',
        'pending_ongs': 'ONGs en attente de validation',
        'approve': 'Approuver',
        'reject': 'Rejeter',
        # General
        'search': 'Rechercher...',
        'logout': 'Déconnexion',
        'profile': 'Profil',
        'view_details': 'Voir détails',
        'donor_visitor': 'Donateur / Visiteur',
        'donor_desc': 'Découvrez les cas sociaux et contribuez à faire la différence.',
        'enter': 'Entrer',
        'ong_access': 'Espace ONG',
        'ong_desc': 'Connectez-vous pour gérer votre ONG et publier des cas.',
        'connect': 'Se connecter',
        'login_desc': 'Entrez vos identifiants pour accéder à votre espace.',
        'no_account': 'Pas encore de compte ?',
        'register_now': 'Inscrivez-vous maintenant',
        'dashboard_intro': 'Parcourez les derniers cas sociaux signalés par nos ONGs partenaires.',
        'current_logo': 'Logo actuel',
        'impact_tracking': 'Suivi de notre impact',
        'impact_desc': 'Voyez combien de vies ont été touchées par nos efforts collectifs.',
        'view_beneficiaries_stats': 'Voir les statistiques des bénéficiaires',
        'total_beneficiaries': 'Total des bénéficiaires',
        'top_ongs_impact': 'ONGs les plus impactantes',
        'my_profile': 'Mon profil',
        'my_cases': 'Mes cas sociaux',
        'add_case': 'Ajouter un cas',
        'total_cases': 'Total des cas',
        'urgent_cases': 'Cas urgents',
        'resolved_cases': 'Cas résolus',
        'case_details': 'Détails du cas',
        'back_to_profile': 'Retour au profil',
        'no_cases': 'Aucun cas social pour le moment',
        'start_adding': 'Commencez par ajouter votre premier cas',
        'publication_date': 'Date de publication',
        'beneficiaries_list': 'Liste des bénéficiaires',
        'media_gallery': 'Galerie média',
        'latest_cases': 'Derniers Cas',
        'all': 'Tous',
        'by_category': 'Distribution par Secteur',
        'by_ong': 'Distribution par ONG',
        'beneficiary_subtitle': 'Suivi et gestion des bénéficiaires assistés',
        'ong_subtitle': 'Vue d\'ensemble et statistiques des organisations partenaires',
        'filters': 'Filtres',
        'filters_desc': 'Utilisez les filtres pour affiner les graphiques en temps réel.',
        'reset_filters': 'Réinitialiser',
        'reset_filters_long': 'Réinitialiser les filtres',
        'registered_orgs': 'Organisations inscrites',
        'validated_ongs': 'ONGs validées',
        'verification_req': 'Vérification requise',
        'sector_impact': 'Impact par Secteur',
        'validation_state': 'État des Validations',
        'detailed_registry': 'Registre Détaillé',
        'total_ongs': 'Total ONGs',
        'active': 'Active',
        'verification': 'Vérification',
        'contact': 'Contact',
        'admin_login': 'Connexion Admin',
        'admin_login_desc': 'Espace réservé aux administrateurs',
        'feature_unavailable': 'Cette fonctionnalité n\'est pas encore disponible. Veuillez contacter un administrateur.',
        'forgot_password': 'Mot de passe oublié ?',
        'reset_subtitle': 'Entrez votre email pour recevoir un nouveau mot de passe.',
        'send_reset': 'Envoyer le nouveau mot de passe',
        'back_login': 'Retour à la connexion',
        'email_not_found': 'Email introuvable.',
        'password_reset_success': 'Mot de passe réinitialisé. Vérifiez votre email.',
        'hero_title': 'Ensemble pour un monde meilleur',
        'hero_subtitle': 'La plateforme qui connecte les ONGs aux besoins réels de la communauté.',
        'join_movement': 'Rejoignez le mouvement',
        'active_ongs': 'ONGs Actives',
        'search_placeholder': 'Rechercher un cas...',
        'filter_by': 'Filtrer par',
        'all_statuses': 'Tous les statuts',
        'all_ongs_filter': 'Toutes les ONGs',
        'all_domains': 'Tous les domaines',
        'clear_filters': 'Effacer les filtres',
        'showing_results': 'Affichage des résultats',
        'no_results_found': 'Aucun résultat trouvé',
        'change_password_title': 'Changer le mot de passe',
        'new_password': 'Nouveau mot de passe',
        'confirm_new_password': 'Confirmer le nouveau mot de passe',
        'passwords_do_not_match': 'Les mots de passe ne correspondent pas',
        'wilaya': 'Wilaya',
        'moughataa': 'Moughataa',
        'select_wilaya': '-- Sélectionner une Wilaya --',
        'select_moughataa': '-- Sélectionner une Moughataa --',
        'specific_location_details': 'Détails de l\'emplacement spécifique...',
        'select_category': '-- Sélectionner une catégorie --',
        'allowed_formats': 'Formats autorisés : Images, Vidéos.',
        'attached_media': 'Médias attachés',
        'view': 'Voir',
        'call_ong': 'Appeler ONG',
        'email': 'Email',
    }
}

@app.before_request
def before_request():
    if 'lang' not in session:
        session['lang'] = 'ar'
    
    # Custom CSRF Protection
    # 1. Generate token if not exists
    if 'csrf_token' not in session:
        session['csrf_token'] = os.urandom(24).hex()

    app.jinja_env.globals['csrf_token'] = lambda: session['csrf_token']

    # 2. Check token on POST/PUT/DELETE
    if request.method in ['POST', 'PUT', 'DELETE']:
        # Exempt API routes (they use JWT authentication)
        if request.path.startswith('/api/'):
            return  # Skip CSRF for mobile API
        
        # Check Form Data
        token = request.form.get('csrf_token')
        
        # Check Headers (for AJAX)
        if not token:
            token = request.headers.get('X-CSRFToken')
            
        if not token or token != session.get('csrf_token'):
            abort(400, description="CSRF Token Missing or Invalid")

@app.context_processor
def inject_conf_var():
    lang = session.get('lang', 'ar')
    return dict(
        lang=lang,
        t=TRANSLATIONS[lang],
        dir='rtl' if lang == 'ar' else 'ltr',
        locations=MAURITANIA_LOCATIONS
    )

# --- Decorators ---

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('user_type') != 'admin':
            flash("Accès réservé aux administrateurs.", "danger")
            return redirect(url_for('admin_login'))
        return f(*args, **kwargs)
    return decorated_function

# --- Routes ---



@app.route('/create_default_admin')
def create_default_admin():
    # Only allow when no admin exists at all (bootstrap scenario)
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) as count FROM administrateur")
                if cursor.fetchone()['count'] > 0:
                    flash("Accès refusé.", "danger")
                    return redirect(url_for('unified_login'))
                
                hashed = generate_password_hash('admin123')
                # Create in users table first
                cursor.execute(
                    "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'admin')",
                    ('admin@ongconnect.com', hashed)
                )
                new_user_id = cursor.lastrowid
                cursor.execute(
                    "INSERT INTO administrateur (nom, email, mot_de_passe, user_id) VALUES ('Admin', 'admin@ongconnect.com', %s, %s)",
                    (hashed, new_user_id)
                )
                conn.commit()
                return "Default admin created: admin@ongconnect.com / admin123"
    except Exception as e:
        return f"Error: {e}"

@app.route('/set_language/<lang_code>')
def set_language(lang_code):
    if lang_code in ['ar', 'fr']:
        session['lang'] = lang_code
    return redirect(request.referrer or url_for('index'))

@app.route('/')
def index():
    return render_template('landing.html')

def get_pagination_iter(current_page, total_pages, left_edge=1, right_edge=1, left_current=1, right_current=1):
    """
    Generates a list of page numbers and None for ellipses.
    Example: 1 ... 4 5 6 ... 10
    """
    if total_pages <= 1:
        return []
    
    # If total pages is small, just show all
    if total_pages <= 7:
        return list(range(1, total_pages + 1))

    pages = []
    last = 0

    for num in range(1, total_pages + 1):
        if (num <= left_edge) or \
           (num > total_pages - right_edge) or \
           (abs(num - current_page) <= left_current): # Use left_current for both sides for simplicity/symmetry
            
            if last + 1 != num:
                pages.append(None) # Ellipsis
            pages.append(num)
            last = num
            
    return pages

@app.route('/public/dashboard')
def public_dashboard():
    page = request.args.get('page', 1, type=int)
    per_page = 3 # Adjusted to 3 so pagination is visible with few cases
    offset = (page - 1) * per_page
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Count total approved cases only
            cursor.execute("SELECT COUNT(*) as count FROM cas_social WHERE statut_approbation = 'approuvé'")
            total_cases = cursor.fetchone()['count']
            total_pages = (total_cases + per_page - 1) // per_page
            
            # Ensure page is within bounds
            if page < 1: page = 1
            if total_pages > 0 and page > total_pages: page = total_pages

            # Recalculate offset if page changed
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

            # Fetch random/latest ONGs for the dashboard
            cursor.execute("SELECT * FROM ong ORDER BY update_at DESC LIMIT 6")
            ongs = cursor.fetchall()

            # Fetch ALL ONGs for filter dropdown
            cursor.execute("SELECT id_ong, nom_ong FROM ong ORDER BY nom_ong")
            all_ongs = cursor.fetchall()

            # Fetch categories for filter
            cursor.execute("SELECT * FROM categorie")
            categories = cursor.fetchall()

            # Fetch ALL approved cases for client-side filtering
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
                         all_cases=all_cases,  # For client-side filtering
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

@app.route('/public/statistics')
def public_statistics():
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Fetch ALL approved cases for statistics
            sql = """
                SELECT c.*, o.nom_ong, o.logo_url
                FROM cas_social c 
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                WHERE c.statut_approbation = 'approuvé'
                ORDER BY c.date_publication DESC
            """
            cursor.execute(sql)
            cases = cursor.fetchall()
            
            # Calculate stats
            total_cases = len(cases)
            urgent_cases = sum(1 for case in cases if case['statut'] == 'Urgent')
            resolved_cases = sum(1 for case in cases if case['statut'] == 'Résolu')
            
            # Statistics by ONG
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

@app.route('/public/beneficiaries')
def public_beneficiaries():
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Fetch Statistics for initial render (Strict: Only Resolved Cases)
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
            
            # Fetch ONGs for filter
            cursor.execute("SELECT id_ong, nom_ong FROM ong ORDER BY nom_ong")
            ongs = cursor.fetchall()
            
            # Fetch Categories (Domains) from the categorie table
            cursor.execute("SELECT nomCategorie FROM categorie ORDER BY nomCategorie")
            categories = [c['nomCategorie'] for c in cursor.fetchall()]
            
            # Fetch Unique Locations (from beneficier or cas_social)
            cursor.execute("SELECT DISTINCT adresse FROM beneficier WHERE adresse IS NOT NULL AND adresse != ''")
            locations = [l['adresse'] for l in cursor.fetchall()]
            
    return render_template('public/beneficiaries.html', 
                         total_beneficiaries=total_beneficiaries,
                         filter_ongs=ongs,
                         filter_categories=categories,
                         filter_locations=locations)

# /api/cases is now handled by api_get_cases at the end of the file for better standardization.

@app.route('/api/stats/beneficiaries')
def api_beneficiary_stats():
    ong_id = request.args.get('ong_id')
    category = request.args.get('category')
    location = request.args.get('location')
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Base query using UNION for Strict Count (Only Resolved)
            query = """
                SELECT * FROM (
                    SELECT b.id_beneficiaire, b.adresse as b_adresse, c.adresse as c_adresse, o.id_ong, o.nom_ong, o.domaine_intervation 
                    FROM beneficier b
                    JOIN cas_social c ON b.id_cas_social = c.id_cas_social
                    JOIN ong o ON c.id_ong = o.id_ong
                    WHERE c.statut = 'Résolu'
                    
                    UNION ALL
                    
                    SELECT NULL, c.adresse, c.adresse, o.id_ong, o.nom_ong, o.domaine_intervation
                    FROM cas_social c
                    JOIN ong o ON c.id_ong = o.id_ong
                    WHERE c.statut = 'Résolu' 
                    AND c.id_cas_social NOT IN (SELECT DISTINCT id_cas_social FROM beneficier)
                ) as combined
                WHERE 1=1
            """
            params = []
            
            if ong_id:
                query += " AND id_ong = %s"
                params.append(ong_id)
            if location:
                query += " AND (b_adresse LIKE %s OR c_adresse LIKE %s)"
                params.append(f"%{location}%")
                params.append(f"%{location}%")
            if category:
                query += " AND domaine_intervation LIKE %s"
                params.append(f"%{category}%")
            
            cursor.execute(query, params)
            results = cursor.fetchall()
            
            # Process results for stats
            total = len(results)
            by_ong = {}
            by_category = {}
            by_location = {}
            
            for row in results:
                # By ONG
                ong_name = row['nom_ong']
                by_ong[ong_name] = by_ong.get(ong_name, 0) + 1
                
                # By Location (Simplistic: just use the address or first part)
                loc = row['b_adresse'] or "Inconnu"
                # If it's a long address, maybe try to extract city. For now, use as is.
                by_location[loc] = by_location.get(loc, 0) + 1
                
                # By Category (Domain)
                domains = [d.strip() for d in row['domaine_intervation'].split(',')]
                for d in domains:
                    if d:
                        by_category[d] = by_category.get(d, 0) + 1
            
            lang_code = session.get('lang', 'ar')
            t = TRANSLATIONS[lang_code]

            # Convert to list for Chart.js
            stats = {
                'total': total,
                'by_ong': [{'label': k, 'value': v} for k, v in sorted(by_ong.items(), key=lambda x: x[1], reverse=True)[:10]],
                'by_category': [{'label': t.get(k, k), 'value': v} for k, v in by_category.items()],
                'by_location': [{'label': k, 'value': v} for k, v in sorted(by_location.items(), key=lambda x: x[1], reverse=True)[:10]]
            }
            
            return jsonify(stats)


@app.route('/public/case/<int:id>')
def public_case_details(id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Fetch Case Details with ONG info
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
            
            # Check Visibility Rule:
            # Case must be 'approuvé' OR User must be Admin OR User must be the Owner ONG
            is_approved = case.get('statut_approbation') == 'approuvé'
            is_admin = session.get('user_type') == 'admin'
            is_owner = session.get('user_type') == 'ong' and session.get('user_id') == case['id_ong']
            
            if not (is_approved or is_admin or is_owner):
                 # Pending or Rejected case -> 404 for public
                return "Case not found", 404

            # Fetch all media for this case
            cursor.execute("SELECT * FROM media WHERE id_cas_social = %s", (id,))
            media_list = cursor.fetchall()
            
    finally:
        conn.close()
    return render_template('public/case_details.html', case=case, media_list=media_list)


@app.route('/ong/login', methods=['GET', 'POST'])
def ong_login():
    # Redirect legacy route to unified login
    return redirect(url_for('unified_login'))


@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    # Redirect legacy route to unified login
    return redirect(url_for('unified_login'))

@app.route('/forgot_password', methods=['GET', 'POST'])
def forgot_password():
    lang_code = session.get('lang', 'ar')
    t = TRANSLATIONS[lang_code]
    
    if request.method == 'POST':
        email = request.form.get('email')
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                # 1. Check if user exists in the unified users table
                cursor.execute("SELECT id, email, role FROM users WHERE email=%s", (email,))
                user = cursor.fetchone()
                
                if user:
                     # Generate random password (8-digit number)
                    new_password = ''.join([str(random.randint(0, 9)) for _ in range(8)])
                    hashed_password = generate_password_hash(new_password)
                    
                    # 2. Update unified users table
                    cursor.execute(
                        "UPDATE users SET password_hash=%s, must_change_password=1 WHERE id=%s", 
                        (hashed_password, user['id'])
                    )
                    
                    # 3. Update legacy table for consistency
                    if user['role'] == 'ong':
                        cursor.execute("UPDATE ong SET mot_de_passe=%s, must_change_password=1 WHERE user_id=%s", (hashed_password, user['id']))
                    elif user['role'] == 'admin':
                        cursor.execute("UPDATE administrateur SET mot_de_passe=%s, must_change_password=1 WHERE user_id=%s", (hashed_password, user['id']))
                    
                    conn.commit()
                    
                    # Send Email
                    sent = send_reset_email(email, new_password)
                    if sent:
                        flash(t.get('password_reset_success'), "success")
                        return redirect(url_for('unified_login'))
                    else:
                        flash("Erreur lors de l'envoi de l'email.", "danger")
                else:
                    flash(t.get('email_not_found'), "danger")
    
    return render_template('ong/forgot_password.html')

@app.route('/ong/profile')
def ong_profile():
    # Check if user is logged in as ONG
    if session.get('user_type') != 'ong':
        flash('Please login to access your profile', 'warning')
        return redirect(url_for('ong_login'))
    
    ong_id = session.get('user_id')
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Fetch ONG details
            cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (ong_id,))
            ong = cursor.fetchone()
            
            if not ong:
                flash('ONG not found', 'danger')
                session.clear()
                return redirect(url_for('ong_login'))
            
            # Fetch social cases for this ONG with first media image
            cursor.execute("""
                SELECT c.*, 
                       (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) as first_image
                FROM cas_social c
                WHERE c.id_ong=%s 
                ORDER BY c.date_publication DESC
            """, (ong_id,))
            cases = cursor.fetchall()
            
            # Calculate stats
            total_cases = len(cases)
            urgent_cases = sum(1 for case in cases if case['statut'] == 'Urgent')
            resolved_cases = sum(1 for case in cases if case['statut'] == 'Résolu')
    
    return render_template('ong/profile.html', 
                          ong=ong, 
                          cases=cases,
                          total_cases=total_cases,
                          urgent_cases=urgent_cases,
                          resolved_cases=resolved_cases)

@app.route('/ong/dashboard')
def ong_dashboard():
    # Check if user is logged in as ONG
    if session.get('user_type') != 'ong':
        flash('Please login to access your dashboard', 'warning')
        return redirect(url_for('ong_login'))
    
    ong_id = session.get('user_id')
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Fetch ONG details (for name and basic info)
            cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (ong_id,))
            ong = cursor.fetchone()
            
            if not ong:
                flash('ONG not found', 'danger')
                session.clear()
                return redirect(url_for('ong_login'))
            
            # Fetch social cases for this ONG with first media image
            cursor.execute("""
                SELECT c.*, 
                       (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) as first_image
                FROM cas_social c
                WHERE c.id_ong=%s 
                ORDER BY c.date_publication DESC
            """, (ong_id,))
            cases = cursor.fetchall()
            
            # Calculate stats
            total_cases = len(cases)
            urgent_cases = sum(1 for case in cases if case['statut'] == 'Urgent')
            resolved_cases = sum(1 for case in cases if case['statut'] == 'Résolu')
    
    return render_template('ong/dashboard.html', 
                          ong=ong, 
                          cases=cases,
                          total_cases=total_cases,
                          urgent_cases=urgent_cases,
                          resolved_cases=resolved_cases)

@app.route('/ong/case/<int:id>')
def ong_case_details(id):
    # Check if user is logged in as ONG
    if session.get('user_type') != 'ong':
        flash('Please login to access case details', 'warning')
        return redirect(url_for('ong_login'))
    
    ong_id = session.get('user_id')
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Fetch case details (ensure it belongs to this ONG)
            cursor.execute("""
                SELECT * FROM cas_social 
                WHERE id_cas_social=%s AND id_ong=%s
            """, (id, ong_id))
            case = cursor.fetchone()
            
            if not case:
                flash(TRANSLATIONS[session.get('lang', 'ar')].get('no_records', 'Case not found or access denied'), 'danger')
                return redirect(url_for('ong_profile'))
            
            # Fetch media for this case
            cursor.execute("SELECT * FROM media WHERE id_cas_social=%s", (id,))
            media_list = cursor.fetchall()
            
            # Fetch beneficiaries for this case
            cursor.execute("SELECT * FROM beneficier WHERE id_cas_social=%s", (id,))
            beneficiaries = cursor.fetchall()
    
    return render_template('ong/case_details.html', 
                          case=case, 
                          media_list=media_list, 
                          beneficiaries=beneficiaries)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

@app.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) as count FROM administrateur")
            admins_count = cursor.fetchone()['count']
            
            cursor.execute("SELECT COUNT(*) as count FROM ong")
            ngos_count = cursor.fetchone()['count']
            
            cursor.execute("SELECT COUNT(*) as count FROM cas_social")
            cases_count = cursor.fetchone()['count']
            
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
            beneficiaries_count = cursor.fetchone()['count']
            
            # Fetch pending social cases
            cursor.execute("""
                SELECT c.*, o.nom_ong 
                FROM cas_social c
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                WHERE c.statut_approbation = 'en_attente'
                ORDER BY c.date_publication DESC
            """)
            pending_cases = cursor.fetchall()

            # Fetch pending ONGs
            cursor.execute("""
                SELECT * FROM ong 
                WHERE statut_de_validation = 'enattente'
                ORDER BY update_at DESC
            """)
            pending_ongs = cursor.fetchall()
            
            counts = {
                'admins': admins_count,
                'ngos': ngos_count,
                'cases': cases_count,
                'beneficiaries': beneficiaries_count
            }
    finally:
        conn.close()
    return render_template('index.html', counts=counts, pending_cases=pending_cases, pending_ongs=pending_ongs)


@app.route('/login', methods=['GET', 'POST'])
def unified_login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # Query the unified users table
                cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
                user = cursor.fetchone()
                
                if user:
                    # Verify password (supports both hashed and legacy plain-text migration)
                    password_valid = False
                    db_password = user['password_hash']
                    
                    if db_password.startswith('scrypt:') or db_password.startswith('pbkdf2:'):
                        password_valid = check_password_hash(db_password, password)
                    elif db_password == password:
                        # Migrate plain-text password to hash
                        new_hash = generate_password_hash(password)
                        cursor.execute("UPDATE users SET password_hash=%s WHERE id=%s", (new_hash, user['id']))
                        conn.commit()
                        password_valid = True
                    
                    if password_valid:
                        if user['role'] == 'admin':
                            # Fetch admin profile
                            cursor.execute("SELECT * FROM administrateur WHERE user_id=%s", (user['id'],))
                            admin = cursor.fetchone()
                            
                            if admin:
                                session['user_type'] = 'admin'
                                session['user_id'] = admin['id_admin']
                                session['auth_user_id'] = user['id']  # Store users table ID
                                session['user_name'] = admin['nom']
                                
                                if user.get('must_change_password', 0) == 1:
                                    return redirect(url_for('change_password'))
                                    
                                flash('Bienvenue Administrateur.', 'success')
                                return redirect(url_for('admin_dashboard'))
                            else:
                                flash('Profil administrateur introuvable.', 'danger')
                                return redirect(url_for('unified_login'))
                        
                        elif user['role'] == 'ong':
                            # Fetch ONG profile
                            cursor.execute("SELECT * FROM ong WHERE user_id=%s", (user['id'],))
                            ong = cursor.fetchone()
                            
                            if ong:
                                status = ong.get('statut_de_validation', 'enattente')
                                
                                if status == 'validé':
                                    session['user_type'] = 'ong'
                                    session['user_id'] = ong['id_ong']
                                    session['auth_user_id'] = user['id']
                                    session['user_name'] = ong['nom_ong']
                                    
                                    if user.get('must_change_password', 0) == 1:
                                         return redirect(url_for('change_password'))
                                         
                                    return redirect(url_for('ong_profile'))
                                elif status == 'rejetée':
                                     flash('Votre compte a été rejeté par un administrateur.', 'danger')
                                else: # enattente
                                     flash('Votre compte est en attente de validation par un administrateur.', 'warning')
                                return redirect(url_for('unified_login'))
                            else:
                                flash('Profil ONG introuvable.', 'danger')
                                return redirect(url_for('unified_login'))
                    else:
                        flash('Email ou mot de passe incorrect.', 'danger')
                else:
                    flash('Email ou mot de passe incorrect.', 'danger')    
        finally:
            conn.close()
            
    return render_template('public/login.html')



@app.route('/change_password', methods=['GET', 'POST'])
def change_password():
    if not session.get('user_id'):
        return redirect(url_for('unified_login'))
        
    if request.method == 'POST':
        new_password = request.form['new_password']
        confirm_password = request.form['confirm_password']
        
        if new_password != confirm_password:
            flash(TRANSLATIONS[session.get('lang', 'ar')]['passwords_do_not_match'], 'danger')
            return redirect(request.url)
            
        hashed_pw = generate_password_hash(new_password)
        auth_user_id = session.get('auth_user_id')  # Use the users table ID
        user_type = session.get('user_type')
        
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # Update the unified users table
                if auth_user_id:
                    cursor.execute("UPDATE users SET password_hash=%s, must_change_password=0 WHERE id=%s", (hashed_pw, auth_user_id))
                else:
                    # Fallback for legacy sessions (before migration)
                    user_id = session.get('user_id')
                    if user_type == 'ong':
                        cursor.execute("UPDATE ong SET mot_de_passe=%s, must_change_password=0 WHERE id_ong=%s", (hashed_pw, user_id))
                    elif user_type == 'admin':
                        cursor.execute("UPDATE administrateur SET mot_de_passe=%s, must_change_password=0 WHERE id_admin=%s", (hashed_pw, user_id))
            conn.commit()
            
            flash(TRANSLATIONS[session.get('lang', 'ar')]['success_edit'], 'success')
            
            if user_type == 'ong':
                return redirect(url_for('ong_profile'))
            else:
                return redirect(url_for('admin_dashboard'))
                
        except Exception as e:
            flash(f"Error: {e}", 'danger')
        finally:
            conn.close()
            
    return render_template('public/change_password.html')



@app.route('/api/verify_ong_password', methods=['POST'])
def verify_ong_password():
    data = request.get_json()
    ong_id = data.get('ong_id')
    password = data.get('password')
    
    if not ong_id or not password:
        return {'success': False, 'message': 'Missing data'}, 400
        
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Note: storing passwords in plain text as per existing implementation
            cursor.execute("SELECT id_ong, mot_de_passe FROM ong WHERE id_ong=%s", (ong_id,))
            result = cursor.fetchone()
            
            if result and check_and_migrate_password(conn, 'ong', 'id_ong', result['id_ong'], password, result['mot_de_passe']):
                # Set authorization in session for Edit actions
                session['authorized_ong_id'] = int(ong_id)
                return {'success': True}
            else:
                return {'success': False, 'message': 'Mot de passe incorrect'}, 401
    finally:
        conn.close()

@app.route('/api/verify_admin_credentials', methods=['POST'])
def verify_admin_credentials():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return {'success': False, 'message': 'Missing credentials'}, 400
        
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Todo: hash check in production
            cursor.execute("SELECT * FROM administrateur WHERE email=%s", (email,))
            admin = cursor.fetchone()
            
            if admin and check_and_migrate_password(conn, 'administrateur', 'id_admin', admin['id_admin'], password, admin['mot_de_passe']):
                return {'success': True}
            else:
                return {'success': False, 'message': 'Invalid credentials'}, 401
    finally:
        conn.close()

@app.route('/admin/case/<int:id>/approve', methods=['POST'])
@admin_required
def approve_case(id):
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("UPDATE cas_social SET statut_approbation = 'approuvé' WHERE id_cas_social = %s", (id,))
            
            # Trigger Notification
            cursor.execute("SELECT titre FROM cas_social WHERE id_cas_social = %s", (id,))
            case = cursor.fetchone()
            if case:
                case_title = case['titre']
                cursor.execute("""
                    INSERT INTO notifications (id_cas_social, message_fr, message_ar)
                    VALUES (%s, %s, %s)
                """, (id, f"Nouveau cas social publié : {case_title}", f"تم نشر حالة اجتماعية جديدة: {case_title}"))
                
        conn.commit()
    flash(TRANSLATIONS[session.get('lang', 'ar')]['case_approved'], 'success')
    return redirect(url_for('admin_dashboard'))

@app.route('/admin/case/<int:id>/reject', methods=['POST'])
@admin_required
def reject_case(id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # 1. Clean Media Files
            cursor.execute("SELECT file_url FROM media WHERE id_cas_social=%s", (id,))
            media_files = cursor.fetchall()
            for media in media_files:
                if media['file_url']:
                    file_path = os.path.join('static', media['file_url'])
                    if os.path.exists(file_path):
                        try: os.remove(file_path)
                        except: pass
            
            # 2. Delete Database Records (Order matters for FK)
            cursor.execute("DELETE FROM media WHERE id_cas_social=%s", (id,))
            cursor.execute("DELETE FROM beneficier WHERE id_cas_social=%s", (id,))
            cursor.execute("DELETE FROM cas_social WHERE id_cas_social = %s", (id,))
        conn.commit()
    finally:
        conn.close()
    flash('Cas social rejeté et supprimé avec succès.', 'success')
    return redirect(url_for('admin_dashboard'))

# --- Mobile Admin API Endpoints ---

@app.route('/api/admin/pending-ongs', methods=['GET'])
@admin_token_required
def api_admin_pending_ongs(admin_user_id):
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
                
                # Convert to list of dicts
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

@app.route('/api/admin/pending-cases', methods=['GET'])
@admin_token_required
def api_admin_pending_cases(admin_user_id):
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

@app.route('/api/admin/ong/<int:id>/approve', methods=['POST'])
@admin_token_required
def api_admin_approve_ong(admin_user_id, id):
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE ong SET statut_de_validation = 'validé' WHERE id_ong = %s", (id,))
            conn.commit()
        return jsonify({'success': True, 'message': 'ONG approved successfully'})
    except Exception as e:
        print(f"Error approving ONG: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/ong/<int:id>/reject', methods=['POST'])
@admin_token_required
def api_admin_reject_ong(admin_user_id, id):
    try:
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # Same logic as web version - hard delete
                # 1. Clean up cases and their media
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
                
                # 2. Clean up ONG files
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
                
                # 3. Delete ONG
                cursor.execute("DELETE FROM ong WHERE id_ong=%s", (id,))
                conn.commit()
            
            return jsonify({'success': True, 'message': 'ONG rejected and deleted'})
        finally:
            conn.close()
    except Exception as e:
        print(f"Error rejecting ONG: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/case/<int:id>/approve', methods=['POST'])
@admin_token_required
def api_admin_approve_case(admin_user_id, id):
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("UPDATE cas_social SET statut_approbation = 'approuvé' WHERE id_cas_social = %s", (id,))
                
                # Trigger Notification
                cursor.execute("SELECT titre FROM cas_social WHERE id_cas_social = %s", (id,))
                case = cursor.fetchone()
                if case:
                    case_title = case['titre']
                    cursor.execute("""
                        INSERT INTO notifications (id_cas_social, message_fr, message_ar)
                        VALUES (%s, %s, %s)
                    """, (id, f"Nouveau cas social publié : {case_title}", f"تم نشر حالة اجتماعية جديدة: {case_title}"))
                    
            conn.commit()
        return jsonify({'success': True, 'message': 'Case approved successfully'})
    except Exception as e:
        print(f"Error approving case: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/admin/case/<int:id>/reject', methods=['POST'])
@admin_token_required
def api_admin_reject_case(admin_user_id, id):
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


# --- CRUD Routes ---

# 1. Administrateur
@app.route('/admins')
@admin_required
def list_admins():
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM administrateur")
            admins = cursor.fetchall()
    return render_template('administrateur/list.html', admins=admins)

@app.route('/admins/add', methods=['GET', 'POST'])
@admin_required
def add_admin():
    if request.method == 'POST':
        with get_db() as conn:
            with conn.cursor() as cursor:
                email = request.form['email']
                hashed_pw = generate_password_hash(request.form['mot_de_passe'])
                
                # 1. Insert into users table first
                cursor.execute(
                    "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'admin')",
                    (email, hashed_pw)
                )
                new_user_id = cursor.lastrowid
                
                # 2. Insert into administrateur with user_id link
                sql = "INSERT INTO administrateur (nom, email, mot_de_passe, user_id) VALUES (%s, %s, %s, %s)"
                cursor.execute(sql, (request.form['nom'], email, hashed_pw, new_user_id))
            conn.commit()
            flash(TRANSLATIONS[session.get('lang', 'ar')]['success_add'], 'success')
        return redirect(url_for('list_admins'))
    return render_template('administrateur/form.html', action='add')


@app.route('/admins/edit/<int:id>', methods=['GET', 'POST'])
@admin_required
def edit_admin(id):
    conn = get_db_connection()
    try:
        if request.method == 'POST':
            with conn.cursor() as cursor:
                email = request.form['email']
                hashed_pw = generate_password_hash(request.form['mot_de_passe'])
                
                sql = "UPDATE administrateur SET nom=%s, email=%s, mot_de_passe=%s WHERE id_admin=%s"
                cursor.execute(sql, (request.form['nom'], email, hashed_pw, id))
                
                # Sync to unified users table
                cursor.execute("SELECT user_id FROM administrateur WHERE id_admin=%s", (id,))
                admin_row = cursor.fetchone()
                if admin_row and admin_row['user_id']:
                    cursor.execute(
                        "UPDATE users SET email=%s, password_hash=%s WHERE id=%s",
                        (email, hashed_pw, admin_row['user_id'])
                    )
            conn.commit()
            flash(TRANSLATIONS[session.get('lang', 'ar')]['success_edit'], 'success')
            return redirect(url_for('list_admins'))
        else:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM administrateur WHERE id_admin=%s", (id,))
                admin = cursor.fetchone()
            if not admin:
                return "Admin not found", 404
            return render_template('administrateur/form.html', action='edit', admin=admin)
    finally:
        conn.close()

@app.route('/admins/delete/<int:id>')
@admin_required
def delete_admin(id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Fetch user_id before deleting to clean up users table
            cursor.execute("SELECT user_id FROM administrateur WHERE id_admin=%s", (id,))
            admin_row = cursor.fetchone()
            
            cursor.execute("DELETE FROM administrateur WHERE id_admin=%s", (id,))
            
            # Clean up unified users table
            if admin_row and admin_row.get('user_id'):
                cursor.execute("DELETE FROM users WHERE id=%s", (admin_row['user_id'],))
        conn.commit()
        flash(TRANSLATIONS[session.get('lang', 'ar')]['success_delete'], 'success')
    finally:
        conn.close()
    return redirect(url_for('list_admins'))

@app.route('/admin/action/<action>/<int:id>', methods=['GET', 'POST'])
def admin_ong_action(action, id):
    # This Action now requires implicit authentication via POST params if not logged in options
    # Or purely POST as per the prompt logic "needs email and password of admin"
    
    if request.method == 'POST':
        # 1. Check if already logged in as Admin
        if session.get('user_type') == 'admin':
            pass # Proceed to action
            
        else:
            # 2. Verify Creds from Form (for external/modal access)
            email = request.form.get('email')
            password = request.form.get('password')
            
            conn = get_db_connection()
            try:
                with conn.cursor() as cursor:
                     cursor.execute("SELECT * FROM administrateur WHERE email=%s", (email,))
                     admin = cursor.fetchone()
                     
                     if not admin or not check_and_migrate_password(conn, 'administrateur', 'id_admin', admin['id_admin'], password, admin['mot_de_passe']):
                          flash("Identifiants administrateur incorrects.", "danger")
                          return redirect(url_for('list_ngos'))
            finally:
                conn.close()

        # Execute Action
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if action == 'validate':
                    new_status = 'validé'
                    cursor.execute("UPDATE ong SET statut_de_validation=%s WHERE id_ong=%s", (new_status, id))
                    conn.commit()
                    flash(f"Statut de l'ONG mis à jour: {new_status}", 'success')
                
                elif action == 'reject':
                    # Logique de suppression (Hard Delete)
                    # 1. Nettoyer les fichiers et enregistrements dépendants
                    cursor.execute("SELECT id_cas_social FROM cas_social WHERE id_ong=%s", (id,))
                    cases = cursor.fetchall()
                    
                    for case in cases:
                        case_id = case['id_cas_social']
                        
                        # A. Supprimer fichiers et enregistrements MEDIA
                        cursor.execute("SELECT file_url FROM media WHERE id_cas_social=%s", (case_id,))
                        media_files = cursor.fetchall()
                        for media in media_files:
                            if media['file_url']:
                                file_path = os.path.join('static', media['file_url'])
                                if os.path.exists(file_path):
                                    try: os.remove(file_path)
                                    except: pass
                        cursor.execute("DELETE FROM media WHERE id_cas_social=%s", (case_id,))

                        # B. Supprimer enregistrements BENEFICIER
                        cursor.execute("DELETE FROM beneficier WHERE id_cas_social=%s", (case_id,))

                        # C. Supprimer le CAS SOCIAL
                        cursor.execute("DELETE FROM cas_social WHERE id_cas_social=%s", (case_id,))

                    # 2. Nettoyer les fichiers de l'ONG elle-même (Logo, Doc Verif)
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

                    # 3. Supprimer l'ONG (Maintenant que les enfants sont supprimés)
                    cursor.execute("DELETE FROM ong WHERE id_ong=%s", (id,))
                    conn.commit()
                    flash("ONG rejetée et supprimée avec succès.", 'success')
                
                else:
                    return redirect(url_for('list_ngos'))

        finally:
            conn.close()
        return redirect(url_for('list_ngos'))
         
    # Fallback / Error
    flash("Action requires POST with credentials.", "warning")
    return redirect(url_for('list_ngos'))


# 2. ONG
@app.route('/ngos')
def list_ngos():
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM ong")
            ngos = cursor.fetchall()
            
            # Fetch categories for filter
            cursor.execute("SELECT nomCategorie FROM categorie ORDER BY nomCategorie")
            categories = [c['nomCategorie'] for c in cursor.fetchall()]

    return render_template('ong/list.html', ngos=ngos, filter_categories=categories)

@app.route('/api/stats/ongs')
def api_ong_stats():
    category = request.args.get('category')
    status = request.args.get('status')
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            query = "SELECT * FROM ong WHERE 1=1"
            params = []
            
            if category:
                query += " AND domaine_intervation LIKE %s"
                params.append(f"%{category}%")
            if status:
                query += " AND statut_de_validation = %s"
                params.append(status)
                
            cursor.execute(query, params)
            results = cursor.fetchall()
            
            total = len(results)
            valid = sum(1 for r in results if r['statut_de_validation'] == 'validé')
            pending = sum(1 for r in results if r['statut_de_validation'] == 'enattente')
            rejected = sum(1 for r in results if r['statut_de_validation'] == 'rejetée')
            
            by_category = {}
            for r in results:
                domains = [d.strip() for d in r['domaine_intervation'].split(',')]
                for d in domains:
                    if d:
                        by_category[d] = by_category.get(d, 0) + 1
            
            lang_code = session.get('lang', 'ar')
            t = TRANSLATIONS[lang_code]

            stats = {
                'total': total,
                'valid': valid,
                'pending': pending,
                'rejected': rejected,
                'by_category': [{'label': t.get(k, k), 'value': v} for k, v in by_category.items()],
                'by_status': [
                    {'label': t['validé'], 'value': valid},
                    {'label': t['enattente'], 'value': pending},
                    {'label': t['rejetée'], 'value': rejected}
                ]
            }
            return jsonify(stats)

@app.route('/api/ngos/register', methods=['POST'])
def api_register_ong():
    try:
        # Validate Logo Presence
        if 'logo' not in request.files or request.files['logo'].filename == '':
            return jsonify({'success': False, 'message': 'Logo is mandatory'}), 400
            
        with get_db() as conn:
            with conn.cursor() as cursor:
                # Handle multiple domain selections
                domains = request.form.get('domaine_intervation', '') # Expecting comma separated string from mobile
                
                email = request.form['email']
                password = request.form['mot_de_passe']
                
                # Check if email exists
                cursor.execute("SELECT id FROM users WHERE email=%s", (email,))
                if cursor.fetchone():
                    return jsonify({'success': False, 'message': 'Email already exists'}), 400
                
                hashed_password = generate_password_hash(password)
                
                # 1. Insert into users table first
                cursor.execute(
                    "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'ong')",
                    (email, hashed_password)
                )
                new_user_id = cursor.lastrowid
                
                # 2. Insert into ong table with user_id link
                sql = """
                    INSERT INTO ong (nom_ong, adresse, telephone, email, domaine_intervation, mot_de_passe, statut_de_validation, user_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """
                cursor.execute(sql, (
                    request.form['nom_ong'],
                    request.form['adresse'],
                    request.form['telephone'],
                    email,
                    domains,
                    hashed_password,  # Keep for legacy/fallback
                    'enattente',
                    new_user_id
                ))
                ong_id = cursor.lastrowid
                
                # Handle Logo Upload
                if 'logo' in request.files:
                    file = request.files['logo']
                    if file and file.filename != '':
                        filename = secure_filename(file.filename)
                        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                        unique_filename = f"logo_{timestamp}_{filename}"
                        file_path = os.path.join(app.config['LOGO_FOLDER'], unique_filename)
                        file.save(file_path)
                        
                        web_path = f"uploads/logos/{unique_filename}"
                        cursor.execute("UPDATE ong SET logo_url=%s WHERE id_ong=%s", (web_path, ong_id))

                # Handle Verification Doc Upload
                if 'verification_doc' in request.files:
                    file = request.files['verification_doc']
                    if file and file.filename != '':
                        filename = secure_filename(file.filename)
                        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                        unique_filename = f"doc_{timestamp}_{filename}"
                        file_path = os.path.join(app.config['DOCS_FOLDER'], unique_filename)
                        file.save(file_path)
                        
                        web_path = f"uploads/docs/{unique_filename}"
                        cursor.execute("UPDATE ong SET verification_doc_url=%s WHERE id_ong=%s", (web_path, ong_id))

            conn.commit()
            
            return jsonify({'success': True, 'message': 'Account created successfully', 'ong_id': ong_id})
            
    except Exception as e:
         print(f"Error registering ONG: {e}")
         return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/ngos/add', methods=['GET', 'POST'])
def add_ong():
    if request.method == 'POST':
        # Validate Logo Presence
        if 'logo' not in request.files or request.files['logo'].filename == '':
            flash('Logo is mandatory for new ONGs.', 'danger')
            return redirect(request.url)
            
        try:
            with get_db() as conn:
                with conn.cursor() as cursor:
                    # Handle multiple domain selections
                    domains = request.form.getlist('domaine_intervation')
                    domains_str = ','.join(domains) if domains else ''
                    
                    email = request.form['email']
                    hashed_password = generate_password_hash(request.form['mot_de_passe'])
                    
                    # 1. Insert into users table first
                    cursor.execute(
                        "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'ong')",
                        (email, hashed_password)
                    )
                    new_user_id = cursor.lastrowid
                    
                    # 2. Insert into ong table with user_id link
                    sql = """
                        INSERT INTO ong (nom_ong, adresse, telephone, email, domaine_intervation, mot_de_passe, statut_de_validation, user_id)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """
                    cursor.execute(sql, (
                        request.form['nom_ong'],
                        request.form['adresse'],
                        request.form['telephone'],
                        email,
                        domains_str,
                        hashed_password,  # Keep for legacy/fallback
                        'enattente',
                        new_user_id
                    ))
                    ong_id = cursor.lastrowid
                    
                    # Handle Logo Upload
                    if 'logo' in request.files:
                        file = request.files['logo']
                        if file and file.filename != '':
                            filename = secure_filename(file.filename)
                            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                            unique_filename = f"logo_{timestamp}_{filename}"
                            file_path = os.path.join(app.config['LOGO_FOLDER'], unique_filename)
                            file.save(file_path)
                            
                            web_path = f"uploads/logos/{unique_filename}"
                            cursor.execute("UPDATE ong SET logo_url=%s WHERE id_ong=%s", (web_path, ong_id))

                    # Handle Verification Doc Upload
                    if 'verification_doc' in request.files:
                        file = request.files['verification_doc']
                        if file and file.filename != '':
                            filename = secure_filename(file.filename)
                            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                            unique_filename = f"doc_{timestamp}_{filename}"
                            file_path = os.path.join(app.config['DOCS_FOLDER'], unique_filename)
                            file.save(file_path)
                            
                            web_path = f"uploads/docs/{unique_filename}"
                            cursor.execute("UPDATE ong SET verification_doc_url=%s WHERE id_ong=%s", (web_path, ong_id))

                conn.commit()
                
                flash('Compte créé avec succès! Votre compte est en attente de validation par un administrateur.', 'info')
                return redirect(url_for('ong_login'))
        except Exception as e:
             # Basic error handling for duplicate email or other insertion errors
             flash(f"Error adding NGO: {e}", 'danger')
             return redirect(request.url)

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM categorie")
            categories = cursor.fetchall()
        return render_template('ong/form.html', action='add', categories=categories)


@app.route('/ngos/edit/<int:id>', methods=['GET', 'POST'])
def edit_ong(id):
    # Check authorization (must be logged in as that ONG, Admin, or have temporarily verified password)
    authorized = False
    if session.get('user_type') == 'admin':
        authorized = True
    elif session.get('user_type') == 'ong' and session.get('user_id') == id:
        authorized = True
    elif session.get('authorized_ong_id') == id:
        authorized = True
        
    if not authorized:
        flash("Veuillez entrer le mot de passe de l'ONG pour modifier.", "warning")
        return redirect(url_for('list_ngos'))

    with get_db() as conn:
        try:
            if request.method == 'POST':
                with conn.cursor() as cursor:
                    # Handle multiple domain selections
                    domains = request.form.getlist('domaine_intervation')
                    domains_str = ','.join(domains) if domains else ''
                    
                    # Hash the password before storing
                    hashed_pw = generate_password_hash(request.form['mot_de_passe'])
                    
                    sql = """
                        UPDATE ong SET nom_ong=%s, adresse=%s, telephone=%s, email=%s, domaine_intervation=%s, mot_de_passe=%s
                        WHERE id_ong=%s
                    """
                    cursor.execute(sql, (
                        request.form['nom_ong'],
                        request.form['adresse'],
                        request.form['telephone'],
                        request.form['email'],
                        domains_str,
                        hashed_pw,
                        id
                    ))
                    
                    # Sync password and email to unified users table
                    cursor.execute("SELECT user_id FROM ong WHERE id_ong=%s", (id,))
                    ong_row = cursor.fetchone()
                    if ong_row and ong_row.get('user_id'):
                        cursor.execute(
                            "UPDATE users SET email=%s, password_hash=%s WHERE id=%s",
                            (request.form['email'], hashed_pw, ong_row['user_id'])
                        )
                
                    # Handle Logo Upload Update
                    if 'logo' in request.files:
                        file = request.files['logo']
                        if file and file.filename != '':
                            filename = secure_filename(file.filename)
                            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                            unique_filename = f"logo_{timestamp}_{filename}"
                            file_path = os.path.join(app.config['LOGO_FOLDER'], unique_filename)
                            file.save(file_path)
                            
                            web_path = f"uploads/logos/{unique_filename}"
                            cursor.execute("UPDATE ong SET logo_url=%s WHERE id_ong=%s", (web_path, id))

                    # Handle Verification Doc Upload (Edit)
                    if 'verification_doc' in request.files:
                        file = request.files['verification_doc']
                        if file and file.filename != '':
                            filename = secure_filename(file.filename)
                            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                            unique_filename = f"doc_{timestamp}_{filename}"
                            file_path = os.path.join(app.config['DOCS_FOLDER'], unique_filename)
                            file.save(file_path)
                            
                            web_path = f"uploads/docs/{unique_filename}"
                            cursor.execute("UPDATE ong SET verification_doc_url=%s WHERE id_ong=%s", (web_path, id))

                conn.commit()
                flash(TRANSLATIONS[session.get('lang', 'ar')]['success_edit'], 'success')
                return redirect(url_for('list_ngos'))
            else:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (id,))
                    ong = cursor.fetchone()
                    
                    # Fetch categories for the dropdown
                    cursor.execute("SELECT * FROM categorie")
                    categories = cursor.fetchall()
                    
                if not ong:
                    return "NGO not found", 404
                return render_template('ong/form.html', action='edit', ong=ong, categories=categories)
        except Exception as e:
            flash(f"Error: {e}", "danger")
            return redirect(url_for('list_ngos'))

# --- EMAIL HELPER ---

def send_reset_email(to_email, new_password):
    """
    Sends a password reset email via SMTP (HTML format).
    """
    subject = "Renouvellement de mot de passe / إعادة تعيين كلمة المرور - ONG Connect"
    
    # HTML Body with French and Arabic
    html_body = f"""
    <html>
    <body>
        <div style="font-family: Arial, sans-serif; direction: ltr;">
            <p>Bonjour,</p>
            <p>Votre mot de passe a été réinitialisé par un administrateur.</p>
            <p>Voici votre nouveau mot de passe temporaire : <b style="font-size: 16px;">{new_password}</b></p>
            <p>Veuillez vous connecter et changer ce mot de passe dès que possible.</p>
            <p>Cordialement,<br>Équipe ONG Connect</p>
        </div>
        <hr>
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; direction: rtl; text-align: right;">
            <p>مرحباً،</p>
            <p>تم إعادة تعيين كلمة المرور الخاصة بك بنجاح.</p>
            <p>كلمة المرور المؤقتة الجديدة هي: <b style="font-size: 16px;">{new_password}</b></p>
            <p>يرجى تسجيل الدخول وتغيير كلمة المرور في أقرب وقت ممكن.</p>
            <p>مع تحيات،<br>فريق ONG Connect</p>
        </div>
    </body>
    </html>
    """
    
    # Real SMTP Implementation
    try:
        smtp_server = app.config['MAIL_SERVER']
        smtp_port = app.config['MAIL_PORT']
        sender_email = app.config['MAIL_USERNAME']
        password = app.config['MAIL_PASSWORD']
        
        # Guard clause for placeholder password
        if password == 'YOUR_APP_PASSWORD_HERE' or not password:
            print("❌ Error: Email password not configured in config.py")
            return False

        msg = MIMEText(html_body, 'html', 'utf-8')
        msg['Subject'] = subject
        msg['From'] = sender_email
        msg['To'] = to_email

        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, password)
            server.send_message(msg)
            
        print(f"✅ Email sent successfully to {to_email}")
        return True
    except Exception as e:
        print(f"❌ Email Error: {e}")
        return False

@app.route('/admin/ong/<int:id>/reset-password', methods=['POST'])
@admin_required
def admin_reset_password(id):
    # Check handled by decorator
        
    # Generate random password (8-digit number)
    new_password = ''.join([str(random.randint(0, 9)) for _ in range(8)])
    hashed_password = generate_password_hash(new_password)
    
    with get_db() as conn:
        with conn.cursor() as cursor:
            # Get ONG details
            cursor.execute("SELECT nom_ong, email, user_id FROM ong WHERE id_ong=%s", (id,))
            ong = cursor.fetchone()
            
            if not ong:
                flash("ONG introuvable.", "danger")
                return redirect(url_for('list_ngos'))
                
            # 1. Update Legacy Table
            cursor.execute("UPDATE ong SET mot_de_passe=%s, must_change_password=1 WHERE id_ong=%s", (hashed_password, id))
            
            # 2. Update Unified Users Table
            if ong['user_id']:
                cursor.execute(
                    "UPDATE users SET password_hash=%s, must_change_password=1 WHERE id=%s", 
                    (hashed_password, ong['user_id'])
                )
                
            conn.commit()
        
    # Send Email
    send_reset_email(ong['email'], new_password)
    
    flash(f"Mot de passe réinitialisé pour {ong['nom_ong']}. Le nouveau mot de passe a été envoyé par email.", "success")
    return redirect(url_for('list_ngos'))

@app.route('/ngos/delete/<int:id>', methods=['POST'])
def delete_ong(id):
    # Password verification required for delete
    password = request.form.get('password')
    
    # Allow admin to delete without password (or with admin functionality, but user asked for password flow)
    # The requirement: "put the password of the ong they want to modify"
    # We will enforce password check unless it's a logged-in Admin session doing a bypass (optional, but safer to require password)
    
    # If user is admin, allow
    is_admin = session.get('user_type') == 'admin'
    
    if not is_admin:
         if not password:
            flash("Mot de passe requis pour la suppression.", "danger")
            return redirect(url_for('list_ngos'))
            
         conn = get_db_connection()
         try:
             with conn.cursor() as cursor:
                 cursor.execute("SELECT id_ong, mot_de_passe FROM ong WHERE id_ong=%s", (id,))
                 ong = cursor.fetchone()
                 
                 if not ong or not check_and_migrate_password(conn, 'ong', 'id_ong', ong['id_ong'], password, ong['mot_de_passe']):
                     flash("Mot de passe incorrect.", "danger")
                     return redirect(url_for('list_ngos'))
         finally:
             conn.close()

    with get_db() as conn:
        with conn.cursor() as cursor:
            # 1. Fetch all cases for this ONG to clean up their media files
            cursor.execute("SELECT id_cas_social FROM cas_social WHERE id_ong=%s", (id,))
            cases = cursor.fetchall()
            
            for case in cases:
                case_id = case['id_cas_social']
                # Fetch media for each case
                cursor.execute("SELECT file_url FROM media WHERE id_cas_social=%s", (case_id,))
                media_files = cursor.fetchall()
                for media in media_files:
                    if media['file_url']:
                        file_path = os.path.join(app.config['UPLOAD_FOLDER'], os.path.basename(media['file_url']))
                        # Since file_url might be "uploads/media/...", basename ensures we target the right file in UPLOAD_FOLDER
                        # Or safer:
                        full_path = os.path.join('static', media['file_url'])
                        if os.path.exists(full_path):
                            try:
                                os.remove(full_path)
                            except Exception as e:
                                print(f"Error deleting file {full_path}: {e}")

            # 2. Fetch user_id before deleting ONG to clean up users table
            cursor.execute("SELECT user_id FROM ong WHERE id_ong=%s", (id,))
            ong_row = cursor.fetchone()
            
            # 3. Delete ONG (Cascade will remove cases and media DB records, but we cleaned files first)
            cursor.execute("DELETE FROM ong WHERE id_ong=%s", (id,))
            
            # 4. Clean up unified users table
            if ong_row and ong_row.get('user_id'):
                cursor.execute("DELETE FROM users WHERE id=%s", (ong_row['user_id'],))
            conn.commit()
            
    flash(TRANSLATIONS[session.get('lang', 'ar')]['success_delete'], 'success')
    return redirect(url_for('list_ngos'))

@app.route('/ngos/details/<int:id>')
def detail_ong(id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Fetch ONG details
            cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (id,))
            ong = cursor.fetchone()
            
            if not ong:
                return "NGO not found", 404
                
            # Fetch associated social cases with their first image (Only Approved)
            cursor.execute("""
                SELECT c.*, 
                       (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) as first_image
                FROM cas_social c
                WHERE c.id_ong=%s AND c.statut_approbation = 'approuvé'
            """, (id,))
            cases = cursor.fetchall()
            
    finally:
        conn.close()
    return render_template('ong/details.html', ong=ong, cases=cases)

# 3. Cas Social
@app.route('/cases')
def list_cases():
    # Security: If ONG is logged in, show only their cases
    # If Admin is logged in, show all cases
    user_type = session.get('user_type')
    user_id = session.get('user_id')
    
    if user_type == 'admin':
        query = "SELECT c.*, o.nom_ong FROM cas_social c LEFT JOIN ong o ON c.id_ong = o.id_ong"
        params = ()
    elif user_type == 'ong':
        query = "SELECT c.*, o.nom_ong FROM cas_social c LEFT JOIN ong o ON c.id_ong = o.id_ong WHERE c.id_ong = %s"
        params = (user_id,)
    else:
        # For security, redirect unauthorized users to the public view
        flash("Veuillez vous connecter pour accéder à cette page.", "warning")
        return redirect(url_for('public_dashboard'))

    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute(query, params)
            cases = cursor.fetchall()
            
    return render_template('cas_social/list.html', cases=cases)

@app.route('/cases/add', methods=['GET', 'POST'])
def add_case():
    with get_db() as conn:
        try:
            if request.method == 'POST':
                
                # Determine ID ONG based on user type
                if session.get('user_type') == 'ong':
                    id_ong = session.get('user_id')
                else:
                    # Admin or other: must select from dropdown
                    id_ong = request.form['id_ong']
                    
                with conn.cursor() as cursor:
                    sql = """
                        INSERT INTO cas_social (titre, description, adresse, wilaya, moughataa, date_publication, statut, id_ong, category_id)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """
                    # Handle date_publication: if missing or empty, use today
                    date_pub = request.form.get('date_publication')
                    if not date_pub:
                        date_pub = datetime.now().strftime('%Y-%m-%d')

                    cursor.execute(sql, (
                        request.form['titre'],
                        request.form['description'],
                        request.form['adresse'],
                        request.form['wilaya'],
                        request.form['moughataa'],
                        date_pub,
                        request.form['statut'],
                        id_ong,
                        request.form['category_id']
                    ))
                    case_id = cursor.lastrowid

                    # Handle Media Uploads
                    if 'media' in request.files:
                        files = request.files.getlist('media')
                        for file in files:
                            if file and file.filename != '':
                                filename = secure_filename(file.filename)
                                # Create unique filename to prevent overwrites
                                timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                                unique_filename = f"{timestamp}_{filename}"
                                file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
                                file.save(file_path)

                                # Save to media table
                                # URL path relative to static folder
                                web_path = f"uploads/media/{unique_filename}"
                                media_sql = "INSERT INTO media (id_cas_social, file_url, description_media) VALUES (%s, %s, %s)"
                                cursor.execute(media_sql, (case_id, web_path, "Media for case " + str(case_id)))
                conn.commit()
                
                # Get the ONG ID to redirect to their profile
                # ong_id variable is effectively id_ong
                flash(TRANSLATIONS[session.get('lang', 'ar')]['awaiting_admin_approval'], 'info')
                return redirect(url_for('detail_ong', id=id_ong))
            else:
                with conn.cursor() as cursor:
                    # Filter ONGs: If logged in as ONG, only show themselves (or nothing if we hide the dropdown)
                    # If Admin, show all.
                    if session.get('user_type') == 'ong':
                        # We still pass current user as 'ngos' list just in case, but template will hide it
                        cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (session.get('user_id'),))
                    else:
                        cursor.execute("SELECT * FROM ong ORDER BY nom_ong")
                    ngos = cursor.fetchall()
                    
                    # Fetch Categories
                    cursor.execute("SELECT * FROM categorie ORDER BY nomCategorie")
                    categories = cursor.fetchall()
                    
                return render_template('cas_social/form.html', action='add', ngos=ngos, categories=categories)
        except Exception as e:
            conn.rollback()
            flash(f"Error adding Case: {e}", 'danger')
            return redirect(url_for('list_cases'))

@app.route('/cases/edit/<int:id>', methods=['GET', 'POST'])
def edit_case(id):
    # Fetch case to check ownership
    conn = get_db_connection() 
    # Use separate connection for preliminary check to avoid nesting issues or just simple query
    try:
        with conn.cursor() as cursor:
             cursor.execute("SELECT id_ong FROM cas_social WHERE id_cas_social=%s", (id,))
             result = cursor.fetchone()
             if not result:
                 return "Case not found", 404
             case_ong_id = result['id_ong']
    finally:
        conn.close()

    # Authorization Check
    authorized = False
    if session.get('user_type') == 'admin':
        authorized = True
    elif session.get('user_type') == 'ong' and session.get('user_id') == case_ong_id:
        authorized = True
    elif session.get('authorized_ong_id') == case_ong_id:
        authorized = True
        
    if not authorized:
        flash("Veuillez entrer le mot de passe de l'ONG associée pour modifier.", "warning")
        # Redirect based on where they likely came from, or default to public dashboard
        return redirect(request.referrer or url_for('public_dashboard'))

    with get_db() as conn:
        try:
            if request.method == 'POST':
                with conn.cursor() as cursor:
                    
                    # Determine ID ONG logic for edit
                    if session.get('user_type') == 'ong':
                         # If ONG, they can't change the owner, so keep existing or use session
                         # We already fetched 'case_ong_id' at the start of the function which is the current owner
                         # But wait, 'case_ong_id' variable is from a separate connection block at the top.
                         # We should reuse it or fetch strictly.
                         # Better: Just use current case_ong_id (which verified ownership) 
                         # OR effectively session['user_id'] since they must match for authorization
                         id_ong = session.get('user_id')
                    else:
                         # Admin might change it OR if field is not present (not sent in form), keep original? 
                         # But form has it for admin.
                         id_ong = request.form['id_ong']

                    sql = """
                        UPDATE cas_social SET titre=%s, description=%s, adresse=%s, wilaya=%s, moughataa=%s, date_publication=%s, statut=%s, id_ong=%s, category_id=%s
                        WHERE id_cas_social=%s
                    """
                    
                    cursor.execute(sql, (
                        request.form['titre'],
                        request.form['description'],
                        request.form['adresse'],
                        request.form['wilaya'],
                        request.form['moughataa'],
                        request.form['date_publication'],
                        request.form['statut'],
                        id_ong,
                        request.form['category_id'],
                        id
                    ))

                    # Handle New Media Uploads
                    if 'media' in request.files:
                        files = request.files.getlist('media')
                        for file in files:
                            if file and file.filename != '':
                                filename = secure_filename(file.filename)
                                timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                                unique_filename = f"{timestamp}_{filename}"
                                file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
                                file.save(file_path)

                                web_path = f"uploads/media/{unique_filename}"
                                media_sql = "INSERT INTO media (id_cas_social, file_url, description_media) VALUES (%s, %s, %s)"
                                cursor.execute(media_sql, (id, web_path, "Media for case " + str(id)))

                conn.commit()
                flash(TRANSLATIONS[session.get('lang', 'ar')]['success_edit'], 'success')
                return redirect(url_for('list_cases'))
            else:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT * FROM cas_social WHERE id_cas_social=%s", (id,))
                    case = cursor.fetchone()
                    
                    # Filter ONGs: If logged in as ONG, only show themselves
                    if session.get('user_type') == 'ong':
                        cursor.execute("SELECT * FROM ong WHERE id_ong=%s", (session.get('user_id'),))
                    else:
                        cursor.execute("SELECT * FROM ong ORDER BY nom_ong")
                        
                    ngos = cursor.fetchall()
                    # Fetch existing media
                    cursor.execute("SELECT * FROM media WHERE id_cas_social=%s", (id,))
                    media_list = cursor.fetchall()
                    
                    # Fetch Categories
                    cursor.execute("SELECT * FROM categorie ORDER BY nomCategorie")
                    categories = cursor.fetchall()
                    
                if not case:
                    return "Case not found", 404
                return render_template('cas_social/form.html', action='edit', case=case, ngos=ngos, media_list=media_list, categories=categories)
        except Exception as e:
            conn.rollback()
            flash(f"Error editing case: {e}", 'danger')
            return redirect(url_for('list_cases'))

@app.route('/cases/update-status/<int:id>', methods=['POST'])
def update_case_status(id):
    """Quick status update endpoint for AJAX calls"""
    # Auth check: must be admin or owning ONG
    user_type = session.get('user_type')
    if user_type not in ('admin', 'ong'):
        return {'success': False, 'message': 'Unauthorized'}, 403
    
    try:
        data = request.get_json()
        new_status = data.get('status')
        
        if new_status not in ['En cours', 'Résolu', 'Urgent']:
            return {'success': False, 'message': 'Invalid status'}, 400
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                # If ONG, verify ownership
                if user_type == 'ong':
                    cursor.execute("SELECT id_ong FROM cas_social WHERE id_cas_social=%s", (id,))
                    case = cursor.fetchone()
                    if not case or case['id_ong'] != session.get('user_id'):
                        return {'success': False, 'message': 'Unauthorized'}, 403
                
                cursor.execute(
                    "UPDATE cas_social SET statut=%s WHERE id_cas_social=%s",
                    (new_status, id)
                )
            conn.commit()
        
        return {'success': True, 'message': 'Status updated successfully'}
    except Exception as e:
        return {'success': False, 'message': str(e)}, 500


@app.route('/cases/delete/<int:id>', methods=['POST'])
def delete_case(id):
    password = request.form.get('password')
    
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Check Case and ONG
            cursor.execute("SELECT id_ong FROM cas_social WHERE id_cas_social=%s", (id,))
            case_data = cursor.fetchone()
            if not case_data:
                flash("Cas introuvable.", "danger")
                return redirect(url_for('public_dashboard'))
                
            ong_id = case_data['id_ong']
            
            # Verify Password (unless Admin)
            is_admin = session.get('user_type') == 'admin'
            if not is_admin:
                if not password:
                    flash("Mot de passe requis.", "danger")
                    return redirect(request.referrer or url_for('public_dashboard'))
                    
                cursor.execute("SELECT id_ong, mot_de_passe FROM ong WHERE id_ong=%s", (ong_id,))
                ong = cursor.fetchone()
                
                if not ong or not check_and_migrate_password(conn, 'ong', 'id_ong', ong['id_ong'], password, ong['mot_de_passe']):
                    flash("Mot de passe incorrect.", "danger")
                    return redirect(request.referrer or url_for('public_dashboard'))

            # 1. Fetch associated media to delete physical files
            cursor.execute("SELECT * FROM media WHERE id_cas_social=%s", (id,))
            media_files = cursor.fetchall()
            
            for media in media_files:
                # Assuming file_url is stored relative to static/ e.g. "uploads/media/..."
                # And we need to remove it from the system
                if media['file_url']:
                    file_path = os.path.join('static', media['file_url'])
                    if os.path.exists(file_path):
                        try:
                            os.remove(file_path)
                        except Exception as e:
                            print(f"could not delete file {file_path}: {e}")

            # 2. Delete the media records from DB
            cursor.execute("DELETE FROM media WHERE id_cas_social=%s", (id,))
            
            # 3. Now safe to delete the case
            cursor.execute("DELETE FROM cas_social WHERE id_cas_social=%s", (id,))
        conn.commit()
        flash(TRANSLATIONS[session.get('lang', 'ar')]['success_delete'], 'success')
    except Exception as e:
        conn.rollback()
        flash(f"Error deleting case: {e}", 'danger')
    finally:
        conn.close()
    
    # Return to the implementation reference (Edit Case page is gone, so go to dashboard or list)
    return redirect(url_for('public_dashboard'))



@app.route('/media/delete/<int:id>', methods=['POST'])
def delete_media(id):
    # Auth check: must be admin or owning ONG
    user_type = session.get('user_type')
    if user_type not in ('admin', 'ong'):
        flash("Accès refusé.", "danger")
        return redirect(url_for('list_cases'))
    
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # 1. Get media info to find file path and correct redirect
            cursor.execute("SELECT * FROM media WHERE id_media=%s", (id,))
            media = cursor.fetchone()
            
            if not media:
                flash("Media not found", "danger")
                return redirect(url_for('list_cases'))
                
            case_id = media['id_cas_social']
            
            # 2. Delete Physical File
            if media['file_url']:
                file_path = os.path.join('static', media['file_url'])
                if os.path.exists(file_path):
                    try:
                        os.remove(file_path)
                    except Exception as e:
                        print(f"Could not delete file {file_path}: {e}")
            
            # 3. Delete DB Record
            cursor.execute("DELETE FROM media WHERE id_media=%s", (id,))
            
        conn.commit()
        flash(TRANSLATIONS[session.get('lang', 'ar')]['success_delete'], 'success')
        return redirect(url_for('edit_case', id=case_id))
    finally:
        conn.close()

# 4. Beneficier
@app.route('/beneficiaries')
def list_beneficiaries():
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT b.*, c.titre as cas_titre FROM beneficier b LEFT JOIN cas_social c ON b.id_cas_social = c.id_cas_social")
            beneficiaries = cursor.fetchall()
            
            # Fetch ONGs for filter
            cursor.execute("SELECT id_ong, nom_ong FROM ong ORDER BY nom_ong")
            ongs = cursor.fetchall()
            
            # Fetch Categories
            cursor.execute("SELECT nomCategorie FROM categorie ORDER BY nomCategorie")
            categories = [c['nomCategorie'] for c in cursor.fetchall()]
            
            # Fetch Locations
            cursor.execute("SELECT DISTINCT adresse FROM beneficier WHERE adresse IS NOT NULL AND adresse != ''")
            locations = [l['adresse'] for l in cursor.fetchall()]

            # Fetch Total Count (Explicit + Implicit)
            # Fetch Total Count (Strict: Only Resolved Cases)
            # 1. Explicit beneficiaries of Resolved cases
            # 2. Resolved cases with NO beneficiaries (Implicit = 1)
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
            total_count = cursor.fetchone()['count']

    return render_template('beneficier/list.html', 
                         beneficiaries=beneficiaries,
                         filter_ongs=ongs,
                         filter_categories=categories,
                         filter_locations=locations,
                         total_beneficiaries=total_count)

@app.route('/beneficiaries/add', methods=['GET', 'POST'])
def add_beneficiary():
    with get_db() as conn:
        try:
            if request.method == 'POST':
                with conn.cursor() as cursor:
                    sql = """
                        INSERT INTO beneficier (nom, prenom, adresse, description_situation, id_cas_social)
                        VALUES (%s, %s, %s, %s, %s)
                    """
                    cursor.execute(sql, (
                        request.form['nom'],
                        request.form['prenom'],
                        request.form['adresse'],
                        request.form['description_situation'],
                        request.form['id_cas_social']
                    ))
                conn.commit()
                flash(TRANSLATIONS[session.get('lang', 'ar')]['success_add'], 'success')
                return redirect(url_for('list_beneficiaries'))
            else:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT * FROM cas_social")
                    cases = cursor.fetchall()
                return render_template('beneficier/form.html', action='add', cases=cases)
        except Exception as e:
            flash(f"Error: {e}", "danger")
            return redirect(url_for('list_beneficiaries'))

@app.route('/beneficiaries/edit/<int:id>', methods=['GET', 'POST'])
def edit_beneficiary(id):
    conn = get_db_connection()
    try:
        if request.method == 'POST':
            with conn.cursor() as cursor:
                sql = """
                    UPDATE beneficier SET nom=%s, prenom=%s, adresse=%s, description_situation=%s, id_cas_social=%s
                    WHERE id_beneficiaire=%s
                """
                cursor.execute(sql, (
                    request.form['nom'],
                    request.form['prenom'],
                    request.form['adresse'],
                    request.form['description_situation'],
                    request.form['id_cas_social'],
                    id
                ))
            conn.commit()
            flash(TRANSLATIONS[session.get('lang', 'ar')]['success_edit'], 'success')
            return redirect(url_for('list_beneficiaries'))
        else:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM beneficier WHERE id_beneficiaire=%s", (id,))
                beneficiary = cursor.fetchone()
                cursor.execute("SELECT * FROM cas_social")
                cases = cursor.fetchall()
            if not beneficiary:
                return "Beneficiary not found", 404
            return render_template('beneficier/form.html', action='edit', beneficiary=beneficiary, cases=cases)
    finally:
        conn.close()

@app.route('/beneficiaries/delete/<int:id>')
def delete_beneficiary(id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM beneficier WHERE id_beneficiaire=%s", (id,))
        conn.commit()
        flash(TRANSLATIONS[session.get('lang', 'ar')]['success_delete'], 'success')
    finally:
        conn.close()
    return redirect(url_for('list_beneficiaries'))

# 5. Categorie
@app.route('/categories')
def list_categories():
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM categorie")
            categories = cursor.fetchall()
    return render_template('categorie/list.html', categories=categories)


@app.route('/categories/add', methods=['GET', 'POST'])
@admin_required
def add_category():
    if request.method == 'POST':
        with get_db() as conn:
            with conn.cursor() as cursor:
                sql = "INSERT INTO categorie (nomCategorie, description) VALUES (%s, %s)"
                cursor.execute(sql, (request.form['nomCategorie'], request.form['description']))
            conn.commit()
            flash(TRANSLATIONS[session.get('lang', 'ar')]['success_add'], 'success')
        return redirect(url_for('list_categories'))
    return render_template('categorie/form.html', action='add')


@app.route('/categories/edit/<int:id>', methods=['GET', 'POST'])
@admin_required
def edit_category(id):
    with get_db() as conn:
        try:
            if request.method == 'POST':
                with conn.cursor() as cursor:
                    sql = "UPDATE categorie SET nomCategorie=%s, description=%s WHERE idCategorie=%s"
                    cursor.execute(sql, (request.form['nomCategorie'], request.form['description'], id))
                conn.commit()
                flash(TRANSLATIONS[session.get('lang', 'ar')]['success_edit'], 'success')
                return redirect(url_for('list_categories'))
            else:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT * FROM categorie WHERE idCategorie=%s", (id,))
                    category = cursor.fetchone()
                if not category:
                    return "Category not found", 404
                return render_template('categorie/form.html', action='edit', category=category)
        except Exception as e:
            flash(f"Error: {e}", "danger")
            return redirect(url_for('list_categories'))


@app.route('/categories/delete/<int:id>')
@admin_required
def delete_category(id):
    with get_db() as conn:
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM categorie WHERE idCategorie=%s", (id,))
        conn.commit()
        flash(TRANSLATIONS[session.get('lang', 'ar')]['success_delete'], 'success')
    return redirect(url_for('list_categories'))

@app.route('/api/social-cases', methods=['GET'])
def get_social_cases_json():
    try:
        # Use simple dictionary cursor
        connection = pymysql.connect(
            host=app.config.get('DB_HOST', 'localhost'),
            user=app.config.get('DB_USER', 'root'),
            password=app.config.get('DB_PASSWORD', ''),
            database=app.config.get('DB_NAME', 'ong_connecte'),
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with connection:
            with connection.cursor() as cursor:
                # Optimized Query:
                # 1. Joins 'cas_social' with 'ong' to get telephone/email
                # 2. Uses 'media' subquery to get the first image
                # 3. Uses 'Santé' as default category
                sql = """
                SELECT 
                    c.id_cas_social, 
                    c.titre, 
                    c.description, 
                    COALESCE(cat.nomCategorie, 'Autre') AS categorie, 
                    c.date_publication,
                    o.nom_ong,
                    o.telephone,
                    o.email,
                    (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) AS image
                FROM cas_social c
                LEFT JOIN ong o ON c.id_ong = o.id_ong
                LEFT JOIN categorie cat ON c.category_id = cat.idCategorie
                WHERE c.statut_approbation = 'approuvé'
                ORDER BY c.date_publication DESC
                """
                cursor.execute(sql)
                cases = cursor.fetchall()
                
                # Format data for JSON
                for case in cases:
                    # Fix Date format
                    if case.get('date_publication'):
                        case['date_publication'] = case['date_publication'].isoformat()
                    
                    # Fix Image URL to be full path
                    if case.get('image'):
                        case['image'] = f"{request.host_url}{case['image']}"

                return jsonify(cases)
                
    except Exception as e:
        print(f"API Error: {e}")
        return jsonify({'error': str(e)}), 500



# ============================================
# MOBILE API ENDPOINTS
# ============================================
# --- PUBLIC API ENDPOINTS ---

@app.route('/api/cases_legacy', methods=['GET'])
def api_list_cases():
    """List all approved social cases with optional filters"""
    try:
        category = request.args.get('category')
        ong_id = request.args.get('ong_id')
        status = request.args.get('status')
        search = request.args.get('search')
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                query = """
                    SELECT c.id_cas_social, c.titre, c.description, c.adresse, 
                           c.statut, c.date_publication, c.latitude, c.longitude,
                           o.id_ong, o.nom_ong, o.logo_url, o.telephone, o.email,
                           cat.nomCategorie as category,
                           (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) as image
                    FROM cas_social c
                    LEFT JOIN ong o ON c.id_ong = o.id_ong
                    LEFT JOIN categorie cat ON c.category_id = cat.idCategorie
                    WHERE c.statut_approbation = 'approuvé'
                """
                params = []
                
                if category:
                    query += " AND cat.nomCategorie = %s"
                    params.append(category)
                if ong_id:
                    query += " AND c.id_ong = %s"
                    params.append(ong_id)
                if status:
                    query += " AND c.statut = %s"
                    params.append(status)
                if search:
                    query += " AND (c.titre LIKE %s OR c.description LIKE %s)"
                    params.append(f"%{search}%")
                    params.append(f"%{search}%")
                
                query += " ORDER BY c.date_publication DESC"
                cursor.execute(query, params)
                cases = cursor.fetchall()
                
                # Format for JSON
                for case in cases:
                    if case.get('date_publication'):
                        case['date_publication'] = case['date_publication'].isoformat()
                    if case.get('image'):
                        case['image'] = f"{request.host_url.rstrip('/')}/static/{case['image']}"
                    if case.get('logo_url'):
                        case['logo_url'] = f"{request.host_url.rstrip('/')}/static/{case['logo_url']}"
                
                return jsonify({'success': True, 'cases': cases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/cases_legacy/<int:id>', methods=['GET'])
def api_case_details(id):
    """Get single case details with media"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT c.*, o.id_ong, o.nom_ong, o.logo_url, o.telephone, o.email, o.adresse as ong_adresse
                    FROM cas_social c
                    LEFT JOIN ong o ON c.id_ong = o.id_ong
                    WHERE c.id_cas_social = %s AND c.statut_approbation = 'approuvé'
                """, (id,))
                case = cursor.fetchone()
                
                if not case:
                    return jsonify({'success': False, 'error': 'Case not found'}), 404
                
                # Get media
                cursor.execute("SELECT * FROM media WHERE id_cas_social = %s", (id,))
                media = cursor.fetchall()
                
                # Format
                if case.get('date_publication'):
                    case['date_publication'] = case['date_publication'].isoformat()
                for m in media:
                    if m.get('file_url'):
                        m['file_url'] = f"{request.host_url.rstrip('/')}/static/{m['file_url']}"
                if case.get('logo_url'):
                    case['logo_url'] = f"{request.host_url.rstrip('/')}/static/{case['logo_url']}"
                
                return jsonify({'success': True, 'case': case, 'media': media})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ongs', methods=['GET'])
def api_list_ongs():
    """List all validated ONGs"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id_ong, nom_ong, email, telephone, adresse, 
                           domaine_intervation, logo_url, description
                    FROM ong 
                    WHERE statut_de_validation = 'validé'
                    ORDER BY nom_ong
                """)
                ongs = cursor.fetchall()
                
                for ong in ongs:
                    if ong.get('logo_url'):
                        ong['logo_url'] = f"{request.host_url.rstrip('/')}/static/{ong['logo_url']}"
                
                return jsonify({'success': True, 'ongs': ongs})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ongs/<int:id>', methods=['GET'])
def api_ong_details(id):
    """Get ONG details with their cases"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id_ong, nom_ong, email, telephone, adresse, 
                           domaine_intervation, logo_url, description
                    FROM ong WHERE id_ong = %s AND statut_de_validation = 'validé'
                """, (id,))
                ong = cursor.fetchone()
                
                if not ong:
                    return jsonify({'success': False, 'error': 'ONG not found'}), 404
                
                # Get ONG's approved cases
                cursor.execute("""
                    SELECT c.id_cas_social, c.titre, c.statut, c.date_publication,
                           (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social LIMIT 1) as image
                    FROM cas_social c
                    WHERE c.id_ong = %s AND c.statut_approbation = 'approuvé'
                    ORDER BY c.date_publication DESC
                """, (id,))
                cases = cursor.fetchall()
                
                if ong.get('logo_url'):
                    ong['logo_url'] = f"{request.host_url.rstrip('/')}/static/{ong['logo_url']}"
                for case in cases:
                    if case.get('date_publication'):
                        case['date_publication'] = case['date_publication'].isoformat()
                    if case.get('image'):
                        case['image'] = f"{request.host_url.rstrip('/')}/static/{case['image']}"
                
                return jsonify({'success': True, 'ong': ong, 'cases': cases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/categories', methods=['GET'])
def api_list_categories():
    """List all categories for filters"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM categorie ORDER BY nomCategorie")
                categories = cursor.fetchall()
                return jsonify({'success': True, 'categories': categories})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# --- AUTHENTICATION API ---

@app.route('/api/auth/login', methods=['POST'])
def api_auth_login():
    """ONG Login - returns JWT token"""
    try:
        data = request.get_json()
        print(f"DEBUG: Login attempt for data: {data}")
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            print("DEBUG: Missing email or password")
            return jsonify({'success': False, 'error': 'Email and password required'}), 400
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                # Check users table first
                print(f"DEBUG: Checking users table for {email}")
                cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
                user = cursor.fetchone()
                print(f"DEBUG: Found user in users table: {user}")
                
                # --- MIGRATION LOGIC START ---
                if not user:
                    print("DEBUG: User not in users table. Checking legacy 'ong' table...")
                    # Check if they exist in legacy ONG table but not in users table
                    cursor.execute("SELECT * FROM ong WHERE email = %s", (email,))
                    legacy_ong = cursor.fetchone()
                    print(f"DEBUG: Found legacy ong: {legacy_ong}")
                    
                    if legacy_ong:
                        # Validate legacy password (assume plain text or match what's in DB)
                        db_password = legacy_ong['mot_de_passe']
                        password_valid = False
                        
                        if db_password == password:
                             # Plain text match
                             print("DEBUG: Legacy password matched (plain text)")
                             password_valid = True
                        elif db_password.startswith('scrypt:') or db_password.startswith('pbkdf2:'):
                             print("DEBUG: Legacy password matched (hashed)")
                             password_valid = check_password_hash(db_password, password)
                        else:
                             print(f"DEBUG: Legacy password mismatch. DB: {db_password} vs Input: {password}")
                        
                        if password_valid:
                            print("DEBUG: Migrating legacy user to 'users' table...")
                            # Migrate to users table
                            new_hash = generate_password_hash(password)
                            cursor.execute(
                                "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'ong')",
                                (email, new_hash)
                            )
                            new_user_id = cursor.lastrowid
                            print(f"DEBUG: Created new user with ID: {new_user_id}")
                            
                            # Update ONG record
                            cursor.execute("UPDATE ong SET user_id = %s, mot_de_passe = %s WHERE id_ong = %s", 
                                           (new_user_id, new_hash, legacy_ong['id_ong']))
                            conn.commit()
                            print("DEBUG: Linked ONG to new user")
                            
                            # Refetch user to proceed
                            cursor.execute("SELECT * FROM users WHERE id = %s", (new_user_id,))
                            user = cursor.fetchone()
                            
                    if not user:
                        # Also check legacy admin table for migration
                        print("DEBUG: Checking legacy 'administrateur' table...")
                        cursor.execute("SELECT * FROM administrateur WHERE email = %s", (email,))
                        legacy_admin = cursor.fetchone()
                        if legacy_admin:
                             # verify password
                             db_password = legacy_admin['mot_de_passe']
                             if db_password == password or (db_password.startswith(('scrypt:', 'pbkdf2:')) and check_password_hash(db_password, password)):
                                 print("DEBUG: Migrating legacy admin to 'users' table...")
                                 new_hash = generate_password_hash(password)
                                 cursor.execute(
                                     "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'admin')",
                                     (email, new_hash)
                                 )
                                 new_user_id = cursor.lastrowid
                                 cursor.execute("UPDATE administrateur SET user_id = %s, mot_de_passe = %s WHERE id_admin = %s", 
                                                (new_user_id, new_hash, legacy_admin['id_admin']))
                                 conn.commit()
                                 cursor.execute("SELECT * FROM users WHERE id = %s", (new_user_id,))
                                 user = cursor.fetchone()
                # --- MIGRATION LOGIC END ---

                if not user:
                    print("DEBUG: User not found after migration check.")
                    return jsonify({'success': False, 'error': 'Invalid credentials'}), 401
                
                # Verify password (if not just migrated)
                db_password = user['password_hash']
                password_valid = False
                
                if db_password.startswith('scrypt:') or db_password.startswith('pbkdf2:'):
                    password_valid = check_password_hash(db_password, password)
                elif db_password == password:
                    # Upgrade plain-text password in users table if needed
                    print("DEBUG: Upgrading plain text password in users table")
                    new_hash = generate_password_hash(password)
                    cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user['id']))
                    conn.commit()
                    password_valid = True
                
                if not password_valid:
                    print("DEBUG: Password invalid for user in users table")
                    return jsonify({'success': False, 'error': 'Invalid credentials'}), 401
                
                # Handle roles
                if user['role'] == 'admin':
                    # Get Admin details
                    cursor.execute("SELECT * FROM administrateur WHERE user_id = %s", (user['id'],))
                    admin = cursor.fetchone()
                    
                    token = jwt.encode({
                        'user_id': user['id'],
                        'role': 'admin',
                        'exp': datetime.utcnow() + timedelta(days=30)
                    }, JWT_SECRET, algorithm='HS256')
                    
                    return jsonify({
                        'success': True,
                        'token': token,
                        'role': 'admin',
                        'user': {
                            'id': user['id'],
                            'email': user['email'],
                            'nom': admin['nom'] if admin else 'Admin'
                        }
                    })
                
                # Regular ONG flow
                cursor.execute("SELECT * FROM ong WHERE user_id = %s", (user['id'],))
                ong = cursor.fetchone()
                print(f"DEBUG: Fetched ONG details: {ong}")
                
                # Double check mapping if user exists but ong doesn't
                if not ong:
                     print("DEBUG: User exists but not linked to ONG. Checking by email...")
                     cursor.execute("SELECT * FROM ong WHERE email = %s", (email,))
                     ong = cursor.fetchone()
                     if ong:
                         print(f"DEBUG: Found unlinked ONG by email. Linking now to user_id {user['id']}")
                         cursor.execute("UPDATE ong SET user_id = %s WHERE id_ong = %s", (user['id'], ong['id_ong']))
                         conn.commit()

                if not ong:
                    print("DEBUG: ONG profile still not found.")
                    return jsonify({'success': False, 'error': 'ONG profile not found'}), 404
                
                if ong['statut_de_validation'] != 'validé':
                    print(f"DEBUG: Account validation status: {ong['statut_de_validation']}")
                    return jsonify({'success': False, 'error': 'Account pending validation'}), 403
                
                # Generate JWT token
                token = jwt.encode({
                    'ong_id': ong['id_ong'],
                    'user_id': user['id'],
                    'role': 'ong',
                    'exp': datetime.utcnow() + timedelta(days=30)
                }, JWT_SECRET, algorithm='HS256')
                
                return jsonify({
                    'success': True,
                    'token': token,
                    'role': 'ong',
                    'ong': {
                        'id': ong['id_ong'],
                        'nom_ong': ong['nom_ong'],
                        'email': ong['email'],
                        'logo_url': f"{request.host_url.rstrip('/')}/static/{ong['logo_url']}" if ong.get('logo_url') else None
                    }
                })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/auth/register', methods=['POST'])
def api_auth_register():
    """ONG Registration"""
    try:
        data = request.get_json()
        nom_ong = data.get('nom_ong')
        email = data.get('email')
        password = data.get('password')
        telephone = data.get('telephone', '')
        adresse = data.get('adresse', '')
        domaine = data.get('domaine', 'Autre')
        
        if not nom_ong or not email or not password:
            return jsonify({'success': False, 'error': 'Name, email and password required'}), 400
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                # Check if email exists
                cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
                if cursor.fetchone():
                    return jsonify({'success': False, 'error': 'Email already registered'}), 400
                
                # Create user
                hashed_password = generate_password_hash(password)
                cursor.execute(
                    "INSERT INTO users (email, password_hash, role) VALUES (%s, %s, 'ong')",
                    (email, hashed_password)
                )
                user_id = cursor.lastrowid
                
                # Create ONG profile
                cursor.execute("""
                    INSERT INTO ong (nom_ong, email, mot_de_passe, telephone, adresse, 
                                     domaine_intervation, statut_de_validation, user_id)
                    VALUES (%s, %s, %s, %s, %s, %s, 'enattente', %s)
                """, (nom_ong, email, hashed_password, telephone, adresse, domaine, user_id))
                
                conn.commit()
                
                return jsonify({
                    'success': True,
                    'message': 'Registration successful. Please wait for admin approval.'
                })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# --- ONG AUTHENTICATED API ---

@app.route('/api/ong/profile', methods=['GET'])
@token_required
def api_ong_profile(current_ong_id):
    """Get current ONG's profile"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT * FROM ong WHERE id_ong = %s", (current_ong_id,))
                ong = cursor.fetchone()
                
                if ong.get('logo_url'):
                    ong['logo_url'] = f"{request.host_url.rstrip('/')}/static/{ong['logo_url']}"
                
                # Stats
                cursor.execute("SELECT COUNT(*) as total FROM cas_social WHERE id_ong = %s", (current_ong_id,))
                total = cursor.fetchone()['total']
                cursor.execute("SELECT COUNT(*) as urgent FROM cas_social WHERE id_ong = %s AND statut = 'Urgent'", (current_ong_id,))
                urgent = cursor.fetchone()['urgent']
                cursor.execute("SELECT COUNT(*) as resolved FROM cas_social WHERE id_ong = %s AND statut = 'Résolu'", (current_ong_id,))
                resolved = cursor.fetchone()['resolved']
                
                return jsonify({
                    'success': True,
                    'ong': ong,
                    'stats': {'total': total, 'urgent': urgent, 'resolved': resolved}
                })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ong/cases', methods=['GET'])
@token_required
def api_ong_get_cases(current_ong_id):
    """List current ONG's cases"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT c.*, 
                           (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social ORDER BY id_media DESC LIMIT 1) as image
                    FROM cas_social c
                    WHERE c.id_ong = %s
                    ORDER BY c.date_publication DESC
                """, (current_ong_id,))
                cases = cursor.fetchall()
                
                for case in cases:
                    if case.get('date_publication'):
                        case['date_publication'] = case['date_publication'].isoformat()
                    if case.get('image'):
                        case['image'] = f"{request.host_url.rstrip('/')}/static/{case['image']}"
                
                return jsonify({'success': True, 'cases': cases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ong/cases', methods=['POST'])
@token_required
def api_ong_create_case(current_ong_id):
    """Create new social case"""
    try:
        data = request.get_json()
        titre = data.get('titre')
        description = data.get('description')
        adresse = data.get('adresse', '')
        statut = data.get('statut', 'En cours')
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        
        category_id = data.get('category_id')

        if not titre or not description or not category_id:
            return jsonify({'success': False, 'error': 'Title, description and category required'}), 400
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO cas_social (titre, description, adresse, statut, id_ong, 
                                            date_publication, statut_approbation, latitude, longitude, category_id)
                    VALUES (%s, %s, %s, %s, %s, NOW(), 'en_attente', %s, %s, %s)
                """, (titre, description, adresse, statut, current_ong_id, latitude, longitude, category_id))
                case_id = cursor.lastrowid
                conn.commit()
                
                return jsonify({
                    'success': True,
                    'case_id': case_id,
                    'message': 'Case created. Awaiting admin approval.'
                })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ong/cases/<int:id>', methods=['PUT'])
@token_required
def api_ong_update_case(current_ong_id, id):
    """Update existing case"""
    try:
        data = request.get_json()
        
        with get_db() as conn:
            with conn.cursor() as cursor:
                # Verify ownership
                cursor.execute("SELECT id_ong FROM cas_social WHERE id_cas_social = %s", (id,))
                case = cursor.fetchone()
                
                if not case or case['id_ong'] != current_ong_id:
                    return jsonify({'success': False, 'error': 'Case not found'}), 404
                
                # Update fields
                updates = []
                params = []
                for field in ['titre', 'description', 'adresse', 'statut', 'latitude', 'longitude', 'category_id']:
                    if field in data:
                        updates.append(f"{field} = %s")
                        params.append(data[field])
                
                if updates:
                    params.append(id)
                    cursor.execute(f"UPDATE cas_social SET {', '.join(updates)} WHERE id_cas_social = %s", params)
                    conn.commit()
                
                return jsonify({'success': True, 'message': 'Case updated'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/ong/profile/update', methods=['POST'])
@token_required
def api_ong_update_profile(current_ong_id):
    """Update ONG profile details"""
    try:
        data = request.form
        nom_ong = data.get('nom_ong')
        telephone = data.get('telephone')
        email = data.get('email')
        adresse = data.get('adresse')
        domaine = data.get('domaine')
        description = data.get('description')
        
        # Handle logo upload
        logo_filename = None
        if 'logo' in request.files:
            file = request.files['logo']
            if file and file.filename != '':
                filename = secure_filename(file.filename)
                # Create uploads/logos directory if not exists
                logo_dir = os.path.join(app.root_path, 'static', 'uploads', 'logos')
                os.makedirs(logo_dir, exist_ok=True)
                
                # Save unique filename
                unique_filename = f"{uuid.uuid4()}_{filename}"
                file.save(os.path.join(logo_dir, unique_filename))
                logo_filename = f"uploads/logos/{unique_filename}"

        with get_db() as conn:
            with conn.cursor() as cursor:
                # Update query builder
                updates = []
                params = []
                
                if nom_ong:
                    updates.append("nom_ong = %s")
                    params.append(nom_ong)
                if telephone:
                    updates.append("telephone = %s")
                    params.append(telephone)
                if email:
                    updates.append("email = %s")
                    params.append(email)
                if adresse:
                    updates.append("adresse = %s")
                    params.append(adresse)
                if domaine:
                    updates.append("domaine_intervation = %s")
                    params.append(domaine)
                if description:
                    updates.append("description = %s")
                    params.append(description)
                if logo_filename:
                    updates.append("logo_url = %s")
                    params.append(logo_filename)
                
                if updates:
                    updates.append("update_at = NOW()")
                    params.append(current_ong_id)
                    
                    sql = f"UPDATE ong SET {', '.join(updates)} WHERE id_ong = %s"
                    cursor.execute(sql, params)
                    conn.commit()
                
                return jsonify({'success': True, 'message': 'Profile updated successfully'})

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500




# --- API Routes for Mobile App ---

@app.route('/api/cases', methods=['GET'])
def api_get_cases():
    try:
        # Get query parameters
        category = request.args.get('category')
        ong_id = request.args.get('ong_id')
        lat = request.args.get('lat', type=float)
        lon = request.args.get('lon', type=float)
        radius = request.args.get('radius', type=float, default=10.0) # km

        with get_db() as conn:
            with conn.cursor() as cursor:
                # Base query
                query = """
                    SELECT c.id_cas_social, c.titre, c.description, c.adresse, c.date_publication, 
                           c.statut, c.latitude, c.longitude, c.wilaya, c.moughataa,
                           o.id_ong, o.nom_ong, o.telephone as ong_phone, o.email as ong_email, o.logo_url,
                           COALESCE(cat.nomCategorie, 'Autre') as categorie_nom,
                           (SELECT file_url FROM media WHERE id_cas_social = c.id_cas_social ORDER BY id_media DESC LIMIT 1) as main_image
                    FROM cas_social c
                    LEFT JOIN ong o ON c.id_ong = o.id_ong
                    LEFT JOIN categorie cat ON c.category_id = cat.idCategorie
                    WHERE c.statut_approbation = 'approuvé'
                """
                params = []

                # Filters
                if ong_id:
                    query += " AND c.id_ong = %s"
                    params.append(ong_id)
                
                if category:
                   query += " AND cat.nomCategorie = %s"
                   params.append(category)

                query += " ORDER BY c.date_publication DESC"
                
                cursor.execute(query, params)
                cases = cursor.fetchall()
                
                # Format for JSON
                results = []
                for case in cases:
                    results.append({
                        'id': case['id_cas_social'],
                        'title': case['titre'],
                        'description': case['description'],
                        'address': case['adresse'],
                        'date': case['date_publication'].strftime('%Y-%m-%d') if case['date_publication'] else None,
                        'status': case['statut'],
                        'location': {
                            'lat': float(case['latitude']) if case['latitude'] else None,
                            'lng': float(case['longitude']) if case['longitude'] else None,
                            'wilaya': case['wilaya'],
                            'moughataa': case['moughataa']
                        },
                        'ong': {
                            'id': case['id_ong'],
                            'name': case['nom_ong'],
                            'logo': f"{request.host_url.rstrip('/')}/static/{case['logo_url']}" if case.get('logo_url') else None,
                            'phone': case['ong_phone'],
                            'email': case['ong_email']
                        },
                        'category': case['categorie_nom'],
                        'image': f"{request.host_url.rstrip('/')}/static/{case['main_image']}" if case.get('main_image') else None,
                    })

        json_response = json.dumps({'status': 'success', 'data': results}, ensure_ascii=False)
        return Response(json_response, content_type='application/json; charset=utf-8')
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/cases/<int:id>', methods=['GET'])
def api_get_case_detail(id):
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                # Case details
                query = """
                    SELECT c.*, 
                           o.nom_ong, o.adresse as ong_address, o.telephone as ong_phone, o.email as ong_email, o.logo_url,
                           cat.nomCategorie as category_name
                    FROM cas_social c
                    LEFT JOIN ong o ON c.id_ong = o.id_ong
                    LEFT JOIN categorie cat ON c.category_id = cat.idCategorie
                    WHERE c.id_cas_social = %s
                """
                cursor.execute(query, (id,))
                case = cursor.fetchone()
                
                if not case:
                    return jsonify({'status': 'error', 'message': 'Case not found'}), 404

                # Media
                cursor.execute("SELECT file_url, description_media FROM media WHERE id_cas_social = %s ORDER BY id_media DESC", (id,))
                media = cursor.fetchall()

                result = {
                    'id': case['id_cas_social'],
                    'title': case['titre'],
                    'description': case['description'],
                    'address': case['adresse'],
                    'date': case['date_publication'].strftime('%Y-%m-%d') if case['date_publication'] else None,
                    'status': case['statut'],
                    'approval_status': case['statut_approbation'],
                    'location': {
                        'lat': float(case['latitude']) if case['latitude'] else None,
                        'lng': float(case['longitude']) if case['longitude'] else None,
                        'wilaya': case['wilaya'],
                        'moughataa': case['moughataa']
                    },
                    'ong': {
                        'id': case['id_ong'],
                        'name': case['nom_ong'],
                        'address': case['ong_address'],
                        'phone': case['ong_phone'],
                        'email': case['ong_email'],
                        'logo': f"{request.host_url.rstrip('/')}/static/{case['logo_url']}" if case.get('logo_url') else None
                    },
                    'category': case['category_name'],
                    'image': f"{request.host_url.rstrip('/')}/static/{media[0]['file_url']}" if media and media[0].get('file_url') else None,
                    'images': [f"{request.host_url.rstrip('/')}/static/{m['file_url']}" for m in media if m.get('file_url')],
                }

        json_response = json.dumps({'status': 'success', 'data': result}, ensure_ascii=False)
        return Response(json_response, content_type='application/json; charset=utf-8')
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/cases/<int:id>', methods=['DELETE'])
@token_required
def api_delete_case(ong_id, id):
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                # specific to authenticated ONG
                cursor.execute("SELECT * FROM cas_social WHERE id_cas_social = %s AND id_ong = %s", (id, ong_id))
                case = cursor.fetchone()
                
                if not case:
                    return jsonify({'status': 'error', 'message': 'Case not found or unauthorized'}), 404
                
                # Delete media files from disk
                cursor.execute("SELECT file_url FROM media WHERE id_cas_social = %s", (id,))
                media_files = cursor.fetchall()
                for media in media_files:
                    try:
                        if media['file_url']:
                            # file_url is "uploads/media/filename.jpg", stored in static/uploads/media
                            # joining 'static' with 'uploads/media/filename.jpg'
                            file_path = os.path.join('static', media['file_url'])
                            if os.path.exists(file_path):
                                os.remove(file_path)
                    except Exception as e:
                        print(f"Error deleting file {media['file_url']}: {e}")

                # Delete from DB
                cursor.execute("DELETE FROM media WHERE id_cas_social = %s", (id,))
                cursor.execute("DELETE FROM cas_social WHERE id_cas_social = %s", (id,))
            conn.commit()
            
            return jsonify({'status': 'success', 'message': 'Case deleted successfully'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/statistics', methods=['GET'])
def api_get_statistics():
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                # 1. Overview Stats
                cursor.execute("""
                    SELECT 
                        COUNT(*) as total_cases,
                        SUM(CASE WHEN statut = 'Urgent' THEN 1 ELSE 0 END) as urgent_cases,
                        SUM(CASE WHEN statut = 'Résolu' THEN 1 ELSE 0 END) as resolved_cases
                    FROM cas_social
                    WHERE statut_approbation = 'approuvé'
                """)
                overview = cursor.fetchone()

                cursor.execute("SELECT COUNT(*) as count FROM ong WHERE statut_de_validation = 'validé'")
                total_ongs = cursor.fetchone()['count']

                # 2. Stats by Wilaya
                cursor.execute("""
                    SELECT wilaya, COUNT(*) as count 
                    FROM cas_social 
                    WHERE statut_approbation = 'approuvé'
                    GROUP BY wilaya
                    ORDER BY count DESC
                """)
                wilaya_stats = cursor.fetchall()

                # 3. Stats by Moughataa (Top 10)
                cursor.execute("""
                    SELECT moughataa, COUNT(*) as count 
                    FROM cas_social 
                    WHERE statut_approbation = 'approuvé'
                    GROUP BY moughataa
                    ORDER BY count DESC
                    LIMIT 10
                """)
                moughataa_stats = cursor.fetchall()

                # 4. Status Stats
                cursor.execute("""
                    SELECT statut, COUNT(*) as count 
                    FROM cas_social 
                    WHERE statut_approbation = 'approuvé'
                    GROUP BY statut
                """)
                status_stats = cursor.fetchall()

        # Convert Decimal to int for JSON serialization
        stats_data = {
            'total_cases': int(overview['total_cases'] or 0),
            'urgent_cases': int(overview.get('urgent_cases', 0) or 0),
            'resolved_cases': int(overview.get('resolved_cases', 0) or 0),
            'total_ongs': int(total_ongs or 0),
            'wilaya_stats': [{'wilaya': w['wilaya'], 'count': int(w['count'])} for w in wilaya_stats],
            'moughataa_stats': [{'moughataa': m['moughataa'], 'count': int(m['count'])} for m in moughataa_stats],
            'status_stats': [{'statut': s['statut'], 'count': int(s['count'])} for s in status_stats]
        }

        json_response = json.dumps({'status': 'success', 'data': stats_data}, ensure_ascii=False)
        return Response(json_response, content_type='application/json; charset=utf-8')
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500



@app.route('/api/notifications', methods=['GET'])
def api_get_notifications():
    """Fetch all notifications for mobile app"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT n.*, c.titre, c.description,
                           (SELECT file_url FROM media WHERE id_cas_social = n.id_cas_social LIMIT 1) as image
                    FROM notifications n
                    LEFT JOIN cas_social c ON n.id_cas_social = c.id_cas_social
                    ORDER BY n.date_notification DESC
                    LIMIT 50
                """)
                notifications = cursor.fetchall()
                
                for n in notifications:
                    if n.get('date_notification'):
                        n['date_notification'] = n['date_notification'].isoformat()
                    if n.get('image'):
                        n['image'] = f"{request.host_url.rstrip('/')}/static/{n['image']}"
                
                return jsonify({'success': True, 'data': notifications})
    except Exception as e:
        print(f"Error fetching notifications: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/cases/add', methods=['POST'])
@token_required
def api_add_case(ong_id):
    """Add new social case from mobile app (multipart/form-data)"""
    try:
        # Get data from form (multipart)
        titre = request.form.get('titre')
        description = request.form.get('description')
        adresse = request.form.get('adresse', '')
        wilaya = request.form.get('wilaya', '')
        moughataa = request.form.get('moughataa', '')
        statut = request.form.get('statut', 'En cours')
        latitude = request.form.get('latitude')
        longitude = request.form.get('longitude')
        category_id = request.form.get('category_id')

        if not titre or not description or not category_id:
            return jsonify({'success': False, 'error': 'Title, description and category required'}), 400

        date_pub = request.form.get('date_publication')
        if not date_pub:
            date_pub = datetime.now().strftime('%Y-%m-%d')

        with get_db() as conn:
            with conn.cursor() as cursor:
                # 1. Insert Case
                sql = """
                    INSERT INTO cas_social (titre, description, adresse, wilaya, moughataa, 
                                            date_publication, statut, id_ong, category_id, 
                                            statut_approbation, latitude, longitude)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'en_attente', %s, %s)
                """
                cursor.execute(sql, (titre, description, adresse, wilaya, moughataa, 
                                     date_pub, statut, ong_id, category_id, latitude, longitude))
                case_id = cursor.lastrowid

                # 2. Handle Media Uploads
                if 'media' in request.files:
                    files = request.files.getlist('media')
                    for file in files:
                        if file and file.filename != '':
                            filename = secure_filename(file.filename)
                            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                            unique_filename = f"{timestamp}_{filename}"
                            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
                            file.save(file_path)

                            # Save to media table - relative path for web
                            web_path = f"uploads/media/{unique_filename}"
                            cursor.execute("INSERT INTO media (id_cas_social, file_url) VALUES (%s, %s)", (case_id, web_path))
                
                conn.commit()
                
                return jsonify({
                    'success': True,
                    'case_id': case_id,
                    'message': 'Case created and awaiting approval'
                })
    except Exception as e:
        print(f"Error adding mobile case: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/cases/edit/<int:id>', methods=['POST'])
@token_required
def api_edit_case(current_ong_id, id):
    """Edit social case from mobile app (multipart/form-data)"""
    try:
        with get_db() as conn:
            with conn.cursor() as cursor:
                # Verify ownership
                cursor.execute("SELECT id_ong FROM cas_social WHERE id_cas_social = %s", (id,))
                case = cursor.fetchone()
                if not case or case['id_ong'] != current_ong_id:
                    return jsonify({'success': False, 'error': 'Unauthorized'}), 403

                # Update main fields
                data_fields = ['titre', 'description', 'adresse', 'wilaya', 'moughataa', 'statut', 'latitude', 'longitude', 'category_id']
                updates = []
                params = []
                
                for field in data_fields:
                    if field in request.form:
                        updates.append(f"{field} = %s")
                        params.append(request.form[field])
                
                if updates:
                    params.append(id)
                    cursor.execute(f"UPDATE cas_social SET {', '.join(updates)} WHERE id_cas_social = %s", params)

                # Handle Media
                if 'media' in request.files:
                    files = request.files.getlist('media')
                    for file in files:
                        if file and file.filename != '':
                            filename = secure_filename(file.filename)
                            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
                            unique_filename = f"{timestamp}_{filename}"
                            
                            # Use absolute path
                            upload_dir = os.path.join(app.root_path, 'static', 'uploads', 'media')
                            os.makedirs(upload_dir, exist_ok=True)
                            file_path = os.path.join(upload_dir, unique_filename)
                            
                            file.save(file_path)

                            web_path = f"uploads/media/{unique_filename}"
                            cursor.execute("INSERT INTO media (id_cas_social, file_url) VALUES (%s, %s)", (id, web_path))

                conn.commit()
                return jsonify({'success': True, 'message': 'Case updated successfully'})
    except Exception as e:
        print(f"Error editing mobile case: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == '__main__':
    init_db()
    # host='0.0.0.0' allows connections from external devices (your phone)
    # port=3000 to match the mobile app configuration
    app.run(host='0.0.0.0', port=3000, debug=True)
