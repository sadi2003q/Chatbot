//
//  ChatHistory.swift
//  Gemini_Chat
//
//  Created by  Sadi on 20/04/2025.
//

import SwiftUI

struct ChatHistorySidebar: View {
    @Binding var conversations: [String]
    @Binding var isShowing: Bool
    @Binding var selectedConversation: String?
    @Binding var conversationName: String
    @State private var currentName: String = ""
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background when sidebar is open
            Color.black
                    .opacity(isShowing ? 0.3 : 0.0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: isShowing)
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
            
            // The sidebar content
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    // Header
                    HStack {
                        Text("Chat History")
                            .font(.headline)
                        Spacer()
                        Button(action: { isShowing = false }) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    
                    // List of conversations
                    List {
                        ForEach(conversations, id: \.self) { fileName in
                            let displayName = fileName
                                .replacingOccurrences(of: ".json", with: "")
                                .replacingOccurrences(of: "_", with: " ")
                                .components(separatedBy: " ")
                                .filter { !$0.isEmpty }
                                .prefix(2)
                                .joined(separator: " ")

                            Button(action: {
                                selectedConversation = fileName
                                conversationName = displayName
                                isShowing = false
                            }) {
                                Text(displayName)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteConversation(named: fileName)
                                    Task {
                                        await deleConversation_fromServer(fileName: fileName)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .listStyle(.plain)
                }
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .background(Color(.systemBackground))
                .offset(x: isShowing ? 0 : -UIScreen.main.bounds.width * 0.75)
                .animation(.easeInOut, value: isShowing)
                
                Spacer()
            }
        }
    }
    
    private func deleteConversation(named name: String) {
        withAnimation {
            conversations.removeAll { $0 == name }
            if selectedConversation == name {
                selectedConversation = nil
            }
        }
        
    }
    
    
    private func deleConversation_fromServer(fileName : String) async {
        do {
            guard let url = URL(string: "http://127.0.0.1:8000/delete_conversation") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload = ["file": fileName]
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            request.httpBody = jsonData
            
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(ServerResponse_Text.self, from: data)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("\(decoded.response)")
            }
        } catch {
            print("Error starting new conversation: \(error.localizedDescription)")
        }
    }
}











struct MainChatView: View {
    @State private var conversations = ["history-1.json", "important-chat.json", "new-idea.json"]
    @State private var selectedConversation: String? = nil
    @State private var showSidebar = false
    @State private var conversationName:String = ""
    
    var body: some View {
        ZStack {
            // Your main chat interface
            NavigationView {
                // Main content here
                Text("Chat content goes here")
                    .navigationTitle(selectedConversation ?? "New Chat")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showSidebar.toggle() }) {
                                Image(systemName: "line.3.horizontal")
                            }
                        }
                    }
            }
            
            // Overlay the sidebar
            ChatHistorySidebar(
                conversations: $conversations,
                isShowing: $showSidebar,
                selectedConversation: $selectedConversation,
                conversationName: $conversationName
            )
        }
    }
}


#Preview(body: {
    MainChatView()
})





