from pydantic import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "TailorSync"
    DATABASE_URL: str = "postgresql://neondb_owner:npg_wfOyHgE84sLm@ep-misty-surf-atv3lv7r.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"
    SECRET_KEY: str = "e83a7f2fb4864c017eb26f95ad263901b0f519548f07b98d2a6a69d740c0b9a2"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 365
    REFRESH_TOKEN_EXPIRE_DAYS: int = 365
    ALLOWED_HOSTS: List[str] = ["*"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()