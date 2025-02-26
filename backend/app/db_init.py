import logging
from sqlalchemy import inspect

from app.models.database import engine, Base
from app.models import User, Session, Message

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_tables():
    """Create database tables if they don't exist"""
    # Check if tables exist
    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()
    
    # Log existing tables
    if existing_tables:
        logger.info(f"Existing tables: {', '.join(existing_tables)}")
    else:
        logger.info("No existing tables found")
    
    # Create tables
    logger.info("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")

def init_db():
    """Initialize the database"""
    create_tables()
    
    # Add any additional initialization here
    # For example, creating admin user if it doesn't exist
    
    logger.info("Database initialization complete")

if __name__ == "__main__":
    # Run this directly to initialize the database
    init_db() 