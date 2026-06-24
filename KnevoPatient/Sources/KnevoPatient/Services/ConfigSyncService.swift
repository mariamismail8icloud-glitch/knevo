import Foundation

@Observable
@MainActor
final class ConfigSyncService {
    var lastConfigUpdate: Date?
    private var webSocketTask: URLSessionWebSocketTask?
    private var patientId: String?

    func connect(patientId: String, onUpdate: @escaping () -> Void) {
        self.patientId = patientId
        // Use simple polling as fallback — WebSocket STOMP requires a library
        // For M7 we rely on pull-to-refresh and app-open fetch
        // A full STOMP implementation is deferred to post-Phase-1 polish
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
}
