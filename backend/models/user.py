from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    role: str  # "admin" or "client"

class UserCreate(UserBase):
    password: str

class UserInDB(UserBase):
    hashed_password: str
    created_at: Optional[datetime] = None

class UserResponse(UserBase):
    id: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
