from backend.db.mongodb import get_database
from backend.models.activity import ActivityCreate, ActivityUpdate, ActivityInDB
from bson import ObjectId
from datetime import datetime

async def get_all_activities(skip: int = 0, limit: int = 100):
    db = await get_database()
    activities = []
    cursor = db.activities.find().skip(skip).limit(limit).sort("start_time", 1)
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        activities.append(doc)
    return activities

async def get_activity(id: str):
    db = await get_database()
    try:
        obj_id = ObjectId(id)
    except:
        return None
    doc = await db.activities.find_one({"_id": obj_id})
    if doc:
        doc["_id"] = str(doc["_id"])
    return doc

async def create_activity(activity: ActivityCreate):
    db = await get_database()
    activity_doc = activity.dict()
    activity_doc["booked_count"] = 0
    activity_doc["created_at"] = datetime.utcnow()
    
    result = await db.activities.insert_one(activity_doc)
    return result.inserted_id

async def update_activity(id: str, activity_update: ActivityUpdate):
    db = await get_database()
    try:
        obj_id = ObjectId(id)
    except:
        return None
        
    update_data = {k: v for k, v in activity_update.dict().items() if v is not None}
    
    if len(update_data) >= 1:
        result = await db.activities.update_one(
            {"_id": obj_id}, {"$set": update_data}
        )
        return result.modified_count
    return 0

async def delete_activity(id: str):
    db = await get_database()
    try:
        obj_id = ObjectId(id)
    except:
        return None
    result = await db.activities.delete_one({"_id": obj_id})
    return result.deleted_count
