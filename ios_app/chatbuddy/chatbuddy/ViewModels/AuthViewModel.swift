import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    private let authService = AuthService.shared
    
    init() {
        // Use Task to avoid state modification during initialization
        Task {
            checkAuthStatus()
        }
    }
    
    /// Check if user is already authenticated
    func checkAuthStatus() {
        isAuthenticated = Configuration.isLoggedIn
        
        if isAuthenticated {
            loadUserProfile()
        }
    }
    
    /// Load user profile
    func loadUserProfile() {
        Task {
            do {
                isLoading = true
                let userResponse = try await authService.getCurrentUser()
                
                // Convert API response to our model
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                
                if let date = dateFormatter.date(from: userResponse.created_at) {
                    self.currentUser = User(
                        id: userResponse.user_id,
                        username: userResponse.username,
                        email: userResponse.email,
                        isActive: userResponse.is_active,
                        createdAt: date
                    )
                }
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load user profile: \(error.localizedDescription)"
                print("Error loading profile: \(error)")
            }
        }
    }
    
    /// Login with username and password
    func login(username: String, password: String) async -> Bool {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and password cannot be empty"
            return false
        }
        
        do {
            isLoading = true
            errorMessage = nil
            
            _ = try await authService.login(username: username, password: password)
            
            isAuthenticated = true
            loadUserProfile()
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            
            if let apiError = error as? APIError {
                errorMessage = apiError.description
            } else {
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
            
            print("Login error: \(error)")
            return false
        }
    }
    
    /// Register a new user
    func register(username: String, email: String, password: String) async -> Bool {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required"
            return false
        }
        
        // Simple email validation
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        // Password length check
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        do {
            isLoading = true
            errorMessage = nil
            
            _ = try await authService.register(username: username, email: email, password: password)
            
            // Auto-login after registration
            return await login(username: username, password: password)
        } catch {
            isLoading = false
            
            if let apiError = error as? APIError {
                errorMessage = apiError.description
            } else {
                errorMessage = "Registration failed: \(error.localizedDescription)"
            }
            
            print("Registration error: \(error)")
            return false
        }
    }
    
    /// Logout user
    func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
    }
} 