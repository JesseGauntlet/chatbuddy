# ChatBuddy Backend

This is the Python backend for the ChatBuddy application. It provides API endpoints for user management, chat sessions, and integration with LLM providers.

## Features

- User authentication (register, login)
- Session management
- Chat with LLM (OpenAI integration)
- Message history storage
- Modular LLM provider system for easy swapping

## Setup Instructions

### Prerequisites

- Python 3.8+
- Virtual environment tool

### Installation

1. Clone the repository
2. Create and activate a virtual environment:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:

```bash
pip install -r requirements.txt
```

4. Create a `.env` file based on `.env.example` and fill in your settings:

```bash
cp .env.example .env
# Edit .env file with your settings
```

### Running the Application

Start the development server:

```bash
python run.py
```

The API will be available at http://localhost:8000

### API Documentation

Once running, API documentation is available at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

### Authentication
- `POST /api/users/register` - Register a new user
- `POST /api/users/login` - Log in and get access token
- `GET /api/users/me` - Get current user information

### Sessions
- `POST /api/sessions/` - Create a new chat session
- `GET /api/sessions/` - Get all sessions for current user
- `GET /api/sessions/{session_id}` - Get a specific session
- `DELETE /api/sessions/{session_id}` - Delete a session

### Chat
- `POST /api/chat/message` - Send a message and get AI response
- `GET /api/chat/messages/{session_id}` - Get all messages for a session

## Testing

Run tests with pytest:

```bash
pytest
```

## Development

### Adding a New LLM Provider

1. Implement the `LLMProvider` abstract base class in `app/services/llm.py`
2. Update the `get_llm_provider` factory function to return your new provider

### Database Management

The database is automatically created and initialized when running the application. To manually initialize:

```bash
python -m app.db_init
``` 