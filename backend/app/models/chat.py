from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
import uuid

from app.models.database import Base

class Session(Base):
    """Session model to group messages in a conversation"""
    __tablename__ = "sessions"
    
    # Primary key
    session_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Foreign key to user
    user_id = Column(String(36), ForeignKey("users.user_id"))
    
    # Session information
    title = Column(String(255), default="New Conversation")
    summary_text = Column(Text, nullable=True)  # Summary of the conversation
    
    # Timestamps
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)  # Null if session is ongoing
    
    # Relationships
    user = relationship("User", back_populates="sessions")
    messages = relationship("Message", back_populates="session", cascade="all, delete-orphan")

class Message(Base):
    """Message model for storing conversation messages"""
    __tablename__ = "messages"
    
    # Primary key
    message_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Foreign key to session
    session_id = Column(String(36), ForeignKey("sessions.session_id"))
    
    # Message information
    sender = Column(String(10))  # 'user', 'ai', or 'system'
    content = Column(Text)
    
    # Timestamp
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # For future RAG implementation
    embedding = Column(Text, nullable=True)  # Store as base64 string for now
    
    # Relationships
    session = relationship("Session", back_populates="messages") 