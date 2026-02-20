import asyncio
import sys
import os

# Add root to path
sys.path.append(os.getcwd())

from backend.db.mongodb import connect_to_mongo, close_mongo_connection, get_database

async def check():
    try:
        print("Attempting to connect to MongoDB...")
        await connect_to_mongo()
        from backend.db.mongodb import db
        # Send a ping to confirm a successful connection
        # Correctly ping using the client admin database
        await db.client.admin.command('ping')
        print("✅ SUCCESS: Connected to MongoDB Atlas!")
        await close_mongo_connection()
    except Exception as e:
        print(f"❌ ERROR: Could not connect. Details: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(check())
