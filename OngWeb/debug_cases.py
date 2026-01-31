
import pymysql
import os
from config import Config

def check_cases():
    try:
        conn = pymysql.connect(
            host=Config.DB_HOST,
            user=Config.DB_USER,
            password=Config.DB_PASSWORD,
            database=Config.DB_NAME,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with conn.cursor() as cursor:
            # Fetch cases with their media
            sql = """
                SELECT c.id_cas_social, c.titre, c.statut_approbation, m.file_url 
                FROM cas_social c 
                LEFT JOIN (
                    SELECT id_cas_social, MIN(file_url) as file_url 
                    FROM media 
                    GROUP BY id_cas_social
                ) m ON c.id_cas_social = m.id_cas_social
                WHERE c.statut_approbation = 'approuvé'
                ORDER BY c.date_publication DESC
            """
            cursor.execute(sql)
            cases = cursor.fetchall()
            
            print(f"Found {len(cases)} approved cases.")
            print("-" * 50)
            
            for case in cases:
                file_url = case['file_url']
                print(f"Case ID: {case['id_cas_social']}")
                print(f"Title: {case['titre']}")
                print(f"DB File URL: {file_url}")
                
                if file_url:
                    # Check if file exists in static folder
                    # Assuming file_url is relative to static/
                    # We need to construct the absolute path.
                    # Config.UPLOAD_FOLDER is likely absolute or relative to app root.
                    # But url_for('static', filename=...) looks in the static folder.
                    
                    # Heuristic: verify if it exists relative to 'static'
                    static_path = os.path.join(os.getcwd(), 'static', file_url)
                    exists = os.path.exists(static_path)
                    print(f"Checking path: {static_path}")
                    print(f"Exists: {exists}")
                    
                    if not exists:
                         # Try with 'uploads/' prefix if missing
                         alt_path = os.path.join(os.getcwd(), 'static', 'uploads', file_url)
                         print(f"Checking alt path: {alt_path}")
                         print(f"Exists: {os.path.exists(alt_path)}")

                else:
                    print("No image associated in DB.")
                print("-" * 50)
                
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_cases()
