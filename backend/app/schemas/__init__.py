from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid

# User schemas
class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(UserBase):
    user_id: str
    created_at: datetime
    is_active: bool
    
    class Config:
        orm_mode = True

# Authentication schemas
class TokenResponse(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# Session schemas
class SessionBase(BaseModel):
    title: Optional[str] = "New Conversation"

class SessionCreate(SessionBase):
    pass

class SessionResponse(SessionBase):
    session_id: str
    user_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    summary_text: Optional[str] = None
    
    class Config:
        orm_mode = True

# Message schemas
class MessageBase(BaseModel):
    content: str
    sender: str = Field(..., description="Either 'user', 'ai', or 'system'")

class MessageCreate(MessageBase):
    session_id: str

class MessageResponse(MessageBase):
    message_id: str
    timestamp: datetime
    
    class Config:
        orm_mode = True

# Chat completion schemas
class ChatRequest(BaseModel):
    session_id: Optional[str] = None
    message: str
    model: Optional[str] = None

class ChatResponse(BaseModel):
    session_id: str
    message: MessageResponse
    ai_response: MessageResponse 