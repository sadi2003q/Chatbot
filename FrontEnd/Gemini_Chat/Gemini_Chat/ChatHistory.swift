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
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    
                    // List of conversations
                    /*
                    List {
                        ForEach(conversations, id: \.self) { fileName in
                            Button(action: {
                                selectedConversation = fileName
                                isShowing = false
                            }) {
                                Text(fileName.replacingOccurrences(of: ".json", with: ""))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteConversation(named: fileName)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                     */
                    List {
                        ForEach(conversations, id: \.self) { fileName in
                            Button(action: {
                                selectedConversation = fileName
                                isShowing = false
                            }) {
                                // Create the display name in one expression
                                Text(
                                    fileName
                                        .replacingOccurrences(of: ".json", with: "")
                                        .replacingOccurrences(of: "_", with: " ")
                                        .components(separatedBy: " ")
                                        .filter { !$0.isEmpty }
                                        .prefix(2)  // Take first two words if you want (adjust as needed)
                                        .joined(separator: " ")
                                )
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteConversation(named: fileName)
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
}











struct MainChatView: View {
    @State private var conversations = ["history-1.json", "important-chat.json", "new-idea.json"]
    @State private var selectedConversation: String? = nil
    @State private var showSidebar = false
    
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
                selectedConversation: $selectedConversation
            )
        }
    }
}


#Preview(body: {
    MainChatView()
})





