//
//  Server_responses.swift
//  Gemini_Chat
//
//  Created by  Sadi on 30/04/2025.
//

import Foundation

struct ServerResponse_Text: Decodable {
    let response: String
}

struct ServerResponse_History: Decodable {
    var files: [String]
}

struct ServerResponse_AllText: Decodable {
    var messages: [ServerMessage]
}

struct ServerMessage: Decodable {
    let type: String
    let content: String
}
