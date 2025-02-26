# ChatBuddy

ChatBuddy is an iOS application that enables natural, voice-based conversations with AI. It features voice-to-text transcription, interaction with large language models, and text-to-speech responses.

## Project Structure

This repository contains two main components:

1. **backend/** - Python FastAPI backend server
2. **ios_app/** - Swift iOS application frontend

## Features

- Voice chat with LLM models (starting with OpenAI)
- Text chat option
- Session management and conversation history
- User authentication and profiles
- Settings for voice and API configuration
- Optimized for low latency
- Debug UI for performance monitoring

## Quick Start

### Backend Setup

1. Set up Python environment:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. Create environment configuration:

```bash
cp .env.example .env
# Edit .env with your OpenAI API key and other settings
```

3. Run the server:

```bash
python run.py
```

The API will be accessible at http://localhost:8000

### iOS App Setup

1. Open the Xcode project:

```bash
cd ios_app
# Create the Xcode project first
# Then:
open ChatBuddy.xcodeproj
```

2. Update API configuration in `Configuration.swift`
3. Build and run on simulator or device

## Detailed Documentation

- [Backend Documentation](backend/README.md)
- [iOS App Documentation](ios_app/README.md)
- [PRD](PRD.md) - Product Requirements Document

## Development Roadmap

Follow the development plan in our [checklist](checklist.md), which outlines:

- [x] Project setup
- [ ] Backend development
- [ ] iOS app development
- [ ] Integration and testing
- [ ] Optimization and refinement
- [ ] Deployment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License 