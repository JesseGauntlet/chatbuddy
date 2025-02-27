import Foundation
import AVFoundation

class ElevenLabsService {
    static let shared = ElevenLabsService()
    
    private let baseURL = Configuration.elevenLabsBaseURL
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Audio Session
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Voice Models
    
    struct Voice: Codable, Identifiable {
        let voice_id: String
        let name: String
        let preview_url: String?
        let category: String?
        
        var id: String { voice_id }
    }
    
    struct VoiceSettings: Codable {
        let stability: Float
        let similarity_boost: Float
        let style: Float?
        let use_speaker_boost: Bool?
    }
    
    struct TextToSpeechRequest: Codable {
        let text: String
        let model_id: String
        let voice_settings: VoiceSettings
    }
    
    // MARK: - Voice Methods
    
    /// Get available voices
    func getVoices() async throws -> [Voice] {
        let endpoint = "\(baseURL)/voices"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("\(Configuration.elevenLabsAPIKey)", forHTTPHeaderField: "xi-api-key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw APIError.invalidResponse
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            let voicesResponse = try decoder.decode([String: [Voice]].self, from: data)
            
            if let voices = voicesResponse["voices"] {
                return voices
            } else {
                return []
            }
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    /// Convert text to speech and play
    func speakText(_ text: String, voiceId: String? = nil) async throws {
        let voiceToUse = voiceId ?? Configuration.elevenLabsVoiceID
        
        let endpoint = "\(baseURL)/text-to-speech/\(voiceToUse)"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("\(Configuration.elevenLabsAPIKey)", forHTTPHeaderField: "xi-api-key")
        
        // Default voice settings
        let voiceSettings = VoiceSettings(
            stability: 0.5,
            similarity_boost: 0.75,
            style: 0.0,
            use_speaker_boost: true
        )
        
        let requestBody = TextToSpeechRequest(
            text: text,
            model_id: "eleven_monolingual_v1",
            voice_settings: voiceSettings
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                // Try to parse error message
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = errorJson["detail"] as? String {
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: detail)
                } else {
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Unknown error")
                }
            }
            
            // Play the audio data
            try playAudioData(data)
        } catch {
            throw error
        }
    }
    
    /// Play audio data
    private func playAudioData(_ data: Data) throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error)")
            throw error
        }
    }
    
    /// Stop current playback
    func stopPlayback() {
        audioPlayer?.stop()
    }
} 