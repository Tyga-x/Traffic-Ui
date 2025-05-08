import aiosqlite
import os
import logging
from datetime import datetime
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("database")

# Get database path from environment variable
DB_PATH = os.getenv("DB_PATH", "/etc/x-ui/x-ui.db")

async def get_db_connection():
    """
    Establish a connection to the SQLite database.
    """
    try:
        conn = await aiosqlite.connect(DB_PATH)
        conn.row_factory = aiosqlite.Row
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {str(e)}")
        raise

async def get_user_by_uuid(uuid):
    """
    Get user traffic data by UUID.
    
    Args:
        uuid (str): The user's UUID
        
    Returns:
        dict: User data including traffic stats or None if not found
    """
    try:
        conn = await get_db_connection()
        
        # Query to get user data and traffic information
        query = """
        SELECT 
            u.id, u.uuid, u.email as username, u.enable, 
            i.remark as inbound, 
            c.up as upload, c.down as download,
            u.expiry_time
        FROM users u
        JOIN inbounds i ON u.inbound_id = i.id
        JOIN client_traffics c ON u.id = c.user_id
        WHERE u.uuid = ?
        """
        
        async with conn.execute(query, (uuid,)) as cursor:
            row = await cursor.fetchone()
            
        await conn.close()
        
        if not row:
            return None
            
        # Convert row to dict
        user_data = dict(row)
        
        # Check if user is expired
        if user_data.get("expiry_time"):
            expiry_timestamp = int(user_data["expiry_time"]) / 1000  # Convert from milliseconds
            current_timestamp = datetime.now().timestamp()
            user_data["is_expired"] = current_timestamp > expiry_timestamp
            
            # Format expiry time as ISO string
            expiry_date = datetime.fromtimestamp(expiry_timestamp)
            user_data["expiry_time"] = expiry_date.isoformat()
        
        return user_data
        
    except Exception as e:
        logger.error(f"Error fetching user by UUID: {str(e)}")
        raise

async def get_user_by_username(username):
    """
    Get user traffic data by username (email).
    
    Args:
        username (str): The user's username/email
        
    Returns:
        dict: User data including traffic stats or None if not found
    """
    try:
        conn = await get_db_connection()
        
        # Query to get user data and traffic information
        query = """
        SELECT 
            u.id, u.uuid, u.email as username, u.enable, 
            i.remark as inbound, 
            c.up as upload, c.down as download,
            u.expiry_time
        FROM users u
        JOIN inbounds i ON u.inbound_id = i.id
        JOIN client_traffics c ON u.id = c.user_id
        WHERE u.email = ?
        """
        
        async with conn.execute(query, (username,)) as cursor:
            row = await cursor.fetchone()
            
        await conn.close()
        
        if not row:
            return None
            
        # Convert row to dict
        user_data = dict(row)
        
        # Check if user is expired
        if user_data.get("expiry_time"):
            expiry_timestamp = int(user_data["expiry_time"]) / 1000  # Convert from milliseconds
            current_timestamp = datetime.now().timestamp()
            user_data["is_expired"] = current_timestamp > expiry_timestamp
            
            # Format expiry time as ISO string
            expiry_date = datetime.fromtimestamp(expiry_timestamp)
            user_data["expiry_time"] = expiry_date.isoformat()
        
        return user_data
        
    except Exception as e:
        logger.error(f"Error fetching user by username: {str(e)}")
        raise

async def test_database_connection():
    """
    Test the database connection and schema.
    
    Returns:
        bool: True if connection is successful, False otherwise
    """
    try:
        conn = await get_db_connection()
        
        # Check if required tables exist
        tables_query = "SELECT name FROM sqlite_master WHERE type='table'"
        async with conn.execute(tables_query) as cursor:
            tables = [row['name'] for row in await cursor.fetchall()]
            
        await conn.close()
        
        required_tables = ['users', 'inbounds', 'client_traffics']
        missing_tables = [table for table in required_tables if table not in tables]
        
        if missing_tables:
            logger.error(f"Missing required tables: {', '.join(missing_tables)}")
            return False
            
        return True
        
    except Exception as e:
        logger.error(f"Database test failed: {str(e)}")
        return False
