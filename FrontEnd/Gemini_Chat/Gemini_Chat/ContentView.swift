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
    
    @State private var conversations: [String] = []
    @State private var selectedConversation: String? = nil
    @State private var showSidebar = false
    
    @State private var scrollViewID = UUID()
    
    var body: some View {
        ZStack {
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
                        button_NewConversation
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        button_ConversationHistory
                    }
                }
            }
            .onChange(of: selectedConversation) {
                Task {
                    await loadSelectedConversation()
                }
            }
            
            ChatHistorySidebar(
                conversations: $conversations,
                isShowing: $showSidebar,
                selectedConversation: $selectedConversation
            )
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
                    // Add an empty view at the bottom to ensure scrolling works
                    Color.clear.frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .onChange(of: messages.count) {
                // Use a slight delay to ensure the view has updated
                DispatchQueue.main.async {
                    withAnimation {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        } else {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
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
    
    //MARK: - BUTTONS
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
    
    private var button_ConversationHistory: some View {
        Button(action: {
            Task {
                await ConversationListHistory()
            }
            showSidebar.toggle()
        }) {
            Image(systemName: "line.3.horizontal")
        }
    }
    
    private var button_NewConversation: some View {
        Button("new", systemImage: "plus.circle.fill") {
            newConversation()
        }
    }
    
    
    
    
    
    
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
    
    private func newConversation() {
        // Clear messages with animation
        withAnimation(.spring()) {
            messages.removeAll()
            scrollViewID = UUID()
            selectedConversation = nil
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
    
    @MainActor
    private func ConversationListHistory() async {
        
        do {
            guard let url = URL(string: "http://127.0.0.1:8000/list_conversations") else {
                throw URLError(.badURL)
            }
            
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let responses = try JSONDecoder().decode(ServerResponse_History.self, from: data)
                for file in responses.files {
                    print(file)
                }
                conversations = responses.files
                            
                
            }
            
            
            
        } catch {
            print(error)
        }
    }
    
    @MainActor
    private func loadSelectedConversation() async {
        guard let selectedConversation = selectedConversation else { return }
        
        isLoading = true
        
        do {
            guard let url = URL(string: "http://127.0.0.1:8000/load_conversation") else {
                throw URLError(.badURL)
            }
            
            // Create proper JSON payload
            let payload: [String: Any] = ["file": selectedConversation]
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let errorData = try JSONDecoder().decode([String: String].self, from: data)
                    throw NSError(domain: "", code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: errorData["detail"] ?? "Unknown error"])
                }
            }
            
            let decoded = try JSONDecoder().decode(ServerResponse_Conversation.self, from: data)
            
            // Clear current messages
            withAnimation {
                messages.removeAll()
            }
            
            // Convert server messages to local Message format
            var newMessages: [Message] = []
            for serverMessage in decoded.messages {
                let isUser = serverMessage.type == "HumanMessage"
                let message = Message(
                    content: serverMessage.content,
                    isUser: isUser,
                    timestamp: Date(),
                    isLoading: false
                )
                newMessages.append(message)
            }
            
            withAnimation {
                messages = newMessages
            }
        } catch {
            print("Error loading conversation: \(error.localizedDescription)")
            
        }
        
        isLoading = false
    }
    
}

struct ServerResponse: Decodable {
    let response: String
}

struct ServerResponse_History: Decodable {
    var files: [String]
}

struct ServerResponse_Conversation: Decodable {
    var messages: [ServerMessage]
}

struct ServerMessage: Decodable {
    let type: String
    let content: String
}

#Preview {
    ContentView()
}
