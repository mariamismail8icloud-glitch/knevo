import Foundation

struct ChatMessage: Decodable, Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let senderName: String
    let body: String
    let messageType: String
    let sentAt: String
    let readAt: String?
}

struct SendMessageRequest: Encodable {
    let body: String
    let receiverId: String
    let messageType: String
}
