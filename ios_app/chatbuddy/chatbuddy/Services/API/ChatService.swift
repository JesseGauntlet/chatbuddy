import Foundation

class ChatService {
    static let shared = ChatService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Chat Models
    struct SessionCreateRequest: Codable {
        let title: String
    }
    
    struct SessionResponse: Codable {
        let session_id: String
        let user_id: String
        let title: String
        let start_time: String
        let end_time: String?
        let summary_text: String?
    }
    
    struct MessageResponse: Codable {
        let message_id: String
        let content: String
        let sender: String
        let timestamp: String
    }
    
    struct ChatRequest: Codable {
        let session_id: String?
        let message: String
        let model: String?
    }
    
    struct ChatResponse: Codable {
        let session_id: String
        let message: MessageResponse
        let ai_response: MessageResponse
    }
    
    // MARK: - Session Methods
    
    /// Create a new chat session
    func createSession(title: String) async throws -> SessionResponse {
        let request = SessionCreateRequest(title: title)
        return try await apiService.post(path: "/sessions/", body: request)
    }
    
    /// Get all sessions for current user
    func getSessions() async throws -> [SessionResponse] {
        return try await apiService.get(path: "/sessions/")
    }
    
    /// Get a specific session
    func getSession(id: String) async throws -> SessionResponse {
        return try await apiService.get(path: "/sessions/\(id)")
    }
    
    /// Delete a session
    func deleteSession(id: String) async throws -> Void {
        let _: [String: String] = try await apiService.delete(path: "/sessions/\(id)")
    }
    
    // MARK: - Message Methods
    
    /// Send a message and get AI response
    func sendMessage(sessionId: String?, message: String, model: String? = nil) async throws -> ChatResponse {
        print("DEBUG: ChatService - Sending message to API. SessionID: \(sessionId ?? "nil"), Message: \(message)")
        
        let request = ChatRequest(
            session_id: sessionId,
            message: message,
            model: model
        )
        
        do {
            let response: ChatResponse = try await apiService.post(path: "/chat/message", body: request)
            print("DEBUG: ChatService - Received response from API:")
            print("DEBUG: ChatService - Session ID: \(response.session_id)")
            print("DEBUG: ChatService - User message ID: \(response.message.message_id)")
            print("DEBUG: ChatService - AI response ID: \(response.ai_response.message_id)")
            print("DEBUG: ChatService - AI response content: \(response.ai_response.content.prefix(50))...")
            print("DEBUG: ChatService - AI response sender: \(response.ai_response.sender)")
            return response
        } catch {
            print("ERROR: ChatService - Failed to send message: \(error)")
            throw error
        }
    }
    
    /// Get all messages for a session
    func getMessages(sessionId: String) async throws -> [MessageResponse] {
        return try await apiService.get(path: "/chat/messages/\(sessionId)")
    }
} 