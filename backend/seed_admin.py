"""
Script para crear el usuario administrador por defecto en la base de datos.
Ejecutar desde la carpeta backend con el venv activado:
    python seed_admin.py
"""

import asyncio
import sys
import os
from pathlib import Path

# Añadir la raíz del proyecto al path
sys.path.append(str(Path(__file__).resolve().parent.parent))

from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
from passlib.context import CryptContext

# Cargar .env desde la raíz del proyecto
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)

MONGODB_URL = os.getenv("MONGODB_URL")
DB_NAME = "gym_db"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ──────────────────────────────────────────
#  Datos del admin por defecto
# ──────────────────────────────────────────
ADMIN_EMAIL    = "rafa@prueba.com"
ADMIN_PASSWORD = "123"
ADMIN_NAME     = "Rafa Admin"
# ──────────────────────────────────────────

async def seed():
    if not MONGODB_URL:
        print("❌ MONGODB_URL no encontrada en .env")
        sys.exit(1)

    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DB_NAME]

    # Comprobar si ya existe
    existing = await db.users.find_one({"email": ADMIN_EMAIL})
    if existing:
        print(f"⚠️  El usuario '{ADMIN_EMAIL}' ya existe. No se ha creado nada.")
        client.close()
        return

    hashed_password = pwd_context.hash(ADMIN_PASSWORD)

    admin_doc = {
        "email":           ADMIN_EMAIL,
        "full_name":       ADMIN_NAME,
        "role":            "admin",
        "hashed_password": hashed_password,
        "created_at":      datetime.utcnow(),
    }

    result = await db.users.insert_one(admin_doc)
    print(f"✅ Admin creado correctamente!")
    print(f"   📧 Email:    {ADMIN_EMAIL}")
    print(f"   🔑 Password: {ADMIN_PASSWORD}")
    print(f"   🆔 ID:       {result.inserted_id}")

    client.close()

if __name__ == "__main__":
    asyncio.run(seed())
