from functools import lru_cache
from typing import List, Optional
import os

from pydantic_settings import BaseSettings
from pydantic import validator

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables
    """
    # API Configuration
    API_VERSION: str = "0.1.0"
    DEBUG: bool = False
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = ["*"]  # For development, restrict in production

    # Database Configuration
    DATABASE_URL: str = "sqlite:///./chatbuddy.db"
    
    # JWT Configuration
    JWT_SECRET_KEY: str = "development_secret_key"  # Change in production!
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # OpenAI Configuration
    OPENAI_API_KEY: Optional[str] = None
    LLM_MODEL: str = "gpt-3.5-turbo"
    
    @validator("OPENAI_API_KEY", pre=True)
    def validate_openai_api_key(cls, v):
        if not v:
            raise ValueError("OPENAI_API_KEY must be set")
        return v
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    """
    Returns application settings, cached for performance
    """
    return Settings()

# Create a .env.example file if one doesn't exist
if not os.path.exists(os.path.join(os.path.dirname(__file__), "..", ".env.example")):
    with open(os.path.join(os.path.dirname(__file__), "..", ".env.example"), "w") as f:
        f.write("""# ChatBuddy Environment Variables
# Copy this file to .env and fill in your values

# API Configuration
DEBUG=False

# Database Configuration
DATABASE_URL=sqlite:///./chatbuddy.db

# JWT Configuration
JWT_SECRET_KEY=your_secret_key
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key
LLM_MODEL=gpt-3.5-turbo
""") 