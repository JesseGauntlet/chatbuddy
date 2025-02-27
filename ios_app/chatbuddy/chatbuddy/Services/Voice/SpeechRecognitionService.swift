import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: NSObject, SFSpeechRecognizerDelegate {
    static let shared = SpeechRecognitionService()
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Status tracking
    private(set) var isRecording = false
    
    // Callback for transcription updates
    var onTranscription: ((String) -> Void)?
    
    // Callback for recognition completion
    var onRecognitionComplete: ((Result<String, Error>) -> Void)?
    
    // Current transcription text
    private(set) var currentTranscription: String = ""
    
    override init() {
        // Use the device locale for speech recognition
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        speechRecognizer?.delegate = self
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            print("Speech recognition not available")
        }
    }
    
    // MARK: - Permission Handling
    
    enum SpeechRecognitionError: Error {
        case notAuthorized
        case noMicrophoneAccess
        case recognizerNotAvailable
        case audioEngineError
        case recognitionCancelled
        case recognitionFailed(Error)
        
        var localizedDescription: String {
            switch self {
            case .notAuthorized:
                return "Speech recognition not authorized"
            case .noMicrophoneAccess:
                return "Microphone access not granted"
            case .recognizerNotAvailable:
                return "Speech recognizer is not available"
            case .audioEngineError:
                return "Audio engine error"
            case .recognitionCancelled:
                return "Recognition was cancelled"
            case .recognitionFailed(let error):
                return "Recognition failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume(returning: true)
                default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    /// Check if speech recognition is authorized
    var isAuthorized: Bool {
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    // MARK: - Recording Methods
    
    /// Start speech recognition
    func startRecording() async throws {
        // Check authorization
        guard isAuthorized else {
            throw SpeechRecognitionError.notAuthorized
        }
        
        // Check recognizer
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }
        
        // Check if already recording
        if isRecording {
            stopRecording()
        }
        
        // Set up audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechRecognitionError.audioEngineError
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Configure request
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognitionFailed(NSError(domain: "SpeechRecognition", code: -1, userInfo: nil))
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
        } catch {
            throw SpeechRecognitionError.audioEngineError
        }
        
        // Start recognition task
        currentTranscription = ""
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                self.currentTranscription = result.bestTranscription.formattedString
                self.onTranscription?(self.currentTranscription)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.isRecording = false
                
                if let error = error {
                    if let nserror = error as NSError?, nserror.domain == "kAFAssistantErrorDomain" && nserror.code == 216 {
                        // This is a cancellation error, which is normal when we stop recording
                        self.onRecognitionComplete?(.success(self.currentTranscription))
                    } else {
                        self.onRecognitionComplete?(.failure(SpeechRecognitionError.recognitionFailed(error)))
                    }
                } else {
                    self.onRecognitionComplete?(.success(self.currentTranscription))
                }
            }
        }
        
        isRecording = true
    }
    
    /// Stop speech recognition
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        // Note: The completion handler in recognitionTask will clean up resources
    }
} 