import Foundation

// MARK: - User Model

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case email
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Session Model

struct ChatSession: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let startTime: Date
    let endTime: Date?
    let summaryText: String?
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case userId = "user_id"
        case title
        case startTime = "start_time"
        case endTime = "end_time"
        case summaryText = "summary_text"
    }
}

// MARK: - Message Model

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let sender: MessageSender
    let timestamp: Date
    
    // For previews and testing
    static func preview(content: String, sender: MessageSender = .user) -> Message {
        return Message(
            id: UUID().uuidString,
            content: content,
            sender: sender,
            timestamp: Date()
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case content
        case sender
        case timestamp
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

enum MessageSender: String, Codable {
    case user
    case ai
    case system
    
    // Handle potential case variations from the API
    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "user":
            self = .user
        case "ai", "assistant", "bot":
            self = .ai
        case "system":
            self = .system
        default:
            print("WARNING: Unknown message sender type: \(rawValue)")
            return nil
        }
    }
    
    var isUser: Bool {
        return self == .user
    }
    
    var isAI: Bool {
        return self == .ai
    }
}

// MARK: - API Request/Response Models

struct LoginCredentials {
    let username: String
    let password: String
}

struct RegisterCredentials {
    let username: String
    let email: String
    let password: String
}

// MARK: - Date Handling

extension JSONDecoder {
    static var chatBuddyDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
}

extension JSONEncoder {
    static var chatBuddyEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }
} 