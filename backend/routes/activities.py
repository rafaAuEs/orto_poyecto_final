from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from backend.models.activity import ActivityCreate, ActivityInDB, ActivityUpdate
from backend.db.activities import create_activity, get_all_activities, get_activity, update_activity, delete_activity
from backend.routes.auth import get_current_user

router = APIRouter()

# Dependency to check for admin role
async def get_current_admin(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user doesn't have enough privileges"
        )
    return current_user

@router.get("/", response_model=List[ActivityInDB])
async def list_activities(skip: int = 0, limit: int = 100):
    activities = await get_all_activities(skip, limit)
    return activities

@router.post("/", response_model=ActivityInDB, status_code=status.HTTP_201_CREATED)
async def create_new_activity(activity: ActivityCreate, current_user: dict = Depends(get_current_admin)):
    activity_id = await create_activity(activity)
    created_activity = await get_activity(activity_id)
    return created_activity

@router.get("/{activity_id}", response_model=ActivityInDB)
async def read_activity(activity_id: str):
    activity = await get_activity(activity_id)
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")
    return activity

@router.put("/{activity_id}", response_model=ActivityInDB)
async def update_existing_activity(activity_id: str, activity_update: ActivityUpdate, current_user: dict = Depends(get_current_admin)):
    updated_count = await update_activity(activity_id, activity_update)
    if updated_count == 0:
        # Check if it exists
        existing = await get_activity(activity_id)
        if not existing:
             raise HTTPException(status_code=404, detail="Activity not found")
        # If exists but no changes, just return it
        
    activity = await get_activity(activity_id)
    return activity

@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_activity(activity_id: str, current_user: dict = Depends(get_current_admin)):
    deleted_count = await delete_activity(activity_id)
    if deleted_count == 0:
        raise HTTPException(status_code=404, detail="Activity not found")
    return None
