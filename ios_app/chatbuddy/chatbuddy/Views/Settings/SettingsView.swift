import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // Account section
                Section(header: Text("Account")) {
                    if let user = authViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    } else {
                        Text("Loading...")
                    }
                }
                
                // Voice settings
                Section(header: Text("Voice Settings")) {
                    Toggle("Voice Input", isOn: $viewModel.voiceInputEnabled)
                    Toggle("Voice Output", isOn: $viewModel.voiceOutputEnabled)
                    
                    if viewModel.voiceOutputEnabled {
                        NavigationLink(destination: VoiceSettingsView()) {
                            Text("Voice Selection")
                        }
                        
                        Button("Test Voice") {
                            viewModel.testCurrentVoice()
                        }
                        .disabled(viewModel.elevenLabsAPIKey.isEmpty)
                    }
                }
                
                // ElevenLabs configuration
                Section(header: Text("ElevenLabs Configuration")) {
                    SecureField("API Key", text: $viewModel.elevenLabsAPIKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !viewModel.elevenLabsAPIKey.isEmpty {
                        Button("Save and Verify") {
                            viewModel.loadVoices()
                        }
                    }
                    
                    if viewModel.isLoadingVoices {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                    
                    if let error = viewModel.voicesError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                
                // API Status
                Section(header: Text("API Status")) {
                    HStack {
                        Text("Backend")
                        Spacer()
                        if viewModel.isCheckingStatus {
                            ProgressView()
                        } else {
                            Image(systemName: viewModel.backendStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.backendStatus ? .green : .red)
                        }
                    }
                    
                    HStack {
                        Text("ElevenLabs")
                        Spacer()
                        if viewModel.isCheckingStatus {
                            ProgressView()
                        } else {
                            Image(systemName: viewModel.elevenLabsStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.elevenLabsStatus ? .green : .red)
                        }
                    }
                    
                    Button("Check Status") {
                        viewModel.checkServiceStatus()
                    }
                }
                
                // Debug settings
                Section(header: Text("Debug Settings")) {
                    Toggle("Debug Mode", isOn: $viewModel.debugMode)
                    
                    Button(role: .destructive) {
                        viewModel.resetSettings()
                    } label: {
                        Text("Reset All Settings")
                    }
                }
                
                // App info
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Always visible logout section
                Section {
                    Button(role: .destructive) {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .confirmationDialog(
                        "Sign Out",
                        isPresented: $showingLogoutConfirmation
                    ) {
                        Button("Sign Out", role: .destructive) {
                            authViewModel.logout()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to sign out?")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct VoiceSettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Available Voices")) {
                if viewModel.isLoadingVoices {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if viewModel.availableVoices.isEmpty {
                    if let error = viewModel.voicesError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Text("No voices available. Please check your API key.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    ForEach(viewModel.availableVoices) { voice in
                        Button {
                            viewModel.selectedVoiceId = voice.voice_id
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(voice.name)
                                        .foregroundColor(.primary)
                                    
                                    if let category = voice.category {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if viewModel.selectedVoiceId == voice.voice_id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Test Selected Voice") {
                    viewModel.testCurrentVoice()
                }
            }
        }
        .navigationTitle("Voice Selection")
        .onAppear {
            if !viewModel.elevenLabsAPIKey.isEmpty {
                viewModel.loadVoices()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
} 