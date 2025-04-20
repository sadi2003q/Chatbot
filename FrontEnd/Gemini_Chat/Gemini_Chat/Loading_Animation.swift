//
//  Loading_Animation.swift
//  Gemini_Chat
//
//  Created by  Sadi on 17/04/2025.
//

import SwiftUI

struct LoadingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
        .padding(10)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

#Preview {
    LoadingAnimation()
}
