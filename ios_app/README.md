# ChatBuddy iOS App

This is the iOS frontend for the ChatBuddy application. It provides a user-friendly interface for conversational AI interactions using voice or text input.

## Features

- Voice-to-text using on-device Speech framework or Whisper
- Text-to-speech using AVSpeechSynthesizer
- Real-time chat with LLM
- Session management and history
- Settings for API configuration and voice preferences
- Modern SwiftUI interface

## Setup Instructions

### Prerequisites

- Xcode 14.0+
- iOS 15.0+ device or simulator
- Active Apple Developer account (for testing on physical devices)
- Backend server running (see `../backend/README.md`)

### Installation

1. Open the Xcode project:

```bash
cd ios_app
open ChatBuddy.xcodeproj
```

2. Configure API settings:
   - Open the `Configuration.swift` file
   - Update the `baseURL` to point to your backend server
   - Set other configuration options as needed

3. Build and run the application in Xcode

### Configuration

The app can be configured through the Settings screen or by modifying `Configuration.swift`:

- LLM Provider: OpenAI (default) or others as implemented
- Voice-to-Text: On-device (Speech framework) or Whisper
- Text-to-Speech: On-device (AVSpeechSynthesizer) or cloud-based
- Voice settings: Voice selection, speed, pitch

## Project Structure

```
ios_app/
├── ChatBuddy/
│   ├── App/ - App entry point and lifecycle
│   ├── Views/ - SwiftUI views
│   │   ├── Chat/ - Chat interface views
│   │   ├── Settings/ - Settings views
│   │   └── Auth/ - Authentication views
│   ├── ViewModels/ - ViewModels for MVVM pattern
│   ├── Models/ - Data models
│   ├── Services/ - Service layer
│   │   ├── API/ - Backend API communication
│   │   ├── Speech/ - Voice-to-text services
│   │   ├── TTS/ - Text-to-speech services
│   │   └── Auth/ - Authentication services
│   └── Utilities/ - Helper functions and extensions
├── ChatBuddyTests/ - Unit tests
└── ChatBuddyUITests/ - UI tests
```

## Development

### Adding a New Feature

1. Create appropriate models in the `Models` directory
2. Create or update services in the `Services` directory
3. Create or update ViewModels in the `ViewModels` directory
4. Create or update views in the `Views` directory
5. Add unit tests in the `ChatBuddyTests` directory

### Testing

- Run unit tests in Xcode using Cmd+U
- Test on multiple device sizes using the Xcode Simulator
- Test voice features on physical devices for best results

## Troubleshooting

### Common Issues

- **Microphone Access Denied**: Ensure microphone permission is granted in Settings
- **API Connection Failed**: Check that backend server is running and URL is correct
- **Voice Recognition Issues**: Test on a physical device in a quiet environment

### Debug Tools

The app includes a debug overlay for monitoring:
- Transcription latency
- LLM response time
- TTS generation time
- End-to-end latency

Access it by tapping the gear icon and enabling "Debug Mode" in Settings. 