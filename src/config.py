"""Connection settings. Credentials come from environment variables (never hard-code them).

Set them in your shell or in a local `.env` file (copy `.env.example`; `.env` is git-ignored).
"""
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

try:  # optional: load a local .env file if python-dotenv is installed
    from dotenv import load_dotenv
    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass

DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "Na1007016?")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "northwind_warehouse")

RAW_DATA_DIR = str(PROJECT_ROOT / "data" / "raw")
SQL_DIR = str(PROJECT_ROOT / "sql")
