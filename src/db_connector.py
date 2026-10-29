# db_connector.py
from sqlalchemy import create_engine
from config import DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME

def get_db_engine():
    connection_string = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    engine = create_engine(connection_string)
    return engine