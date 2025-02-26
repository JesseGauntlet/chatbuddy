from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any

from openai import OpenAI
from app.config import get_settings

# Get settings
settings = get_settings()

# Base LLM Provider class
class LLMProvider(ABC):
    """Abstract base class for LLM providers"""

    @abstractmethod
    async def generate_response(self, messages: List[Dict[str, str]], model: Optional[str] = None) -> str:
        """Generate a response from the LLM"""
        pass

# OpenAI implementation
class OpenAIProvider(LLMProvider):
    """OpenAI LLM provider implementation"""

    def __init__(self):
        """Initialize with API key from settings"""
        self.api_key = settings.OPENAI_API_KEY
        self.default_model = settings.LLM_MODEL
        self.client = OpenAI(api_key=self.api_key)

    async def generate_response(self, messages: List[Dict[str, str]], model: Optional[str] = None) -> str:
        """Generate a response using OpenAI API"""
        try:
            # Use provided model or default from settings
            model_to_use = model or self.default_model

            # Call OpenAI API
            response = self.client.chat.completions.create(
                model=model_to_use,
                messages=messages,
                temperature=0.7,
                max_tokens=800,
                top_p=1.0,
                frequency_penalty=0.0,
                presence_penalty=0.0
            )

            # Extract and return response text
            return response.choices[0].message.content.strip()

        except Exception as e:
            # Log the error (in a production app, use proper logging)
            print(f"Error generating OpenAI response: {str(e)}")
            # Return error message or fallback response
            return "I'm sorry, I couldn't generate a response at this time. Please try again later."

# Factory function to get the appropriate LLM provider
def get_llm_provider() -> LLMProvider:
    """Factory function to get LLM provider based on settings"""
    # In the future, this could check a setting to determine which provider to use
    return OpenAIProvider() 