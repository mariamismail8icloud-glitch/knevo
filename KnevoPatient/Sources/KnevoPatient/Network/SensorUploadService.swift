import Foundation

struct SensorIngestResponse: Decodable {
    let inserted: Int
}

/// Relays a decoded sensor batch to the backend ingest endpoint (§5.1).
/// Large sets (~120k samples / ~10 MB) are split into chunks to keep each
/// request small; inserted counts are summed across chunks.
@MainActor
final class SensorUploadService {
    static let chunkSize = 5000

    private let post: (String, [SensorSample]) async throws -> SensorIngestResponse

    /// Default uses the shared API client. Inject a closure in tests.
    init(post: @escaping (String, [SensorSample]) async throws -> SensorIngestResponse = { path, samples in
        try await APIClient.shared.post(path: path, body: samples)
    }) {
        self.post = post
    }

    func upload(sessionId: UUID, setRecordId: UUID, samples: [SensorSample]) async throws -> Int {
        let path = "/api/sessions/\(sessionId.uuidString)/sets/\(setRecordId.uuidString)/sensor-readings"
        var totalInserted = 0
        for batch in Self.chunk(samples, size: Self.chunkSize) {
            let response = try await post(path, batch)
            totalInserted += response.inserted
        }
        return totalInserted
    }

    /// Splits `items` into sub-arrays of at most `size` elements (last may be smaller).
    nonisolated static func chunk<T>(_ items: [T], size: Int) -> [[T]] {
        guard size > 0 else { return items.isEmpty ? [] : [items] }
        return stride(from: 0, to: items.count, by: size).map {
            Array(items[$0 ..< min($0 + size, items.count)])
        }
    }
}
