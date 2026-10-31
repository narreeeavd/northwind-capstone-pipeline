"""Phase 2: run the SQL scripts that build and load the dw schema."""
import glob
import os
import re

from sqlalchemy import text

from config import SQL_DIR
from db_connector import get_db_engine


def split_statements(sql):
    """Split a SQL script into individual statements (comments removed)."""
    sql = re.sub(r"--[^\n]*", "", sql)
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.S)
    return [s.strip() for s in sql.split(";") if s.strip()]


def find_sql(prefix):
    """Find a script in sql/ by its numeric prefix, e.g. '04'."""
    matches = sorted(glob.glob(os.path.join(SQL_DIR, f"{prefix}_*.sql")))
    if not matches:
        raise FileNotFoundError(f"No SQL file starting with '{prefix}_' in {SQL_DIR}")
    return matches[0]


def run_sql_file(engine, path):
    with open(path, "r", encoding="utf-8") as f:
        statements = split_statements(f.read())
    with engine.begin() as conn:
        for stmt in statements:
            conn.execute(text(stmt))
    print(f"[OK] {os.path.basename(path)} ({len(statements)} statements)")


def transform_warehouse(engine=None):
    """Idempotent stg -> dw load: dimensions first, then the fact table."""
    engine = engine or get_db_engine()
    run_sql_file(engine, find_sql("04"))   # dimensions
    run_sql_file(engine, find_sql("05"))   # fact table


if __name__ == "__main__":
    transform_warehouse()
