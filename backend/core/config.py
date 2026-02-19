from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# config.py está en: Proyecto_final_orto/backend/core/config.py
# .parent       → core/
# .parent.parent       → backend/
# .parent.parent.parent → Proyecto_final_orto/  ← aquí está el .env
BASE_DIR = Path(__file__).resolve().parent.parent.parent
ENV_FILE = str(BASE_DIR / ".env")

class Settings(BaseSettings):
    MONGODB_URL: str
    PROJECT_NAME: str = "Proyecto Final 2DAM"
    DATABASE_NAME: str = "gym_db"

    model_config = SettingsConfigDict(env_file=ENV_FILE, extra="ignore")

settings = Settings()
