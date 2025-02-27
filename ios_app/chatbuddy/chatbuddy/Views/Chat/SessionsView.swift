import SwiftUI

struct SessionsView: View {
    @StateObject private var viewModel = SessionsViewModel()
    @State private var showingNewSessionAlert = false
    @State private var newSessionTitle = ""
    @State private var selectedSession: ChatSession?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading sessions...")
                        .padding()
                } else if viewModel.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("ChatBuddy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewSessionAlert = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                    }
                }
            }
            .alert("New Conversation", isPresented: $showingNewSessionAlert) {
                TextField("Title", text: $newSessionTitle)
                Button("Cancel", role: .cancel) {
                    newSessionTitle = ""
                }
                Button("Create") {
                    createNewSession()
                }
            } message: {
                Text("Enter a title for your new conversation")
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .onAppear {
                viewModel.loadSessions()
            }
            .refreshable {
                await refreshSessions()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start a new conversation to chat with AI")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                showingNewSessionAlert = true
            } label: {
                Text("Start New Conversation")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
    
    private var sessionsList: some View {
        List {
            ForEach(viewModel.sessions) { session in
                NavigationLink(destination: ChatView(sessionId: session.id, title: session.title)) {
                    sessionRow(session)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        selectedSession = session
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .confirmationDialog(
                "Delete Conversation",
                isPresented: $showingDeleteConfirmation,
                presenting: selectedSession
            ) { session in
                Button("Delete", role: .destructive) {
                    deleteSession(session)
                }
            } message: { session in
                Text("Are you sure you want to delete \"\(session.title)\"? This action cannot be undone.")
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func sessionRow(_ session: ChatSession) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(session.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(session.formattedStartTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func createNewSession() {
        let title = newSessionTitle.isEmpty ? "New Conversation" : newSessionTitle
        
        Task {
            if let session = await viewModel.createSession(title: title) {
                selectedSession = session
                newSessionTitle = ""
            }
        }
    }
    
    private func deleteSession(_ session: ChatSession) {
        Task {
            _ = await viewModel.deleteSession(id: session.id)
        }
    }
    
    private func refreshSessions() async {
        await viewModel.fetchSessions()
    }
}

struct SessionsView_Previews: PreviewProvider {
    static var previews: some View {
        SessionsView()
    }
} 