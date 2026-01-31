import pymysql
from config import Config

def check():
    try:
        conn = pymysql.connect(
            host=Config.DB_HOST,
            user=Config.DB_USER,
            password=Config.DB_PASSWORD,
            charset='utf8mb4'
        )
        print("Connected to MySQL successfully.")
        
        with conn.cursor() as cursor:
            cursor.execute(f"SHOW DATABASES LIKE '{Config.DB_NAME}'")
            if not cursor.fetchone():
                print(f"Database {Config.DB_NAME} does NOT exist.")
                return
            
            print(f"Database {Config.DB_NAME} exists.")
            conn.select_db(Config.DB_NAME)
            
            tables = ['ong', 'cas_social', 'users', 'categorie']
            for table in tables:
                cursor.execute(f"SHOW TABLES LIKE '{table}'")
                if cursor.fetchone():
                    cursor.execute(f"SELECT COUNT(*) as count FROM {table}")
                    count = cursor.fetchone()[0]
                    print(f"Table '{table}' exists with {count} records.")
                    
                    if table == 'ong':
                        cursor.execute("SELECT COUNT(*) FROM ong WHERE statut_de_validation='validé'")
                        print(f"  - Validated ONGs: {cursor.fetchone()[0]}")
                    if table == 'cas_social':
                        cursor.execute("SELECT COUNT(*) FROM cas_social WHERE statut_approbation='approuvé'")
                        print(f"  - Approved Cases: {cursor.fetchone()[0]}")
                else:
                    print(f"Table '{table}' does NOT exist.")
                    
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check()
