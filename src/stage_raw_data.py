"""Phase 1: load the raw Northwind CSV files 1:1 into the stg schema.

Tables are created by sql/02_create_staging.sql. Each run truncates a staging
table and reloads it, so the load is repeatable and never duplicates rows.
"""
import os

import pandas as pd
from sqlalchemy import text

from config import RAW_DATA_DIR
from db_connector import get_db_engine

# Core tables: the pipeline fails if any of these CSV files is missing.
REQUIRED_TABLES = [
    "categories", "customers", "employees", "employee_territories",
    "order_details", "orders", "products", "regions",
    "shippers", "suppliers", "territories",
]
# Optional tables of the 13-table schema: skipped when the CSV is absent.
OPTIONAL_TABLES = ["customer_customer_demo", "customer_demographics"]


def load_staging_data(engine=None):
    print("--- Staging load started ---")
    engine = engine or get_db_engine()

    for table in REQUIRED_TABLES + OPTIONAL_TABLES:
        path = os.path.join(RAW_DATA_DIR, f"{table}.csv")

        if not os.path.exists(path):
            if table in REQUIRED_TABLES:
                raise FileNotFoundError(f"Required raw file not found: {path}")
            print(f"[SKIP] {table}.csv not found (optional table)")
            continue

        # Everything is read as text (no type changes). The literal string
        # "NULL" used by the source export becomes a real SQL NULL.
        df = pd.read_csv(path, dtype=str, encoding="utf-8",
                         na_values=["NULL"], keep_default_na=False)

        with engine.begin() as conn:
            conn.execute(text(f"TRUNCATE TABLE stg.{table}"))

        df.to_sql(name=table, con=engine, schema="stg",
                  if_exists="append", index=False, chunksize=500)

        with engine.connect() as conn:
            loaded = conn.execute(text(f"SELECT COUNT(*) FROM stg.{table}")).scalar()
        if loaded != len(df):
            raise RuntimeError(f"stg.{table}: expected {len(df)} rows, found {loaded}")

        print(f"[OK] stg.{table}: {loaded} rows")

    print("--- Staging load finished ---")


if __name__ == "__main__":
    load_staging_data()
