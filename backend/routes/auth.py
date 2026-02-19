from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from backend.db.users import create_user, get_user_by_email, get_all_users, delete_user_db
from backend.models.user import UserCreate, UserResponse
from backend.core.security import verify_password, create_access_token, SECRET_KEY, ALGORITHM
from jose import JWTError, jwt
from datetime import timedelta
from typing import List

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# --- Dependencies ---
async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    user = await get_user_by_email(email)
    if user is None:
        raise credentials_exception
    return user

async def get_current_admin(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user doesn't have enough privileges"
        )
    return current_user

# --- Endpoints ---

@router.post("/register", response_model=UserResponse)
async def register(user: UserCreate):
    # Check if user already exists
    existing_user = await get_user_by_email(user.email)
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    user_id = await create_user(user)
    if not user_id:
        raise HTTPException(status_code=500, detail="Error creating user")
        
    return {**user.dict(), "id": str(user_id)}

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    print(f"🔹 LOGIN ATTEMPT: username={form_data.username}") # DEBUG log
    
    # 1. Get user from DB
    user = await get_user_by_email(form_data.username)
    if not user:
        print(f"❌ User not found: {form_data.username}")
        raise HTTPException(status_code=400, detail="Incorrect email or password")
        
    # 2. Verify password
    if not verify_password(form_data.password, user["hashed_password"]):
        print(f"❌ Password mismatch for: {form_data.username}")
        raise HTTPException(status_code=400, detail="Incorrect email or password")
        
    # 3. Create token
    access_token_expires = timedelta(minutes=60 * 24) # 24 horas para desarrollo
    access_token = create_access_token(
        data={"sub": user["email"], "role": user["role"]},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: dict = Depends(get_current_user)):
    return {**current_user, "id": str(current_user["_id"])}

@router.get("/users", response_model=List[UserResponse])
async def list_users(current_user: dict = Depends(get_current_admin)):
    users = await get_all_users()
    return users

@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: str, current_user: dict = Depends(get_current_admin)):
    if str(current_user["_id"]) == user_id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
        
    deleted = await delete_user_db(user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="User not found")
    return None
