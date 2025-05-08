from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel, Field
from typing import Optional, Union, Dict, Any
import os
import sys
from pathlib import Path
import logging
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv

# Import speed test module
from backend.speed_test import router as speed_test_router

# Add parser module to path
sys.path.append(str(Path(__file__).parent.parent))
from parser.database import get_user_by_uuid, get_user_by_username

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("api.log"),
    ],
)
logger = logging.getLogger("3x-ui-dashboard")

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)
RATE_LIMIT = os.getenv("RATE_LIMIT", "60/minute")

# Initialize FastAPI app
app = FastAPI(
    title="3x-ui Traffic Dashboard API",
    description="API for checking 3x-ui traffic usage",
    version="1.0.0",
)

# Add rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, specify your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the speed test router
app.include_router(speed_test_router, prefix="/api")

# Response models
class UserTrafficResponse(BaseModel):
    username: str
    uuid: str
    upload: int
    download: int
    total: int
    upload_gb: float
    download_gb: float
    total_gb: float
    inbound: str
    expiry_time: Optional[str] = None
    status: str = "active"

class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None

# Routes
@app.get("/api", response_class=JSONResponse)
def api_root():
    return {"message": "3x-ui Traffic Dashboard API"}

@app.get("/api/admin-contact", response_class=JSONResponse)
@limiter.limit(RATE_LIMIT)
def get_admin_contact(request: Request):
    """Get the Telegram admin contact URL"""
    telegram_url = os.getenv("TELEGRAM_ADMIN_URL", "")
    return {"telegram_url": telegram_url}

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/api/usage", response_model=Union[UserTrafficResponse, ErrorResponse])
@limiter.limit(RATE_LIMIT)
async def get_usage(
    request: Request,
    uuid: Optional[str] = None,
    username: Optional[str] = None
):
    try:
        if not uuid and not username:
            return JSONResponse(
                status_code=400,
                content={"error": "Missing parameter", "detail": "Either uuid or username must be provided"}
            )
        
        user_data = None
        if uuid:
            logger.info(f"Looking up user by UUID: {uuid}")
            user_data = await get_user_by_uuid(uuid)
        elif username:
            logger.info(f"Looking up user by username: {username}")
            user_data = await get_user_by_username(username)
        
        if not user_data:
            return JSONResponse(
                status_code=404,
                content={"error": "User not found", "detail": "No user found with the provided identifier"}
            )
        
        # Convert bytes to GB for better readability
        upload_gb = user_data["upload"] / (1024 ** 3)
        download_gb = user_data["download"] / (1024 ** 3)
        total_gb = upload_gb + download_gb
        
        return {
            "username": user_data["username"],
            "uuid": user_data["uuid"],
            "upload": user_data["upload"],
            "download": user_data["download"],
            "total": user_data["upload"] + user_data["download"],
            "upload_gb": round(upload_gb, 2),
            "download_gb": round(download_gb, 2),
            "total_gb": round(total_gb, 2),
            "inbound": user_data["inbound"],
            "expiry_time": user_data.get("expiry_time"),
            "status": "expired" if user_data.get("is_expired", False) else "active"
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"error": "Server error", "detail": str(e)}
        )

# Serve static files (frontend)
frontend_path = Path(__file__).parent.parent / "frontend"
if frontend_path.exists():
    # Root route to serve the index.html file
    @app.get("/", include_in_schema=False)
    async def serve_root():
        return FileResponse(str(frontend_path / "index.html"))
    
    # Explicit redirect for root API path
    @app.get("/api/", include_in_schema=False)
    async def api_redirect():
        return {"message": "API endpoints available at /api/usage and /api/admin-contact"}
    
    # CSS files
    @app.get("/css/{file_path:path}", include_in_schema=False)
    async def serve_css(file_path: str):
        return FileResponse(str(frontend_path / "css" / file_path))
    
    # JavaScript files
    @app.get("/js/{file_path:path}", include_in_schema=False)
    async def serve_js(file_path: str):
        return FileResponse(str(frontend_path / "js" / file_path))
    
    # Image files
    @app.get("/img/{file_path:path}", include_in_schema=False)
    async def serve_img(file_path: str):
        return FileResponse(str(frontend_path / "img" / file_path))
    
    # Fallback for any other static files
    @app.get("/{file_path:path}", include_in_schema=False)
    async def serve_static(file_path: str):
        file_path_obj = frontend_path / file_path
        if file_path_obj.exists() and file_path_obj.is_file():
            return FileResponse(str(file_path_obj))
        return FileResponse(str(frontend_path / "index.html"))

# Run the application
if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host=host, port=port, reload=True)
