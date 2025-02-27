import Foundation

class AuthService {
    static let shared = AuthService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Authentication Models
    struct LoginRequest: Codable {
        let username: String
        let password: String
    }
    
    struct RegistrationRequest: Codable {
        let username: String
        let email: String
        let password: String
    }
    
    struct TokenResponse: Codable {
        let access_token: String
        let token_type: String
    }
    
    struct UserResponse: Codable {
        let username: String
        let email: String
        let user_id: String
        let created_at: String
        let is_active: Bool
    }
    
    // MARK: - Authentication Methods
    
    /// Login user and get JWT token
    func login(username: String, password: String) async throws -> TokenResponse {
        let loginRequest = LoginRequest(username: username, password: password)
        let response: TokenResponse = try await apiService.post(path: "/users/login", body: loginRequest)
        
        // Store token
        Configuration.setJWTToken(response.access_token)
        
        return response
    }
    
    /// Register a new user
    func register(username: String, email: String, password: String) async throws -> UserResponse {
        let registrationRequest = RegistrationRequest(username: username, email: email, password: password)
        return try await apiService.post(path: "/users/register", body: registrationRequest)
    }
    
    /// Get current user information
    func getCurrentUser() async throws -> UserResponse {
        guard Configuration.isLoggedIn else {
            throw APIError.unauthorized
        }
        
        return try await apiService.get(path: "/users/me")
    }
    
    /// Logout user
    func logout() {
        Configuration.setJWTToken(nil)
    }
    
    /// Check if token is valid
    func validateToken() async -> Bool {
        guard Configuration.isLoggedIn else {
            return false
        }
        
        do {
            _ = try await getCurrentUser()
            return true
        } catch {
            // Token is invalid, clear it
            Configuration.setJWTToken(nil)
            return false
        }
    }
} 