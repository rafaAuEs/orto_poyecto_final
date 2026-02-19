from motor.motor_asyncio import AsyncIOMotorClient
from backend.core.config import settings
from passlib.context import CryptContext
from datetime import datetime, timezone

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class DataBase:
    client: AsyncIOMotorClient = None

db = DataBase()

async def get_database():
    return db.client[settings.DATABASE_NAME]

async def connect_to_mongo():
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    print(f"Connected to MongoDB: {settings.DATABASE_NAME}")
    
    database = db.client[settings.DATABASE_NAME]
    
    # --- Indexes ---
    # User email unique
    await database.users.create_index("email", unique=True)
    
    # Reservation Unique (User + Activity) ONLY if Active
    await database.reservations.create_index(
        [("user_id", 1), ("activity_id", 1)],
        unique=True,
        partialFilterExpression={"status": "active"}
    )
    print("Indexes created.")

    # --- Default admin seed ---
    DEFAULT_ADMIN_EMAIL = "admin@admin.com"
    existing_admin = await database.users.find_one({"email": DEFAULT_ADMIN_EMAIL})
    if not existing_admin:
        hashed_password = pwd_context.hash("admin")
        await database.users.insert_one({
            "email":           DEFAULT_ADMIN_EMAIL,
            "full_name":       "Administrador",
            "role":            "admin",
            "hashed_password": hashed_password,
            "created_at":      datetime.now(timezone.utc),
        })
        print(f"✅ Admin por defecto creado: {DEFAULT_ADMIN_EMAIL} / admin")
    else:
        print(f"ℹ️  Admin por defecto ya existe: {DEFAULT_ADMIN_EMAIL}")

async def close_mongo_connection():
    db.client.close()
    print("Closed MongoDB connection")

