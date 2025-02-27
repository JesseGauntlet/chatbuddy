import SwiftUI

@main
struct ChatBuddyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(authViewModel)
        }
    }
}

struct MainContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showLogin = false
    
    var body: some View {
        Group {
            if !showLogin {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            // Initialize state based on current auth status
            showLogin = !authViewModel.isAuthenticated
        }
        .onChange(of: authViewModel.isAuthenticated) { _, newValue in
            // Update view when auth status changes
            showLogin = !newValue
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var sessionsViewModel = SessionsViewModel()
    @State private var defaultSessionId: String? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main chat tab - always creates or shows a default chat
            ChatView(sessionId: defaultSessionId, title: "Main Chat")
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.text.bubble.right")
                }
                .tag(0)
            
            // All chats/sessions tab - inject the shared view model
            SessionsView(injectedViewModel: sessionsViewModel)
                .environmentObject(authViewModel)
                .tabItem {
                    Label("All Chats", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Settings tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .onAppear {
            // Load sessions once when tab view appears
            Task {
                await sessionsViewModel.fetchSessions()
                
                // Set the default session ID to the first session if available
                if !sessionsViewModel.sessions.isEmpty {
                    defaultSessionId = sessionsViewModel.sessions.first?.id
                }
            }
        }
        // Observe the defaultSessionId from the view model instead of the sessions array
        .onChange(of: sessionsViewModel.defaultSessionId) { _, newValue in
            if newValue != nil && defaultSessionId == nil {
                defaultSessionId = newValue
            }
        }
    }
} 