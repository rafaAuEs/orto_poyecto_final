from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from backend.models.reservation import ReservationCreate, ReservationInDB, ReservationAttendance, AttendanceUpdate
from backend.db.reservations import create_reservation_db, cancel_reservation_db, get_user_reservations, get_activity_reservations, update_attendance_db
from backend.routes.auth import get_current_user, get_current_admin

router = APIRouter()

@router.post("/", response_model=ReservationInDB, status_code=status.HTTP_201_CREATED)
async def create_reservation(reservation: ReservationCreate, current_user: dict = Depends(get_current_user)):
    res_id, error = await create_reservation_db(str(current_user["_id"]), reservation)
    if error:
        raise HTTPException(status_code=400, detail=error)
    return {**reservation.dict(), "id": res_id, "user_id": str(current_user["_id"]), "status": "active"}

@router.get("/me", response_model=List[ReservationInDB])
async def read_my_reservations(current_user: dict = Depends(get_current_user)):
    reservations = await get_user_reservations(str(current_user["_id"]))
    return reservations

@router.put("/{reservation_id}/cancel")
async def cancel_reservation(reservation_id: str, current_user: dict = Depends(get_current_user)):
    result, error = await cancel_reservation_db(reservation_id, str(current_user["_id"]))
    if error:
        raise HTTPException(status_code=400, detail=error)
    return result

@router.get("/activity/{activity_id}", response_model=List[ReservationAttendance])
async def list_activity_attendees(activity_id: str, current_user: dict = Depends(get_current_admin)):
    reservations = await get_activity_reservations(activity_id)
    return reservations

@router.put("/{reservation_id}/attendance")
async def update_attendance(reservation_id: str, update: AttendanceUpdate, current_user: dict = Depends(get_current_admin)):
    success = await update_attendance_db(reservation_id, update.status)
    if not success:
        raise HTTPException(status_code=400, detail="Could not update attendance")
    return {"status": "updated"}
