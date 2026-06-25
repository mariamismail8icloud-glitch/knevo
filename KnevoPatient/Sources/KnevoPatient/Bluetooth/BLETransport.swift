import Foundation

protocol BLETransport: Sendable {
    func scanAndConnect() async throws
    func write(_ data: Data, to characteristicUUID: String) async throws
    func read(from characteristicUUID: String) async throws -> Data
    var statusUpdates: AsyncStream<Data> { get }
    func disconnect()
}
