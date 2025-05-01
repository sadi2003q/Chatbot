//
//  Models.swift
//  Gemini_Chat
//
//  Created by  Sadi on 29/04/2025.
//

import Foundation


struct Model_response: Codable {
    var response: String
}

struct Model_request: Codable {
    var request: String
}

struct ConversationFileName: Codable {
    var files: String
}

struct ServerMessage_: Decodable {
    let type: String
    let content: String
}
struct Message_: Identifiable, Equatable {
    let id : UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isLoading: Bool = false
}
