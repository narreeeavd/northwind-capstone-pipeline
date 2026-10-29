import os
from db_connector import get_db_connection

def run_sql_file(file_path):
    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()
            
        # Բաժանում ենք հարցումները իրարից (;) կետ-ստորակետով, եթե մի քանիսն են
        for result in cursor.execute(sql_script, multi=True):
            pass
            
        connection.commit()
        print(f"Successfully executed: {file_path}")
    except Exception as e:
        print(f"Error executing {file_path}: {e}")
        connection.rollback()
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    
    sql_dir = "../sql_scripts"
    run_sql_file(os.path.join(sql_dir, "04_upsert_dimensions.sql"))
    run_sql_file(os.path.join(sql_dir, "05_upsert_fact_sales.sql"))