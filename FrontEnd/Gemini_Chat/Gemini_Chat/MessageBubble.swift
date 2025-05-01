//
//  MessageBubble.swift
//  Gemini_Chat
//
//  Created by  Sadi on 19/04/2025.
//

import SwiftUI
/*
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            // Modified Text initialization with Markdown support
            Text(.init(message.content)) // Note the .init() here
                .padding(10)
                .foregroundColor(message.isUser ? .white : .primary)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .cornerRadius(10)
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing: .leading)
                .textSelection(.enabled) // Optional: allows text selection
            
            if !message.isUser {
                Spacer()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: message.isUser ? .trailing : .leading),
            removal: .opacity
        ))
    }
}


struct MessageBubble2: View {
        let message: Message
        
        var body: some View {
            HStack {
                if message.isUser {
                    Spacer()
                }
                
                Text(message.content)
                    .padding(10)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: message.isUser ? .trailing: .leading)
                
                if !message.isUser {
                    Spacer()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: message.isUser ? .trailing : .leading),
                removal: .opacity
            ))
        }
    }
*/

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        // Wrapping in HStack for proper alignment
        HStack {
            if message.isUser {
                Spacer()
            }
            
            // Main message content
            Text(.init(message.content)) // Using .init() for Markdown support
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(message.isUser ? .white : .primary)
                .background(
                    message.isUser ? Color.blue : Color(.systemGray5)
                )
                .cornerRadius(12)
                .frame(
                    maxWidth: 300,
                    alignment: message.isUser ? .trailing : .leading
                )
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true) // Ensure proper text wrapping
            
            if !message.isUser {
                Spacer()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: message.isUser ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .opacity
        ))
        .id(message.id) // Important for animation identity
    }
}

//#Preview {
//    MessageBubble()
//}
