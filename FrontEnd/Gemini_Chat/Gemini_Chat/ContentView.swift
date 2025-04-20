import SwiftUI

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isLoading: Bool = false
}

struct ContentView: View {
    @State private var userQuery: String = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    
    @State private var scrollViewID = UUID()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                view_MessageScrollBar
                
                // Input area
                view_InputArea
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("new", systemImage: "plus.circle.fill") {
                        newConversation()
                    }
                }
            }
        }
    }
    
    // MARK: - Message Area
    private var view_MessageScrollBar: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        if message.isLoading {
                            HStack {
                                LoadingAnimation()
                                    .id(message.id)
                                Spacer()
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading),
                                removal: .opacity))
                        } else {
                            MessageBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: message.isUser ? .trailing : .leading),
                                    removal: .opacity
                                ))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .onChange(of: messages) {
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
        }
        .id(scrollViewID)
    }
    
    // MARK: - Input Area
    private var view_InputArea: some View {
        HStack {
            textField_UserMessageArea
            button_SendQuery
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var textField_UserMessageArea: some View {
        TextField("Type a message...", text: $userQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.leading)
    }
    
    private var button_SendQuery: some View {
        Button {
            Task {
                await sendQueryToGemini()
            }
        } label: {
            Image(systemName: "paperplane.fill")
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
        .disabled(userQuery.isEmpty || isLoading)
        .padding(.trailing)
    }
    
    
    
    
    // MARK: - Loading Animation View
    
    
    // MARK: - Network Functions
    @MainActor
    func sendQueryToGemini() async {
        guard !userQuery.isEmpty else { return }
        
        // Add user message with animation
        let userMessage = Message(content: userQuery, isUser: true, timestamp: Date())
        withAnimation(.spring()) {
            messages.append(userMessage)
        }
        
        // Add loading placeholder with animation
        let loadingMessage = Message(
            content: "",
            isUser: false,
            timestamp: Date(),
            isLoading: true
        )
        
        withAnimation(.spring()) {
            messages.append(loadingMessage)
        }
        
        isLoading = true
        userQuery = ""
        
        // Prepare and send request
        do {
            guard let url = URL(string: "http://127.0.0.1:8000/model_response") else {
                throw URLError(.badURL)
            }
            
            let payload = ["user_query": userMessage.content]
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(ServerResponse.self, from: data)
            
            updateLoadingMessage(with: decoded.response)
        } catch {
            updateLoadingMessage(with: "Error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func updateLoadingMessage(with content: String) {
        guard let lastIndex = messages.indices.last, messages[lastIndex].isLoading else { return }
        
        withAnimation(.spring()) {
            messages[lastIndex] = Message(
                content: content,
                isUser: false,
                timestamp: Date(),
                isLoading: false
            )
        }
    }
    
    @MainActor
    private func newConversation() {
        // Clear messages with animation
        withAnimation(.spring()) {
            messages.removeAll()
            scrollViewID = UUID()
        }

        Task {
            await instantiateNewConversationOnServer()
        }
    }
    
    @MainActor
    private func instantiateNewConversationOnServer() async {
        isLoading = true
        
        do {
            guard let url = URL(string: "http://127.0.0.1:8000/instantiate") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("New conversation started")
            }
        } catch {
            print("Error starting new conversation: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

struct ServerResponse: Decodable {
    let response: String
}


#Preview {
    ContentView()
}
