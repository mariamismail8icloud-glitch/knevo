import CoreBluetooth
import Foundation

enum BLETransportError: Error, Equatable {
    case poweredOff
    case unauthorized
    case unsupported
    case deviceNotFound
    case connectionFailed(String)
    case serviceNotFound
    case characteristicNotFound(String)
    case readFailed(String)
    case writeFailed(String)
    case notConnected
}

/// Real `BLETransport` backed by CoreBluetooth (§3.0 discovery, §3.1 GATT).
///
/// IMPORTANT: CoreBluetooth is not available in the iOS Simulator, so this type
/// cannot be exercised there. It is correct-by-construction and compiles under
/// `-swift-version 6`; the simulator/test path uses `MockBLETransport` instead.
///
/// All CoreBluetooth delegate callbacks arrive on `queue` (a private serial
/// queue). The bridge serializes mutable state onto that queue and resumes the
/// async API via continuations, so the type is safe to use from any actor.
final class CoreBluetoothTransport: NSObject, BLETransport, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.knevo.ble.transport")

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristics: [String: CBCharacteristic] = [:]

    // Continuations are resumed exactly once each, then cleared.
    private var powerOnContinuation: CheckedContinuation<Void, Error>?
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var discoveryContinuation: CheckedContinuation<Void, Error>?
    private var readContinuations: [String: CheckedContinuation<Data, Error>] = [:]
    private var writeContinuations: [String: CheckedContinuation<Void, Error>] = [:]

    private var pendingServiceDiscovery = false
    private var discoveredCharacteristicCount = 0

    private let statusContinuation: AsyncStream<Data>.Continuation
    let statusUpdates: AsyncStream<Data>

    private let serviceCBUUID = CBUUID(string: KnevoGATT.serviceUUID)
    private let characteristicCBUUIDs: [CBUUID] = [
        CBUUID(string: KnevoGATT.wifiConfigUUID),
        CBUUID(string: KnevoGATT.wifiStatusUUID),
        CBUUID(string: KnevoGATT.setConfigUUID),
        CBUUID(string: KnevoGATT.controlUUID),
        CBUUID(string: KnevoGATT.deviceStatusUUID), // swiftlint:disable:this trailing_comma
    ]

    override init() {
        var continuation: AsyncStream<Data>.Continuation!
        statusUpdates = AsyncStream { continuation = $0 }
        statusContinuation = continuation
        super.init()
        central = CBCentralManager(delegate: self, queue: queue)
    }

    // MARK: - BLETransport

    func scanAndConnect() async throws {
        try await waitForPoweredOn()
        try await locateAndStorePeripheral()
        try await connectStoredPeripheral()
        try await discoverServicesAndCharacteristics()
    }

    func write(_ data: Data, to characteristicUUID: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                guard let peripheral = self.peripheral,
                      let characteristic = self.characteristics[characteristicUUID.lowercased()]
                else {
                    cont.resume(throwing: BLETransportError.characteristicNotFound(characteristicUUID))
                    return
                }
                self.writeContinuations[characteristicUUID.lowercased()] = cont
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
    }

    func read(from characteristicUUID: String) async throws -> Data {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
            queue.async {
                guard let peripheral = self.peripheral,
                      let characteristic = self.characteristics[characteristicUUID.lowercased()]
                else {
                    cont.resume(throwing: BLETransportError.characteristicNotFound(characteristicUUID))
                    return
                }
                self.readContinuations[characteristicUUID.lowercased()] = cont
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func disconnect() {
        queue.async {
            if let peripheral = self.peripheral {
                self.central.cancelPeripheralConnection(peripheral)
            }
            self.central.stopScan()
        }
    }

    // MARK: - Discovery steps (all hop onto `queue`)

    private func waitForPoweredOn() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                switch self.central.state {
                case .poweredOn:
                    cont.resume()
                case .poweredOff:
                    cont.resume(throwing: BLETransportError.poweredOff)
                case .unauthorized:
                    cont.resume(throwing: BLETransportError.unauthorized)
                case .unsupported:
                    cont.resume(throwing: BLETransportError.unsupported)
                default:
                    // .unknown / .resetting → wait for didUpdateState.
                    self.powerOnContinuation = cont
                }
            }
        }
    }

    /// Finds the target peripheral and stores it on `self.peripheral` (on `queue`).
    /// The `CBPeripheral` (non-Sendable) is never returned across a continuation —
    /// only `Void` crosses the actor boundary.
    private func locateAndStorePeripheral() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                // §3.0 step 1: reuse an already-connected device.
                let connected = self.central.retrieveConnectedPeripherals(withServices: [self.serviceCBUUID])
                if let existing = connected.first {
                    self.peripheral = existing
                    cont.resume()
                    return
                }
                // §3.0 step 2: scan, keep the first `knevo_`-prefixed peripheral.
                self.scanContinuation = cont
                self.central.scanForPeripherals(withServices: [self.serviceCBUUID])
            }
        }
    }

    private var scanContinuation: CheckedContinuation<Void, Error>?

    private func connectStoredPeripheral() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                guard let target = self.peripheral else {
                    cont.resume(throwing: BLETransportError.deviceNotFound)
                    return
                }
                target.delegate = self
                self.connectContinuation = cont
                self.central.connect(target)
            }
        }
    }

    private func discoverServicesAndCharacteristics() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                guard let peripheral = self.peripheral else {
                    cont.resume(throwing: BLETransportError.notConnected)
                    return
                }
                self.discoveryContinuation = cont
                self.pendingServiceDiscovery = true
                self.discoveredCharacteristicCount = 0
                peripheral.discoverServices([self.serviceCBUUID])
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension CoreBluetoothTransport: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let cont = powerOnContinuation else { return }
        powerOnContinuation = nil
        switch central.state {
        case .poweredOn: cont.resume()
        case .poweredOff: cont.resume(throwing: BLETransportError.poweredOff)
        case .unauthorized: cont.resume(throwing: BLETransportError.unauthorized)
        case .unsupported: cont.resume(throwing: BLETransportError.unsupported)
        default: powerOnContinuation = cont // keep waiting
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi _: NSNumber
    ) {
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? ""
        guard name.hasPrefix(KnevoGATT.namePrefix) else { return }
        guard let cont = scanContinuation else { return }
        scanContinuation = nil
        central.stopScan()
        self.peripheral = peripheral
        cont.resume()
    }

    func centralManager(_: CBCentralManager, didConnect _: CBPeripheral) {
        guard let cont = connectContinuation else { return }
        connectContinuation = nil
        cont.resume()
    }

    func centralManager(_: CBCentralManager, didFailToConnect _: CBPeripheral, error: Error?) {
        guard let cont = connectContinuation else { return }
        connectContinuation = nil
        cont.resume(throwing: BLETransportError.connectionFailed(error?.localizedDescription ?? "unknown"))
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral _: CBPeripheral, error _: Error?) {
        characteristics.removeAll()
    }
}

// MARK: - CBPeripheralDelegate

extension CoreBluetoothTransport: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            finishDiscovery(.failure(BLETransportError.connectionFailed(error.localizedDescription)))
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceCBUUID }) else {
            finishDiscovery(.failure(BLETransportError.serviceNotFound))
            return
        }
        peripheral.discoverCharacteristics(characteristicCBUUIDs, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            finishDiscovery(.failure(BLETransportError.connectionFailed(error.localizedDescription)))
            return
        }
        for characteristic in service.characteristics ?? [] {
            characteristics[characteristic.uuid.uuidString.lowercased()] = characteristic
        }
        // Enable notifications on the two status characteristics (§3.3, §3.5).
        for uuid in [KnevoGATT.wifiStatusUUID, KnevoGATT.deviceStatusUUID] {
            if let characteristic = characteristics[uuid.lowercased()] {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        finishDiscovery(.success(()))
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = characteristic.uuid.uuidString.lowercased()
        // Resolve a pending explicit read, if any.
        if let cont = readContinuations.removeValue(forKey: key) {
            if let error {
                cont.resume(throwing: BLETransportError.readFailed(error.localizedDescription))
            } else {
                cont.resume(returning: characteristic.value ?? Data())
            }
            return
        }
        // Otherwise it's a notification; forward to the stream.
        if let value = characteristic.value {
            statusContinuation.yield(value)
        }
    }

    func peripheral(_: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = characteristic.uuid.uuidString.lowercased()
        guard let cont = writeContinuations.removeValue(forKey: key) else { return }
        if let error {
            cont.resume(throwing: BLETransportError.writeFailed(error.localizedDescription))
        } else {
            cont.resume()
        }
    }

    private func finishDiscovery(_ result: Result<Void, Error>) {
        guard pendingServiceDiscovery, let cont = discoveryContinuation else { return }
        pendingServiceDiscovery = false
        discoveryContinuation = nil
        cont.resume(with: result)
    }
}
