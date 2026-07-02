from sqlalchemy import create_engine, text
from app.core.config import settings

engine = create_engine(settings.DATABASE_URL, future=True)
with engine.connect() as conn:
    r = conn.execute(text("SELECT version();"))
    print(r.fetchone())