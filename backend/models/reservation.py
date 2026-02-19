from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum

class ReservationStatus(str, Enum):
    ACTIVE = "active"
    CANCELLED = "cancelled"
    LATE_CANCELLED = "late_cancelled"
    ATTENDED = "attended"
    ABSENT = "absent"

class ReservationBase(BaseModel):
    activity_id: str

class ReservationCreate(ReservationBase):
    pass

class ReservationInDB(ReservationBase):
    id: str = Field(alias="_id")
    user_id: str
    status: ReservationStatus = ReservationStatus.ACTIVE
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Optional: Embed basic activity info
    activity_title: Optional[str] = None
    activity_start_time: Optional[datetime] = None

    class Config:
        populate_by_name = True
        json_encoders = {datetime: lambda v: v.isoformat()}

class ReservationAttendance(ReservationInDB):
    user_name: Optional[str] = None
    user_email: Optional[str] = None

class AttendanceUpdate(BaseModel):
    status: ReservationStatus
