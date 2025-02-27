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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat sessions tab
            SessionsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            
            // New chat tab
            ChatView()
                .tabItem {
                    Label("New Chat", systemImage: "plus.circle")
                }
                .tag(1)
            
            // Settings tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
} 