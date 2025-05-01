//
//  Componants.swift
//  Gemini_Chat
//
//  Created by  Sadi on 29/04/2025.
//

import Foundation
import SwiftUI


struct MessageInputView: View {
    @Binding var message: String
    var onSubmit: ((String) -> Void)?
    
    
    var body: some View {
        HStack {
            TextField("Type your message...", text: $message)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                )
                .font(.system(size: 16))
            
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
    
    
}

//#Preview {
//    MessageInputView(message: .constant("Demo Message"))
//        .previewLayout(.sizeThatFits)
//        .padding()
//}
