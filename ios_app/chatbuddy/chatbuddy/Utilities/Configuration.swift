import Foundation

/// Application configuration
class Configuration {
    // MARK: - API Configuration
    
    /// Base URL for the backend API
    static let baseURL = "http://localhost:8000/api"
    
    /// Health check URL to verify server is running
    static let healthCheckURL = "http://localhost:8000/"
    
    // For development/debugging on a real device
    static func developmentAPIBaseURL() -> String {
        #if DEBUG
        // When connected via USB with port forwarding, use localhost
        // When on same network, use the Mac's IP address
        return "http://localhost:8000/api"
        #else
        return baseURL
        #endif
    }
    
    // For development/debugging on a real device
    static func developmentHealthCheckURL() -> String {
        #if DEBUG
        // When connected via USB with port forwarding, use localhost
        // When on same network, use the Mac's IP address
        return "http://localhost:8000/"
        #else
        return healthCheckURL
        #endif
    }
    
    // MARK: - LLM Configuration
    
    /// Default LLM model to use
    static let defaultLLMModel = "gpt-3.5-turbo"
    
    // MARK: - Voice Configuration
    
    /// ElevenLabs API key
    /// Store this securely in a production app - consider using Keychain
    static var elevenLabsAPIKey: String {
        // In a real app, you would retrieve this from secure storage
        return UserDefaults.standard.string(forKey: "elevenlabs_api_key") ?? ""
    }
    
    /// Set ElevenLabs API key
    static func setElevenLabsAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "elevenlabs_api_key")
    }
    
    /// ElevenLabs API base URL
    static let elevenLabsBaseURL = "https://api.elevenlabs.io/v1"
    
    /// Default voice ID for ElevenLabs
    static var elevenLabsVoiceID: String {
        return UserDefaults.standard.string(forKey: "elevenlabs_voice_id") ?? "21m00Tcm4TlvDq8ikWAM" // Default voice
    }
    
    /// Set ElevenLabs voice ID
    static func setElevenLabsVoiceID(_ voiceID: String) {
        UserDefaults.standard.set(voiceID, forKey: "elevenlabs_voice_id")
    }
    
    // MARK: - Debug Settings
    
    /// Debug mode for development
    static var debugMode: Bool {
        return UserDefaults.standard.bool(forKey: "debug_mode")
    }
    
    /// Set debug mode
    static func setDebugMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "debug_mode")
    }
    
    // MARK: - JWT Authentication
    
    /// Get stored JWT token
    static var jwtToken: String? {
        return UserDefaults.standard.string(forKey: "jwt_token")
    }
    
    /// Set JWT token
    static func setJWTToken(_ token: String?) {
        if let token = token {
            UserDefaults.standard.set(token, forKey: "jwt_token")
        } else {
            UserDefaults.standard.removeObject(forKey: "jwt_token")
        }
    }
    
    /// Check if user is logged in
    static var isLoggedIn: Bool {
        return jwtToken != nil
    }
    
    // MARK: - User Settings
    
    /// Voice input enabled
    static var voiceInputEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "voice_input_enabled")
    }
    
    /// Set voice input enabled
    static func setVoiceInputEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "voice_input_enabled")
    }
    
    /// Voice output enabled
    static var voiceOutputEnabled: Bool {
        get {
            // Default to true if not set
            return UserDefaults.standard.object(forKey: "voice_output_enabled") as? Bool ?? true
        }
    }
    
    /// Set voice output enabled
    static func setVoiceOutputEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "voice_output_enabled")
    }
} 