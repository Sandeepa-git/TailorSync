from pydantic import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "TailorSync"
    DATABASE_URL: str = "postgresql://localhost/dev_db"
    SECRET_KEY: str = "temporary_development_secret_key"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 365
    REFRESH_TOKEN_EXPIRE_DAYS: int = 365
    ALLOWED_HOSTS: List[str] = ["*"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()