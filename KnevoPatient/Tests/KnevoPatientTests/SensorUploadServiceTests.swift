import Foundation
@testable import KnevoPatient
import Testing

@Suite("SensorUploadService")
struct SensorUploadServiceTests {
    @Test("chunk splits 12,001 items into 5000/5000/2001")
    func chunkUnevenSplit() {
        let items = Array(0 ..< 12001)
        let chunks = SensorUploadService.chunk(items, size: 5000)
        #expect(chunks.map(\.count) == [5000, 5000, 2001])
        #expect(chunks.flatMap { $0 } == items)
    }

    @Test("chunk returns one chunk when smaller than size")
    func chunkSmaller() {
        let chunks = SensorUploadService.chunk(Array(0 ..< 3), size: 5000)
        #expect(chunks.map(\.count) == [3])
    }

    @Test("chunk of empty input is empty")
    func chunkEmpty() {
        let chunks = SensorUploadService.chunk([Int](), size: 5000)
        #expect(chunks.isEmpty)
    }

    @MainActor
    @Test("upload sums inserted counts across chunks")
    func uploadSumsChunks() async throws {
        var requestCounts: [Int] = []
        let service = SensorUploadService { _, samples in
            requestCounts.append(samples.count)
            return SensorIngestResponse(inserted: samples.count)
        }
        let samples = (0 ..< 12001).map { _ in zeroSample() }
        let inserted = try await service.upload(
            sessionId: UUID(), setRecordId: UUID(), samples: samples
        )
        #expect(inserted == 12001)
        #expect(requestCounts == [5000, 5000, 2001])
    }

    private func zeroSample() -> SensorSample {
        SensorSample(
            timestampUs: 0, sampleId: 0,
            footAxG: 0, footAyG: 0, footAzG: 0, footGxRadS: 0, footGyRadS: 0, footGzRadS: 0,
            shankAxG: 0, shankAyG: 0, shankAzG: 0, shankGxRadS: 0, shankGyRadS: 0, shankGzRadS: 0,
            thighAxG: 0, thighAyG: 0, thighAzG: 0, thighGxRadS: 0, thighGyRadS: 0, thighGzRadS: 0,
            heelFsrRaw: 0, midfootFsrRaw: 0
        )
    }
}
