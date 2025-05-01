//
//  MessageBox.swift
//  Gemini_Chat
//
//  Created by  Sadi on 30/04/2025.
//

import Foundation
import SwiftUI

struct Message__: Codable, Identifiable {
    var content: String
    var id: String
    var time : Date
    var isUser : Bool
    var showTime : Bool = false
}



struct MessageBox: View {
    
    
    
    @State private var showTime = false
    
    
    @State private var user_input : String = "hello"
    
    @State private var messages: [Message__] = [
        Message__(content: "Hello from user!", id: UUID().uuidString, time: Date(), isUser: true),
        Message__(content: "Hi from assistant!", id: UUID().uuidString, time: Date(), isUser: false)
    ]
    
    
    @State private var rebuildID = UUID()

   
    
    
    
    var body: some View {
        NavigationStack {
            Group {
                AllMessageView
            }
            .navigationTitle("All Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    New_Conversation
                }
            }
            
        }
        
        
    }
    
    @ViewBuilder
    func messageBubble(user_message: Binding<Message__>) -> some View {
        VStack {
            Text(user_message.wrappedValue.content)
                .padding()
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .background(user_message.wrappedValue.isUser ? Color.red : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(maxWidth: 300, alignment: user_message.wrappedValue.isUser ? .trailing : .leading)
            
            if user_message.wrappedValue.showTime {
                Text("\(user_message.wrappedValue.time.formatted(.dateTime.hour().minute()))")
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
                    Circle()
                        .frame(width: 20, height: 20)
                }
                .id(rebuildID)

                TextField_view
            }
            .onChange(of: messages.count) {
                withAnimation {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
        }
    }
    
    private var TextField_view: some View {
        HStack {
            TextField("Send the message", text: $user_input)
                .textFieldStyle(RoundedTextFieldStyle())
                .padding(10)
                
            
            Button {
                addMessage()
            } label: {
                Image(systemName: "arrow.left.circle")
                    .font(.title)
                    .rotationEffect(.degrees(user_input.isEmpty ? 0 : 90))
                    .animation(.easeInOut, value: user_input)
            }

        }
        .padding(.horizontal)
        
    }
    
//    private var New_Conversation: some View {
//        Button {
//            withAnimation {
//                messages.removeAll()
//            }
//        } label: {
//            Image(systemName: "line.3.horizontal")
//                .font(.title2)
//                .foregroundStyle(.primary)
//        }
//
//    }
    
    private var New_Conversation: some View {
        Button {
            withAnimation {
                messages.removeAll()
                rebuildID = UUID() // Force LazyVStack to rebuild
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundStyle(.primary)
        }
    }
    
    
    
    
    
    private func addMessage() {
        let newMessage = Message__(
            content: user_input,
            id: UUID().uuidString,
            time: Date(),
            isUser: Bool.random(),
            showTime: false
        )

        withAnimation {
            messages.append(newMessage)
        }

    }
    
    
    
}


struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical)
            .padding(.horizontal, 24)
            .background(
                Color(UIColor.systemGray6)
            )
            .clipShape(Capsule(style: .continuous))
    }
}


#Preview {
    MessageBox()
}

