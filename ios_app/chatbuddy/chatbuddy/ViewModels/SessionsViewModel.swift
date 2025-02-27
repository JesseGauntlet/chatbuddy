import Foundation

@MainActor
class SessionsViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let chatService = ChatService.shared
    
    init() {
        loadSessions()
    }
    
    /// Load all chat sessions
    func loadSessions() {
        Task {
            await fetchSessions()
        }
    }
    
    /// Fetch sessions from the API
    func fetchSessions() async {
        do {
            isLoading = true
            errorMessage = nil
            
            let sessionsResponse = try await chatService.getSessions()
            
            // Convert to our model
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            
            sessions = sessionsResponse.compactMap { session in
                if let startDate = dateFormatter.date(from: session.start_time),
                   let endDate = session.end_time != nil ? dateFormatter.date(from: session.end_time!) : nil {
                    
                    return ChatSession(
                        id: session.session_id,
                        userId: session.user_id,
                        title: session.title,
                        startTime: startDate,
                        endTime: endDate,
                        summaryText: session.summary_text
                    )
                }
                return nil
            }
            
            // Sort by start time (newest first)
            sessions.sort { $0.startTime > $1.startTime }
            
            isLoading = false
        } catch {
            isLoading = false
            
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            print("Session loading error: \(error)")
        }
    }
    
    /// Create a new session
    func createSession(title: String) async -> ChatSession? {
        do {
            isLoading = true
            errorMessage = nil
            
            let sessionResponse = try await chatService.createSession(title: title)
            
            // Convert to our model
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            
            if let startDate = dateFormatter.date(from: sessionResponse.start_time),
               let endDate = sessionResponse.end_time != nil ? dateFormatter.date(from: sessionResponse.end_time!) : nil {
                
                let newSession = ChatSession(
                    id: sessionResponse.session_id,
                    userId: sessionResponse.user_id,
                    title: sessionResponse.title,
                    startTime: startDate,
                    endTime: endDate,
                    summaryText: sessionResponse.summary_text
                )
                
                // Add to sessions and sort
                sessions.append(newSession)
                sessions.sort { $0.startTime > $1.startTime }
                
                isLoading = false
                return newSession
            }
            
            isLoading = false
            return nil
        } catch {
            isLoading = false
            
            errorMessage = "Failed to create session: \(error.localizedDescription)"
            print("Session creation error: \(error)")
            return nil
        }
    }
    
    /// Delete a session
    func deleteSession(at indexSet: IndexSet) {
        Task {
            for index in indexSet {
                let session = sessions[index]
                do {
                    try await chatService.deleteSession(id: session.id)
                    sessions.remove(at: index)
                } catch {
                    errorMessage = "Failed to delete session: \(error.localizedDescription)"
                    print("Session deletion error: \(error)")
                }
            }
        }
    }
    
    /// Delete a specific session by ID
    func deleteSession(id: String) async -> Bool {
        do {
            try await chatService.deleteSession(id: id)
            sessions = sessions.filter { $0.id != id }
            return true
        } catch {
            errorMessage = "Failed to delete session: \(error.localizedDescription)"
            print("Session deletion error: \(error)")
            return false
        }
    }
} 