import pymysql
from config import Config

def add_geolocation_columns():
    """Add latitude and longitude columns to support map functionality"""
    try:
        conn = pymysql.connect(
            host=Config.DB_HOST,
            user=Config.DB_USER,
            password=Config.DB_PASSWORD,
            database=Config.DB_NAME,
            charset='utf8mb4'
        )
        
        with conn.cursor() as cursor:
            print("Adding geolocation columns...")
            
            # Add columns to cas_social table
            try:
                cursor.execute("""
                    ALTER TABLE cas_social 
                    ADD COLUMN latitude DECIMAL(10, 8) NULL,
                    ADD COLUMN longitude DECIMAL(11, 8) NULL
                """)
                print("[OK] Added latitude/longitude to cas_social table")
            except pymysql.err.OperationalError as e:
                if "Duplicate column name" in str(e):
                    print("[INFO] Columns already exist in cas_social table")
                else:
                    raise
            
            # Add columns to beneficier table
            try:
                cursor.execute("""
                    ALTER TABLE beneficier 
                    ADD COLUMN latitude DECIMAL(10, 8) NULL,
                    ADD COLUMN longitude DECIMAL(11, 8) NULL
                """)
                print("[OK] Added latitude/longitude to beneficier table")
            except pymysql.err.OperationalError as e:
                if "Duplicate column name" in str(e):
                    print("[INFO] Columns already exist in beneficier table")
                else:
                    raise
            
            conn.commit()
            print("\n[SUCCESS] Database schema updated successfully!")
            
    except Exception as e:
        print(f"[ERROR] {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    add_geolocation_columns()

