from backend.db.mongodb import get_database
from backend.models.user import UserCreate
from backend.core.security import get_password_hash
from datetime import datetime
from bson import ObjectId

async def get_user_by_email(email: str):
    db = await get_database()
    user = await db.users.find_one({"email": email})
    return user

async def create_user(user: UserCreate):
    db = await get_database()
    
    # 1. Check if user exists
    existing_user = await get_user_by_email(user.email)
    if existing_user:
        return None # Indicate failure
        
    # 2. Hash password
    hashed_password = get_password_hash(user.password)
    
    # 3. Create document
    user_doc = {
        "email": user.email,
        "full_name": user.full_name,
        "hashed_password": hashed_password,
        "role": user.role,
        "created_at": datetime.utcnow()
    }
    
    # 4. Insert
    result = await db.users.insert_one(user_doc)
    return result.inserted_id

async def get_all_users():
    db = await get_database()
    users = []
    # Sort by created_at desc (newest first)
    cursor = db.users.find().sort("created_at", -1)
    async for doc in cursor:
        # Map _id to id for Pydantic
        doc["id"] = str(doc["_id"])
        
        # Remove sensitive info
        if "hashed_password" in doc:
            del doc["hashed_password"]
        # Ensure created_at exists (for old records)
        if "created_at" not in doc:
            doc["created_at"] = None
        users.append(doc)
    return users

async def delete_user_db(user_id: str):
    db = await get_database()
    try:
        obj_id = ObjectId(user_id)
    except:
        return False
        
    result = await db.users.delete_one({"_id": obj_id})
    return result.deleted_count > 0
