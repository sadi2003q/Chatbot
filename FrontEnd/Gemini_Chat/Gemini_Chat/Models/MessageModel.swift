//
//  MessageModel.swift
//  Gemini_Chat
//
//  Created by  Sadi on 30/04/2025.
//

import Foundation
struct Message: Identifiable, Equatable {
    let id : UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var showTime: Bool = false
    var isLoading: Bool = false
}
