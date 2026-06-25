import Foundation
@testable import KnevoPatient
import Network
import Testing

@Suite("SensorDataReceiver")
struct SensorDataReceiverTests {
    private func makeSample(index: Int) -> SensorSample {
        let base = Float(index) * 0.5
        let floats = (0 ..< 18).map { Double(base + Float($0)) }
        return SensorSample(
            timestampUs: Int64(1_719_300_000_000_000 + index), sampleId: index,
            footAxG: floats[0], footAyG: floats[1], footAzG: floats[2],
            footGxRadS: floats[3], footGyRadS: floats[4], footGzRadS: floats[5],
            shankAxG: floats[6], shankAyG: floats[7], shankAzG: floats[8],
            shankGxRadS: floats[9], shankGyRadS: floats[10], shankGzRadS: floats[11],
            thighAxG: floats[12], thighAyG: floats[13], thighAzG: floats[14],
            thighGxRadS: floats[15], thighGyRadS: floats[16], thighGzRadS: floats[17],
            heelFsrRaw: 1000 + index, midfootFsrRaw: 200 + index
        )
    }

    @MainActor
    @Test("receives a frame split across two sends and ACKs 0x06", .timeLimit(.minutes(1)))
    func receiveSplitFrameAndAck() async throws {
        let uuid = UUID()
        let samples = (0 ..< 3).map { makeSample(index: $0) }
        let frame = KnevoCodec.encodeSensorBatch(setRecordId: uuid, samples: samples)

        let receiver = SensorDataReceiver()
        defer { receiver.stop() }
        let (port, _) = try await receiver.start()
        #expect(port != 0)

        // Connect a loopback client to the receiver.
        let endpoint = try NWEndpoint.hostPort(
            host: .ipv4(.loopback),
            port: #require(NWEndpoint.Port(rawValue: port))
        )
        let client = NWConnection(to: endpoint, using: .tcp)
        let ackBox = AckBox()
        client.stateUpdateHandler = { state in
            if case .ready = state {
                // Split the frame across two sends to prove incremental reassembly.
                let split = 7
                let head = frame.prefix(split)
                let tail = frame.suffix(from: split)
                client.send(content: Data(head), completion: .contentProcessed { _ in
                    client.send(content: Data(tail), completion: .contentProcessed { _ in })
                })
                // Read the 1-byte ACK back.
                client.receive(minimumIncompleteLength: 1, maximumLength: 1) { data, _, _, _ in
                    if let data, let first = data.first {
                        Task { await ackBox.set(first) }
                    }
                }
            }
        }
        client.start(queue: .main)
        defer { client.cancel() }

        let batch = try await receiver.awaitBatch()
        #expect(batch.setRecordId == uuid)
        #expect(batch.samples == samples)

        // Allow the ACK round-trip to land.
        let ack = await ackBox.waitForValue(timeoutSeconds: 5)
        #expect(ack == 0x06)
    }

    @MainActor
    @Test("start exposes a non-zero bound port")
    func startExposesPort() async throws {
        let receiver = SensorDataReceiver()
        defer { receiver.stop() }
        let (port, _) = try await receiver.start()
        #expect(port != 0)
        #expect(receiver.port == port)
    }
}

/// Actor box so the NWConnection completion handler (Sendable context) can
/// hand the ACK byte back to the test without data races.
private actor AckBox {
    private var value: UInt8?

    func set(_ byte: UInt8) {
        value = byte
    }

    func waitForValue(timeoutSeconds: Double) async -> UInt8? {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while value == nil, Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return value
    }
}
