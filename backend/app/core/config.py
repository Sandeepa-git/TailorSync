from pydantic import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "TailorSync"
    DATABASE_URL: str = "postgresql://neondb_owner:npg_wfOyHgE84sLm@ep-misty-surf-atv3lv7r.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"
    SECRET_KEY: str = "CHANGE_ME"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 365
    REFRESH_TOKEN_EXPIRE_DAYS: int = 365
    ALLOWED_HOSTS: list[str] = ["*"]

    class Config:
        env_file = ".env"

settings = Settings()