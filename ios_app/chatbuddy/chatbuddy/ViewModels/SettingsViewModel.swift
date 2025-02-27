import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    // Voice settings
    @Published var voiceInputEnabled: Bool {
        didSet {
            Configuration.setVoiceInputEnabled(voiceInputEnabled)
        }
    }
    
    @Published var voiceOutputEnabled: Bool {
        didSet {
            Configuration.setVoiceOutputEnabled(voiceOutputEnabled)
        }
    }
    
    // ElevenLabs settings
    @Published var elevenLabsAPIKey: String {
        didSet {
            Configuration.setElevenLabsAPIKey(elevenLabsAPIKey)
        }
    }
    
    @Published var selectedVoiceId: String {
        didSet {
            Configuration.setElevenLabsVoiceID(selectedVoiceId)
        }
    }
    
    // Available voices
    @Published var availableVoices: [ElevenLabsService.Voice] = []
    @Published var isLoadingVoices: Bool = false
    @Published var voicesError: String?
    
    // Debug settings
    @Published var debugMode: Bool {
        didSet {
            Configuration.setDebugMode(debugMode)
        }
    }
    
    // Status
    @Published var elevenLabsStatus: Bool = false
    @Published var backendStatus: Bool = false
    @Published var isCheckingStatus: Bool = false
    
    private let elevenLabsService = ElevenLabsService.shared
    private let apiService = APIService.shared
    
    init() {
        // Load settings from UserDefaults
        voiceInputEnabled = Configuration.voiceInputEnabled
        voiceOutputEnabled = Configuration.voiceOutputEnabled
        elevenLabsAPIKey = Configuration.elevenLabsAPIKey
        selectedVoiceId = Configuration.elevenLabsVoiceID
        debugMode = Configuration.debugMode
        
        // Load voices if API key is set
        if !elevenLabsAPIKey.isEmpty {
            loadVoices()
        }
        
        // Check status of services
        checkServiceStatus()
    }
    
    // MARK: - Voice Management
    
    /// Load available voices from ElevenLabs
    func loadVoices() {
        guard !elevenLabsAPIKey.isEmpty else {
            voicesError = "API key is required to load voices"
            return
        }
        
        isLoadingVoices = true
        voicesError = nil
        
        Task {
            do {
                availableVoices = try await elevenLabsService.getVoices()
                isLoadingVoices = false
                
                // Update status
                elevenLabsStatus = true
            } catch {
                isLoadingVoices = false
                voicesError = "Failed to load voices: \(error.localizedDescription)"
                print("Voice loading error: \(error)")
                
                // Update status
                elevenLabsStatus = false
            }
        }
    }
    
    /// Test the currently selected voice
    func testCurrentVoice() {
        Task {
            do {
                try await elevenLabsService.speakText("Hello, this is a test of the ElevenLabs voice synthesis.")
            } catch {
                voicesError = "Failed to test voice: \(error.localizedDescription)"
                print("Voice test error: \(error)")
            }
        }
    }
    
    // MARK: - Status Checks
    
    /// Check the status of backend and ElevenLabs
    func checkServiceStatus() {
        isCheckingStatus = true
        
        Task {
            // Check backend
            do {
                backendStatus = try await apiService.checkServerHealth()
            } catch {
                backendStatus = false
                print("Backend status check error: \(error)")
            }
            
            // Check ElevenLabs if API key is set
            if !elevenLabsAPIKey.isEmpty {
                do {
                    _ = try await elevenLabsService.getVoices()
                    elevenLabsStatus = true
                } catch {
                    elevenLabsStatus = false
                    print("ElevenLabs status check error: \(error)")
                }
            } else {
                elevenLabsStatus = false
            }
            
            isCheckingStatus = false
        }
    }
    
    /// Reset all settings to defaults
    func resetSettings() {
        voiceInputEnabled = false
        voiceOutputEnabled = true
        elevenLabsAPIKey = ""
        selectedVoiceId = "21m00Tcm4TlvDq8ikWAM"  // Default voice
        debugMode = false
    }
} 