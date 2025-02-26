import uvicorn
import logging
from app.db_init import init_db

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if __name__ == "__main__":
    # Initialize database
    logger.info("Initializing database...")
    init_db()
    
    # Start FastAPI server
    logger.info("Starting API server...")
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True) 