import Foundation
import AVFoundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // Chat state
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var currentSession: ChatSession?
    @Published var errorMessage: String?
    
    // Voice state
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var transcribedText: String = ""
    
    // Services
    private let chatService = ChatService.shared
    private let speechRecognition = SpeechRecognitionService.shared
    private let elevenLabs = ElevenLabsService.shared
    
    // Date formatter for message timestamps
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()
    
    // Latency tracking for debugging
    private var messageStartTime: Date?
    @Published var lastResponseTime: TimeInterval = 0
    
    init() {
        setupSpeechRecognition()
    }
    
    private func setupSpeechRecognition() {
        // Set up callback for real-time transcription updates
        speechRecognition.onTranscription = { [weak self] text in
            DispatchQueue.main.async {
                self?.transcribedText = text
            }
        }
        
        // Set up callback for when speech recognition is complete
        speechRecognition.onRecognitionComplete = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    self?.isRecording = false
                    if !text.isEmpty {
                        self?.inputText = text
                        if Configuration.voiceInputEnabled {
                            // Auto-send message if voice input is enabled
                            Task {
                                await self?.sendMessage()
                            }
                        }
                    }
                case .failure(let error):
                    self?.isRecording = false
                    self?.errorMessage = "Speech recognition failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Create a new chat session
    func createSession(title: String = "New Conversation") async {
        do {
            isProcessing = true
            let newSession = try await chatService.createSession(title: title)
            
            // Convert to our model
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            
            if let startDate = dateFormatter.date(from: newSession.start_time),
               let endDate = newSession.end_time != nil ? dateFormatter.date(from: newSession.end_time!) : nil {
                
                currentSession = ChatSession(
                    id: newSession.session_id,
                    userId: newSession.user_id,
                    title: newSession.title,
                    startTime: startDate,
                    endTime: endDate,
                    summaryText: newSession.summary_text
                )
                
                messages = []
            }
            
            isProcessing = false
        } catch {
            isProcessing = false
            errorMessage = "Failed to create session: \(error.localizedDescription)"
            print("Session creation error: \(error)")
        }
    }
    
    /// Load an existing chat session
    func loadSession(id: String) async {
        do {
            isProcessing = true
            errorMessage = nil
            
            // Get session details
            let sessionResponse = try await chatService.getSession(id: id)
            
            // Get messages for this session
            let messagesResponse = try await chatService.getMessages(sessionId: id)
            
            // Convert to our models
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            
            if let startDate = dateFormatter.date(from: sessionResponse.start_time),
               let endDate = sessionResponse.end_time != nil ? dateFormatter.date(from: sessionResponse.end_time!) : nil {
                
                currentSession = ChatSession(
                    id: sessionResponse.session_id,
                    userId: sessionResponse.user_id,
                    title: sessionResponse.title,
                    startTime: startDate,
                    endTime: endDate,
                    summaryText: sessionResponse.summary_text
                )
            }
            
            // Convert messages
            messages = messagesResponse.compactMap { msg in
                if let date = dateFormatter.date(from: msg.timestamp),
                   let sender = MessageSender(rawValue: msg.sender) {
                    return Message(
                        id: msg.message_id,
                        content: msg.content,
                        sender: sender,
                        timestamp: date
                    )
                }
                return nil
            }
            
            isProcessing = false
        } catch {
            isProcessing = false
            errorMessage = "Failed to load session: \(error.localizedDescription)"
            print("Session loading error: \(error)")
        }
    }
    
    // MARK: - Message Handling
    
    /// Send a message
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        
        do {
            isProcessing = true
            errorMessage = nil
            messageStartTime = Date()
            
            // Add user message to the UI immediately
            let userMessage = Message.preview(content: messageText, sender: .user)
            messages.append(userMessage)
            
            print("DEBUG: Sending message to API: \(messageText)")
            
            // Send message to the API
            let response = try await chatService.sendMessage(
                sessionId: currentSession?.id,
                message: messageText
            )
            
            print("DEBUG: Received API response with session ID: \(response.session_id)")
            print("DEBUG: AI response content: \(response.ai_response.content)")
            print("DEBUG: AI response sender: \(response.ai_response.sender)")
            
            // If no session yet, set it
            if currentSession == nil {
                // Convert to our model
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                
                // Get session details
                let sessionResponse = try await chatService.getSession(id: response.session_id)
                
                if let startDate = dateFormatter.date(from: sessionResponse.start_time),
                   let endDate = sessionResponse.end_time != nil ? dateFormatter.date(from: sessionResponse.end_time!) : nil {
                    
                    currentSession = ChatSession(
                        id: sessionResponse.session_id,
                        userId: sessionResponse.user_id,
                        title: sessionResponse.title,
                        startTime: startDate,
                        endTime: endDate,
                        summaryText: sessionResponse.summary_text
                    )
                    
                    print("DEBUG: Created new session with ID: \(sessionResponse.session_id)")
                }
            }
            
            // Add AI response to the UI
            if let date = dateFormatter.date(from: response.ai_response.timestamp),
               let sender = MessageSender(rawValue: response.ai_response.sender) {
                
                print("DEBUG: Creating AI message with sender: \(sender.rawValue)")
                
                let aiMessage = Message(
                    id: response.ai_response.message_id,
                    content: response.ai_response.content,
                    sender: sender,
                    timestamp: date
                )
                
                print("DEBUG: Adding AI message to messages array. Current count: \(messages.count)")
                messages.append(aiMessage)
                print("DEBUG: New messages count: \(messages.count)")
                
                // Calculate response time
                if let startTime = messageStartTime {
                    lastResponseTime = Date().timeIntervalSince(startTime)
                    print("DEBUG: Response time: \(lastResponseTime) seconds")
                }
                
                // If voice output is enabled, speak the response
                if Configuration.voiceOutputEnabled {
                    Task {
                        try await speakResponse(response.ai_response.content)
                    }
                }
            } else {
                print("ERROR: Failed to parse AI response date or sender")
                print("DEBUG: Timestamp: \(response.ai_response.timestamp)")
                print("DEBUG: Sender: \(response.ai_response.sender)")
            }
            
            isProcessing = false
        } catch {
            isProcessing = false
            
            // Add error message
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            print("ERROR: Message sending error: \(error)")
            
            // Add system message showing error
            let errorMsg = Message.preview(
                content: "Failed to send message. Please try again.",
                sender: .system
            )
            messages.append(errorMsg)
        }
    }
    
    // MARK: - Voice Input
    
    /// Start voice recording
    func startRecording() async {
        do {
            // Request authorization first
            let isAuthorized = await speechRecognition.requestAuthorization()
            
            if !isAuthorized {
                errorMessage = "Speech recognition not authorized"
                return
            }
            
            // Start recording
            try await speechRecognition.startRecording()
            isRecording = true
            transcribedText = ""
            
        } catch {
            isRecording = false
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            print("Recording error: \(error)")
        }
    }
    
    /// Stop voice recording
    func stopRecording() {
        speechRecognition.stopRecording()
        // The completion handler will set isRecording to false
    }
    
    // MARK: - Voice Output
    
    /// Speak text using ElevenLabs
    func speakResponse(_ text: String) async throws {
        guard !text.isEmpty && Configuration.voiceOutputEnabled else { return }
        
        if isPlaying {
            elevenLabs.stopPlayback()
        }
        
        isPlaying = true
        
        do {
            try await elevenLabs.speakText(text)
        } catch {
            errorMessage = "Failed to generate speech: \(error.localizedDescription)"
            print("Speech generation error: \(error)")
        }
        
        isPlaying = false
    }
    
    /// Stop current playback
    func stopPlayback() {
        elevenLabs.stopPlayback()
        isPlaying = false
    }
} 