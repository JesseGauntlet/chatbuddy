# Import all models to register them with SQLAlchemy
from app.models.database import Base
from app.models.user import User
from app.models.chat import Session, Message

# This file is primarily for initializing models when the app starts 