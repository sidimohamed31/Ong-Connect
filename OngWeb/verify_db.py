
from app import init_db, get_db_connection
import sys

print("Starting verification...")
try:
    # Trigger migration
    init_db()
    print("init_db executed.")
    
    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("DESCRIBE cas_social")
        rows = cursor.fetchall()
        columns = [row['Field'] for row in rows]
        print(f"Columns: {columns}")
        
        if 'wilaya' in columns and 'moughataa' in columns:
            print("SUCCESS: 'wilaya' and 'moughataa' columns exist.")
        else:
            print("FAILURE: Columns missing.")
            sys.exit(1)
    conn.close()
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
