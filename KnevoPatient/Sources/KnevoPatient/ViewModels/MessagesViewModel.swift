import Foundation

@Observable
@MainActor
final class MessagesViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false
    var errorMessage: String?
    var messageInput: String = ""
    var doctorId: String?
    var doctorName: String = "Your Doctor"
    var isSending = false

    func loadConversation(patientId: String) async {
        guard let doctorId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            messages = try await APIClient.shared.get(path: "/api/messages?partnerId=\(doctorId)")
        } catch {
            errorMessage = "Could not load messages."
        }
    }

    func sendMessage(patientId: String) async {
        guard let doctorId, !messageInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let body = messageInput
        messageInput = ""
        isSending = true
        defer { isSending = false }
        do {
            let req = SendMessageRequest(body: body, receiverId: doctorId, messageType: "TEXT")
            let sent: ChatMessage = try await APIClient.shared.post(path: "/api/messages", body: req)
            messages.append(sent)
        } catch {
            errorMessage = "Failed to send message."
            messageInput = body
        }
    }

    func setDoctorFromPlan(_ plan: ActivePlan) {
        doctorId = plan.issuedById
    }
}
