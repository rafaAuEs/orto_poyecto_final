import asyncio
import os
import sys
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

# Cargar variables de entorno desde la raíz del proyecto
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dotenv_path = os.path.join(base_dir, ".env")
load_dotenv(dotenv_path)

# Obtener URL
MONGODB_URL = os.getenv("MONGODB_URL")
if not MONGODB_URL:
    print("❌ Error: MONGODB_URL no encontrada en .env")
    sys.exit(1)

# Nombre de la BD (extraído de la URL o default)
DB_NAME = "gym_db"

async def init_db(reset=False):
    print(f"🔌 Conectando a MongoDB...")
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DB_NAME]
    
    if reset:
        print("⚠️  Borrando base de datos actual (RESET)...")
        await client.drop_database(DB_NAME)
        print("✅ Base de datos borrada.")

    print("🛠  Creando Índices y Colecciones...")

    # 1. USERS
    # Email único
    await db.users.create_index("email", unique=True)
    print("   👉 Índice creado: users.email (UNIQUE)")

    # 2. RESERVATIONS
    # Evitar duplicados: Un usuario no puede tener 2 reservas ACTIVAS para la misma actividad
    await db.reservations.create_index(
        [("user_id", 1), ("activity_id", 1)],
        unique=True,
        partialFilterExpression={"status": "active"} 
    )
    print("   👉 Índice creado: reservations (user_id + activity_id) UNIQUE (si active)")

    # Índice para buscar rápido por usuario
    await db.reservations.create_index("user_id")
    
    # 3. ACTIVITIES
    # Índice por fecha para ordenar rápido
    await db.activities.create_index("start_time")
    print("   👉 Índice creado: activities.start_time")

    print("\n✅ Esquema de base de datos inicializado correctamente.")
    client.close()

if __name__ == "__main__":
    # Si pasas el argumento --reset, borra todo antes
    reset_mode = "--reset" in sys.argv
    asyncio.run(init_db(reset=reset_mode))
