import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'super_secret_key_ong_connect_CHANGE_IN_PROD'
    
    # Database
    DB_HOST = os.environ.get('DB_HOST') or 'localhost'
    DB_USER = os.environ.get('DB_USER') or 'root'
    DB_PASSWORD = os.environ.get('DB_PASSWORD') or 'sidimedtop1'
    DB_NAME = os.environ.get('DB_NAME') or 'ong_connecte'
    
    # JSON Configuration - Ensure Arabic characters are NOT escaped
    JSON_AS_ASCII = False
    JSONIFY_MIMETYPE = 'application/json; charset=utf-8'
    
    # Paths
    UPLOAD_FOLDER = os.path.join('static', 'uploads', 'media')
    LOGO_FOLDER = os.path.join('static', 'uploads', 'logos')
    DOCS_FOLDER = os.path.join('static', 'uploads', 'docs')

    # Mail Settings (Mock by default)
    # Mail Settings
    MAIL_SERVER = os.environ.get('MAIL_SERVER') or 'smtp.gmail.com'
    MAIL_PORT = int(os.environ.get('MAIL_PORT') or 587)
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS') or True
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME') or 'ongconnecte@gmail.com'
    # SECURITY NOTE: Replace 'YOUR_APP_PASSWORD_HERE' with your actual generated App Password.
    # Do NOT use your main Google account password.
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD') or 'lzir xipo lhil ynae'
