from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid

from app.models.database import Base

class User(Base):
    """User model for authentication and profile information"""
    __tablename__ = "users"
    
    # Primary key - Use UUID for better security and distribution
    user_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Authentication fields
    username = Column(String(50), unique=True, index=True)
    email = Column(String(100), unique=True, index=True)
    password_hash = Column(String(255))
    
    # Profile fields
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Settings (could be expanded or separated into a different table)
    settings = Column(String, default='{}')  # JSON string
    
    # Relationships
    sessions = relationship("Session", back_populates="user", cascade="all, delete-orphan") 