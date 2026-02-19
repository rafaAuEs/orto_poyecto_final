import sys
import os
from contextlib import asynccontextmanager

# Añadir el directorio raíz del proyecto al sys.path para que las importaciones de 'backend.' funcionen
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.db.mongodb import connect_to_mongo, close_mongo_connection
from backend.routes.auth import router as auth_router
from backend.routes.activities import router as activities_router
from backend.routes.reservations import router as reservations_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    yield
    await close_mongo_connection()

app = FastAPI(lifespan=lifespan)

# Configurar CORS
origins = [
    "http://localhost:3000",  # Vite Dev Server (Nuevo puerto)
    "http://127.0.0.1:3000",
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "app://."                 # Electron Production
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # Permitir TODO en desarrollo (Wildcard)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(activities_router, prefix="/activities", tags=["activities"])
app.include_router(reservations_router, prefix="/reservations", tags=["reservations"])

@app.get("/")
async def root():
    return {"message": "API Online", "db_status": "connected"}
