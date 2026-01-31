
from app import get_db_connection

try:
    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT id_cas_social, titre, wilaya, moughataa FROM cas_social ORDER BY id_cas_social DESC LIMIT 1")
        case = cursor.fetchone()
        print(f"Latest Case: {case}")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
