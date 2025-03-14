import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage = ""
    @State private var scrollToBottom = false
    @Environment(\.presentationMode) var presentationMode
    
    // Optional parameters - if not provided, a default session will be used
    var sessionId: String?
    var title: String?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                navigationBar
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.messages) { message in
                                VStack(alignment: message.sender.isUser ? .trailing : .leading) {
                                    MessageBubble(message: message)
                                    MessageTimestamp(date: message.timestamp)
                                }
                                .id(message.id)
                                .onAppear {
                                    print("DEBUG: Displaying message: \(message.id) from \(message.sender.rawValue)")
                                }
                            }
                            
                            // Scroll anchor
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.top)
                    }
                    .onChange(of: viewModel.messages.count) { oldCount, newCount in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: scrollToBottom) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Input bar
                HStack(alignment: .center, spacing: 10) {
                    // Text input
                    TextField("Type a message", text: $viewModel.inputText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .disabled(viewModel.isProcessing)
                    
                    // Send button
                    if !viewModel.inputText.isEmpty {
                        Button {
                            Task {
                                await viewModel.sendMessage()
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isProcessing)
                    } else {
                        // Voice record button
                        ZStack {
                            RecordButton(isRecording: viewModel.isRecording) {
                                if viewModel.isRecording {
                                    viewModel.stopRecording()
                                } else {
                                    Task {
                                        await viewModel.startRecording()
                                    }
                                }
                            }
                            
                            if viewModel.isRecording {
                                PulseAnimation()
                            }
                        }
                    }
                }
                .padding(10)
                
                // Transcription preview (when recording)
                if viewModel.isRecording && !viewModel.transcribedText.isEmpty {
                    HStack {
                        Text(viewModel.transcribedText)
                            .font(.footnote)
                            .padding(.horizontal)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        RecordingIndicator()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom))
                }
                
                // Processing indicator
                if viewModel.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Spacer()
                    }
                    .background(Color(.systemGray6).opacity(0.5))
                    .transition(.opacity)
                }
            }
            
            // Playback indicator
            if viewModel.isPlaying {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            viewModel.stopPlayback()
                        } label: {
                            HStack {
                                Text("Playing...")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Capsule().fill(Color.blue))
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 90)
                }
            }
        }
        .onAppear {
            initializeChat()
        }
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.errorMessage != nil ? AlertItem(message: viewModel.errorMessage!) : nil },
            set: { _ in viewModel.errorMessage = nil }
        )) { alert in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Initialize chat based on whether sessionId was provided
    private func initializeChat() {
        print("DEBUG: ChatView - Initializing chat. SessionID: \(sessionId ?? "nil"), Title: \(title ?? "nil")")
        
        Task {
            if let sessionId = sessionId {
                // Load existing session if ID was provided
                print("DEBUG: ChatView - Loading existing session: \(sessionId)")
                await viewModel.loadSession(id: sessionId)
                
                // Set scroll flag after loading with a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollToBottom = true
                }
            } else {
                // Check for default session or create a new one when opened directly
                let defaultTitle = title ?? "Main Chat"
                print("DEBUG: ChatView - Creating new session with title: \(defaultTitle)")
                await viewModel.createSession(title: defaultTitle)
            }
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Only show back button when presented as a sheet/navigation push
            if sessionId != nil {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .padding()
                }
            } else {
                // Empty space for alignment
                Color.clear
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(viewModel.currentSession?.title ?? "Chat")
                .font(.headline)
            
            Spacer()
            
            // Debug button
            if Configuration.debugMode {
                Button {
                    print("Latency: \(viewModel.lastResponseTime)")
                } label: {
                    Image(systemName: "clock")
                        .font(.title3)
                        .padding()
                }
            } else {
                // Empty view for balance
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
}

// MARK: - Alert Item
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
} 