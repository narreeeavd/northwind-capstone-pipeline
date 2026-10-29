# stage_raw_data.py
import os
import pandas as pd
from db_connector import get_db_engine
from config import RAW_DATA_DIR

# Ֆայլերի և stg աղյուսակների քարտեզ
tables_mapping = {
    "categories": "categories",
    "customers": "customers",
    "employees": "employees",
    "employee_territories": "employee_territories",
    "order_details": "order_details",
    "orders": "orders",
    "products": "products",
    "regions": "regions",
    "shippers": "shippers",
    "suppliers": "suppliers",
    "territories": "territories",
    "customer_customer_demo": "customer_customer_demo",
    "customer_demographics": "customer_demographics",
}

def load_staging_data():
    print("--- Starting Staging Data Load Pipeline ---")
    engine = get_db_engine()

    for file_name, table_name in tables_mapping.items():
        csv_path = os.path.join(RAW_DATA_DIR, f"{file_name}.csv")
        xlsx_path = os.path.join(RAW_DATA_DIR, f"{file_name}.xlsx")
        
        if os.path.exists(csv_path):
            file_path = csv_path
            is_excel = False
        elif os.path.exists(xlsx_path):
            file_path = xlsx_path
            is_excel = True
        else:
            print(f"[WARNING] File not found for {file_name} (.csv or .xlsx). Skipping...")
            continue

        try:
            if is_excel:
                df = pd.read_excel(file_path, dtype=str)
            else:
                df = pd.read_csv(file_path, dtype=str, encoding='utf-8', on_bad_lines='skip')

            df.to_sql(
                name=table_name,
                con=engine,
                schema="stg",
                if_exists="replace",
                index=False,
            )

            print(f"[SUCCESS] Loaded {len(df)} rows into stg.{table_name}")

        except Exception as e:
            print(f"[ERROR] Failed to load {file_name}: {e}")

    print("--- Staging Data Load Completed ---")

if __name__ == "__main__":
    load_staging_data()