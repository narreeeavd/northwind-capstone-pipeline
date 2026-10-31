"""Database engine factory."""
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

from config import DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME


def get_db_engine(database=DB_NAME):
    """Return a SQLAlchemy engine for MySQL.

    Pass database=None to connect to the server without a default database
    (needed before the database exists). URL.create() escapes special
    characters in the password (e.g. '?', '@', '#').
    """
    url = URL.create(
        drivername="mysql+pymysql",
        username=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=int(DB_PORT),
        database=database,
    )
    return create_engine(url)
