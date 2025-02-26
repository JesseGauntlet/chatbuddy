from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.models.database import get_db
from app.models.user import User
from app.models.chat import Session as ChatSession, Message
from app.services.auth import get_current_user
from app.services.llm import get_llm_provider, LLMProvider
from app.schemas import ChatRequest, ChatResponse, MessageCreate, MessageResponse

router = APIRouter()

@router.post("/message", response_model=ChatResponse)
async def send_message(
    chat_request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    llm_provider: LLMProvider = Depends(get_llm_provider)
):
    """Send a message and get AI response"""
    # Get or create session
    if chat_request.session_id:
        # Get existing session
        session = db.query(ChatSession).filter(
            ChatSession.session_id == chat_request.session_id,
            ChatSession.user_id == current_user.user_id
        ).first()
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )
    else:
        # Create new session
        session = ChatSession(user_id=current_user.user_id)
        db.add(session)
        db.commit()
        db.refresh(session)
    
    # Create user message
    user_message = Message(
        session_id=session.session_id,
        content=chat_request.message,
        sender="user"
    )
    db.add(user_message)
    db.commit()
    db.refresh(user_message)
    
    # Get conversation history for context
    message_history = db.query(Message).filter(
        Message.session_id == session.session_id
    ).order_by(Message.timestamp.asc()).all()
    
    # Format messages for LLM
    formatted_messages = []
    
    # Add system message for context
    formatted_messages.append({
        "role": "system",
        "content": "You are a helpful assistant in the ChatBuddy app. Provide concise and accurate responses."
    })
    
    # Add conversation history
    for msg in message_history:
        role = "assistant" if msg.sender == "ai" else msg.sender
        formatted_messages.append({
            "role": role,
            "content": msg.content
        })
    
    # Generate AI response
    ai_response_text = await llm_provider.generate_response(
        messages=formatted_messages,
        model=chat_request.model
    )
    
    # Save AI response to database
    ai_message = Message(
        session_id=session.session_id,
        content=ai_response_text,
        sender="ai"
    )
    db.add(ai_message)
    db.commit()
    db.refresh(ai_message)
    
    # Return response
    return {
        "session_id": session.session_id,
        "message": user_message,
        "ai_response": ai_message
    }

@router.get("/messages/{session_id}", response_model=List[MessageResponse])
async def get_messages(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all messages for a session"""
    # Check if session exists and belongs to user
    session = db.query(ChatSession).filter(
        ChatSession.session_id == session_id,
        ChatSession.user_id == current_user.user_id
    ).first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # Get messages
    messages = db.query(Message).filter(
        Message.session_id == session_id
    ).order_by(Message.timestamp.asc()).all()
    
    return messages 