"""Master entry point for the Northwind capstone pipeline.

Steps (in order):
    1. Create database and the stg / dw schemas      (sql/01_*)
    2. Create staging tables                         (sql/02_*)
    3. Create warehouse tables + date dimension      (sql/03_*)
    4. Load raw CSV files 1:1 into stg               (src/stage_raw_data.py)
    5. Upsert dimensions, then the fact table        (src/transform_warehouse.py -> sql/04_*, 05_*)

Usage (from the repository root):
    python run_pipeline.py            # normal, idempotent run
    python run_pipeline.py --reset    # drop stg and dw first (clean rebuild)
"""
import argparse
import os
import sys

from sqlalchemy import text

# The modules in src/ use flat imports (`from config import ...`),
# so make src/ importable regardless of the current working directory.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "src"))

from db_connector import get_db_engine  # noqa: E402
from stage_raw_data import load_staging_data  # noqa: E402
from transform_warehouse import find_sql, run_sql_file, transform_warehouse  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Run the Northwind ETL pipeline.")
    parser.add_argument("--reset", action="store_true",
                        help="drop the stg and dw schemas before rebuilding")
    args = parser.parse_args()

    print("=== Northwind pipeline started ===")
    server = get_db_engine(database=None)   # database may not exist yet

    try:
        if args.reset:
            with server.begin() as conn:
                conn.execute(text("DROP DATABASE IF EXISTS stg"))
                conn.execute(text("DROP DATABASE IF EXISTS dw"))
            print("[OK] dropped stg and dw")

        for prefix in ("01", "02", "03"):
            run_sql_file(server, find_sql(prefix))

        engine = get_db_engine()
        load_staging_data(engine)
        transform_warehouse(engine)

        with engine.connect() as conn:
            for tbl in ("dim_customers", "dim_products", "dim_employees",
                        "dim_suppliers", "dim_date", "fact_orders"):
                n = conn.execute(text(f"SELECT COUNT(*) FROM dw.{tbl}")).scalar()
                print(f"    dw.{tbl}: {n} rows")
    except Exception as exc:
        print(f"[FAILED] Pipeline aborted: {exc}")
        sys.exit(1)
    finally:
        server.dispose()

    print("=== Northwind pipeline finished successfully ===")


if __name__ == "__main__":
    main()
