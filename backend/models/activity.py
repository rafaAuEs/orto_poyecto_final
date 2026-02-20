from pydantic import BaseModel, Field, field_validator
from datetime import datetime, timezone
from typing import Optional

class ActivityBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    capacity: int = Field(..., gt=0, description="Max number of attendees")
    location: str
    instructor: str

    @field_validator('end_time')
    def end_time_must_be_after_start_time(cls, v, values):
        if 'start_time' in values.data and v <= values.data['start_time']:
            raise ValueError('end_time must be after start_time')
        return v

class ActivityCreate(ActivityBase):
    pass

class ActivityUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    capacity: Optional[int] = None
    location: Optional[str] = None
    instructor: Optional[str] = None

class ActivityInDB(ActivityBase):
    id: str = Field(alias="_id")
    booked_count: int = 0
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Config:
        populate_by_name = True
        json_encoders = {
            datetime: lambda v: v.replace(tzinfo=timezone.utc).isoformat().replace("+00:00", "Z") if v.tzinfo is None else v.isoformat().replace("+00:00", "Z")
        }
