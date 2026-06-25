import Foundation
import Network

enum SensorReceiverError: Error, Equatable {
    case localNetworkDenied
    case listenerFailed(String)
    case connectionFailed(String)
    case decodeFailed
    case cancelled
}

/// Post-set WiFi data plane (§4): a TCP server that the device connects to.
/// Listens on an ephemeral port, accepts ONE inbound connection, reassembles
/// the length-prefixed binary frame, decodes it, ACKs `0x06`, and delivers the
/// `SensorBatch` to the caller.
@MainActor
final class SensorDataReceiver {
    private static let ackByte: UInt8 = 0x06
    private static let frameLenPrefix = 4

    private var listener: NWListener?
    private var connection: NWConnection?
    private var buffer = Data()
    private var continuation: CheckedContinuation<SensorBatch, Error>?
    private var startContinuation: CheckedContinuation<(port: UInt16, localIP: String?), Error>?

    /// Port the listener is bound to (available after `start()` returns).
    private(set) var port: UInt16?

    init() {}

    /// Start the TCP listener on an ephemeral port. Returns the bound port and
    /// the device-facing local IPv4 address of this phone (for the WiFiConfig
    /// sent over BLE in T7). Throws if the listener cannot start (e.g. Local
    /// Network permission denied).
    func start() async throws -> (port: UInt16, localIP: String?) {
        let listener: NWListener
        do {
            listener = try NWListener(using: .tcp)
        } catch {
            throw SensorReceiverError.listenerFailed(error.localizedDescription)
        }
        self.listener = listener

        return try await withCheckedThrowingContinuation { cont in
            self.startContinuation = cont
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in self?.handleListenerState(state, listener: listener) }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.accept(connection) }
            }
            listener.start(queue: .main)
        }
    }

    private func handleListenerState(_ state: NWListener.State, listener: NWListener) {
        switch state {
        case .ready:
            let boundPort = listener.port?.rawValue ?? 0
            port = boundPort
            resumeStart(.success((boundPort, Self.localIPv4Address())))
        case let .failed(error):
            // If the listener was already ready (start resumed), fail any pending batch.
            if startContinuation == nil {
                failPending(.listenerFailed(error.localizedDescription))
            } else {
                resumeStart(.failure(Self.mapListenerError(error)))
            }
        case .cancelled:
            resumeStart(.failure(SensorReceiverError.cancelled))
        default:
            break
        }
    }

    private func resumeStart(_ result: Result<(port: UInt16, localIP: String?), Error>) {
        guard let cont = startContinuation else { return }
        startContinuation = nil
        cont.resume(with: result)
    }

    /// Suspends until the inbound frame is fully received and decoded.
    func awaitBatch() async throws -> SensorBatch {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
        }
    }

    func stop() {
        connection?.cancel()
        connection = nil
        listener?.cancel()
        listener = nil
    }

    // MARK: - Connection handling

    private func accept(_ connection: NWConnection) {
        // Accept only the first connection; reject any others.
        guard self.connection == nil else {
            connection.cancel()
            return
        }
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                if case let .failed(error) = state {
                    self.failPending(.connectionFailed(error.localizedDescription))
                }
            }
        }
        connection.start(queue: .main)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.failPending(.connectionFailed(error.localizedDescription))
                    return
                }
                if let data, !data.isEmpty {
                    self.buffer.append(data)
                    if self.tryDecodeAndAck(on: connection) { return }
                }
                if isComplete {
                    self.failPending(.connectionFailed("connection closed before full frame"))
                    return
                }
                self.receive(on: connection)
            }
        }
    }

    /// Returns true once a full frame has been decoded (terminal).
    private func tryDecodeAndAck(on connection: NWConnection) -> Bool {
        guard buffer.count >= Self.frameLenPrefix else { return false }
        let frameLen = UInt32(buffer[0])
            | (UInt32(buffer[1]) << 8)
            | (UInt32(buffer[2]) << 16)
            | (UInt32(buffer[3]) << 24)
        let total = Self.frameLenPrefix + Int(frameLen)
        guard buffer.count >= total else { return false }

        let frame = buffer.prefix(total)
        do {
            let batch = try KnevoCodec.decodeSensorBatch(Data(frame))
            connection.send(content: Data([Self.ackByte]), completion: .contentProcessed { _ in })
            continuation?.resume(returning: batch)
            continuation = nil
        } catch {
            failPending(.decodeFailed)
        }
        return true
    }

    private func failPending(_ error: SensorReceiverError) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    // MARK: - Error mapping

    private static func mapListenerError(_ error: NWError) -> SensorReceiverError {
        // POSIXErrorCode 1 (EPERM) on first listen = Local Network permission denied.
        if case let .posix(code) = error, code == .EPERM {
            return .localNetworkDenied
        }
        return .listenerFailed(error.localizedDescription)
    }

    // MARK: - Local IPv4 discovery (prefer en0/en1)

    static func localIPv4Address() -> String? {
        var preferred: String?
        var fallback: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let interface = current.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)

            var addr = interface.ifa_addr.pointee
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = withUnsafePointer(to: &addr) { saPtr in
                getnameinfo(saPtr, socklen_t(saPtr.pointee.sa_len),
                            &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            }
            guard result == 0, let address = String(validatingCString: host) else { continue }
            if name == "en0" || name == "en1" {
                preferred = preferred ?? address
            } else if name != "lo0" {
                fallback = fallback ?? address
            }
        }
        return preferred ?? fallback
    }
}
