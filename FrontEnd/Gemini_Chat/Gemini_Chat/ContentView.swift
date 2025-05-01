


import SwiftUI

struct ContentView: View {
    @State private var userQuery: String = "Hello"
    @State private var messages: [Message] = []
    @State private var isLoading = false
    
    @State private var conversations: [String] = []
    @State private var selectedConversation: String? = nil
    @State private var showSidebar = false
    
    @State private var scrollViewID = UUID()
    @State private var scrollTo: String = ""
    
    @State private var rebuildID = UUID()
    
    @State private var upButton = false
    
    @State private var conversationName: String = ""
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    // Messages list
                    //                    view_MessageScrollBar
                    AllMessageView
                    
                    
                    // Input area
                    view_InputArea
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(conversationName.isEmpty ? "New Conversation" : conversationName)
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
                selectedConversation: $selectedConversation,
                conversationName: $conversationName
            )
        }
        
    }
    
    // MARK: - Message Area
    private var view_MessageScrollBar: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages , id: \.id) { message in
                        if message.isLoading {
                            HStack {
                                LoadingAnimation()
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading),
                                        removal: .move(edge: .leading)
                                    ))
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
                    
                    Circle()
                        .frame(width: 20, height: 20)
                    
                }
                .padding()
                
            }
            .id(rebuildID)
            .onChange(of: messages.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }            }
            
        }
    }
    
    
    
    private var AllMessageView: some View {
        ScrollViewReader { proxy in
            VStack {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach($messages, id: \.id) { $message in
                            messageBubble(user_message: $message)
                                .id(message.id)
                                .transition(message.isUser ? .move(edge: .trailing) : .move(edge: .leading))
                        }
                    }
                    .padding(.top)
                    
                }
                .id(rebuildID)
                .frame(maxHeight: .infinity)
                
            }
            .onChange(of: messages.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: upButton) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func messageBubble(user_message: Binding<Message>) -> some View {
        VStack {
            Text(.init(user_message.wrappedValue.content))
                .padding()
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .background(user_message.wrappedValue.isUser ? Color.night : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(maxWidth: 300, alignment: user_message.wrappedValue.isUser ? .trailing : .leading)
            
            
            if user_message.wrappedValue.showTime {
                Text("\(user_message.wrappedValue.timestamp.formatted(.dateTime.hour().minute()))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .frame(maxWidth: 300, alignment: user_message.wrappedValue.isUser ? .trailing : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: user_message.wrappedValue.isUser ? .trailing : .leading)
        .padding(.horizontal)
        .onTapGesture {
            withAnimation {
                user_message.wrappedValue.showTime.toggle()
            }
            
        }
        .opacity(user_message.wrappedValue.content.isEmpty ? 0 : 1)
        
        if user_message.wrappedValue.content.isEmpty {
            HStack {
                LoadingAnimation()
                    .transition(.opacity)
                    .padding(.leading)
                    .scaleEffect(0.5)
                Spacer()
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
            upButton.toggle()
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
    
    
    
    
    
    
    
    
    
}



// MARK: - Network Functions
extension ContentView {
    
    @MainActor
    func sendQueryToGemini() async {
        guard !userQuery.isEmpty else { return }
        
        // Add user message with animation
        let userMessage = Message(id: UUID(), content: userQuery, isUser: true, timestamp: Date())
        withAnimation(.spring()) {
            messages.append(userMessage)
        }
        
        // Add loading placeholder with animation
        let loadingMessage = Message(
            id: UUID(),
            content: "",
            isUser: false,
            timestamp: Date(),
            isLoading: true
        )
        
        withAnimation(.spring()) {
            
            messages.append(loadingMessage)
            upButton.toggle()
        }
        
        isLoading = true
        //        userQuery = ""
        
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
            let decoded = try JSONDecoder().decode(ServerResponse_Text.self, from: data)
            
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
                id: messages[lastIndex].id,
                content: content,
                isUser: false,
                timestamp: Date(),
                isLoading: false
            )
        }
    }
    
    private func newConversation() {
        withAnimation(.spring()) {
            messages.removeAll()
            selectedConversation = nil
            rebuildID = UUID()
        }
        
        Task {
            await instantiateNewConversationOnServer()
        }
    }
    
    private func BuiltConversationName() {
        
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
            
            let decoded = try JSONDecoder().decode(ServerResponse_AllText.self, from: data)
            
            // Clear current messages
            withAnimation {
                messages=[]
            }
            
            // Convert server messages to local Message format
            var newMessages: [Message] = []
            for serverMessage in decoded.messages {
                let isUser = serverMessage.type == "HumanMessage"
                let message = Message(
                    id: UUID(),
                    content: serverMessage.content,
                    isUser: isUser,
                    timestamp: Date(),
                    isLoading: false
                )
                newMessages.append(
                    message
                    
                )
            }
            
            for (index, message) in newMessages.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.spring()) {
                        messages.append(message)
                    }
                }
            }
        } catch {
            print("Error loading conversation: \(error.localizedDescription)")
            
        }
        
        isLoading = false
    }
}


#Preview {
    ContentView()
}
