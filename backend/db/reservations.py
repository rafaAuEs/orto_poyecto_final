from backend.db.mongodb import get_database
from backend.models.reservation import ReservationStatus, ReservationCreate
from backend.models.activity import ActivityInDB
from bson import ObjectId
from datetime import datetime
from pymongo import ReturnDocument

async def create_reservation_db(user_id: str, reservation_create: ReservationCreate):
    db = await get_database()
    activity_id = reservation_create.activity_id

    try:
        act_oid = ObjectId(activity_id)
        user_oid = ObjectId(user_id)
    except:
        return None, "Invalid ID format"

    # 1. Check Capacity & Increment (Atomic Operation)
    activity = await db.activities.find_one({"_id": act_oid})
    if not activity:
        return None, "Activity not found"
        
    if activity.get("booked_count", 0) >= activity["capacity"]:
        return None, "Activity is full"

    # 2. Check for duplicate reservation
    existing = await db.reservations.find_one({
        "user_id": user_id,
        "activity_id": activity_id,
        "status": ReservationStatus.ACTIVE
    })
    if existing:
        return None, "You already have an active reservation"

    # 3. Create Reservation
    reservation_doc = {
        "user_id": user_id,
        "activity_id": activity_id,
        "activity_title": activity.get("title", "Unknown"),
        "activity_start_time": activity.get("start_time"),
        "status": ReservationStatus.ACTIVE,
        "created_at": datetime.utcnow()
    }

    try:
        # Insert reservation first
        res_result = await db.reservations.insert_one(reservation_doc)
        
        # If successful, increment activity counter
        await db.activities.update_one(
            {"_id": act_oid},
            {"$inc": {"booked_count": 1}}
        )
        
        return str(res_result.inserted_id), None
        
    except Exception as e:
        return None, f"Reservation failed: {str(e)}"

async def cancel_reservation_db(reservation_id: str, user_id: str):
    db = await get_database()
    
    try:
        res_oid = ObjectId(reservation_id)
    except:
        return None, "Invalid ID"
        
    # 1. Get Reservation
    reservation = await db.reservations.find_one({"_id": res_oid})
    if not reservation:
        return None, "Reservation not found"
        
    # Security check: User must own the reservation
    if reservation["user_id"] != user_id:
        return None, "Not authorized"
        
    if reservation["status"] != ReservationStatus.ACTIVE:
        return None, "Reservation is not active"

    # 2. Get Activity Time
    try:
        act_oid = ObjectId(reservation["activity_id"])
        activity = await db.activities.find_one({"_id": act_oid})
    except:
        return None, "Activity not found"
    
    if not activity:
        return None, "Activity not found"

    # 3. Apply 15-min Rule
    start_time = activity["start_time"]
    if start_time.tzinfo:
        start_time = start_time.replace(tzinfo=None)
        
    now = datetime.utcnow()
    time_diff = start_time - now
    minutes_diff = time_diff.total_seconds() / 60
    
    new_status = ReservationStatus.CANCELLED
    release_spot = True
    message = "Cancelled successfully"
    
    if minutes_diff <= 15:
        new_status = ReservationStatus.LATE_CANCELLED
        release_spot = False 
        message = "Late cancellation. Spot not released."
        
    # 4. Update Reservation Status
    await db.reservations.update_one(
        {"_id": res_oid},
        {"$set": {"status": new_status}}
    )
    
    # 5. Update Activity Count
    if release_spot:
        await db.activities.update_one(
            {"_id": act_oid},
            {"$inc": {"booked_count": -1}}
        )
        
    return {"status": new_status, "message": message}, None

async def get_user_reservations(user_id: str):
    db = await get_database()
    reservations = []
    cursor = db.reservations.find({"user_id": user_id}).sort("activity_start_time", -1)
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        reservations.append(doc)
    return reservations

async def get_activity_reservations(activity_id: str):
    db = await get_database()
    reservations = []
    
    # Get all relevant reservations
    cursor = db.reservations.find({
        "activity_id": activity_id,
        "status": {"$in": ["active", "late_cancelled", "attended", "absent"]}
    })
    
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        
        # Hydrate with user details manually (simple join)
        try:
            user_oid = ObjectId(doc["user_id"])
            user = await db.users.find_one({"_id": user_oid}, {"full_name": 1, "email": 1})
            if user:
                doc["user_name"] = user.get("full_name", "Unknown")
                doc["user_email"] = user.get("email", "Unknown")
        except:
            doc["user_name"] = "Unknown"
        
        reservations.append(doc)
    return reservations

async def update_attendance_db(reservation_id: str, status: str):
    db = await get_database()
    try:
        res_oid = ObjectId(reservation_id)
    except:
        return False
        
    if status not in [ReservationStatus.ATTENDED, ReservationStatus.ABSENT, ReservationStatus.ACTIVE]:
        return False

    result = await db.reservations.update_one(
        {"_id": res_oid},
        {"$set": {"status": status}}
    )
    return result.modified_count > 0
