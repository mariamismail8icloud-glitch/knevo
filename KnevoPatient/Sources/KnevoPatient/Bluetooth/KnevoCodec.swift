import Foundation

enum KnevoCodecError: Error, Equatable {
    case bufferTooShort
    case badMagic
    case unsupportedVersion(UInt8)
    case badSampleSize(UInt16)
    case frameLengthMismatch
}

struct WiFiConfig {
    let appPort: UInt16
    let appIP: [UInt8]
    let ssid: String
    let password: String
}

struct WiFiStatus: Equatable {
    let ok: Bool
    let errorCode: UInt8
}

struct SetConfig {
    let setRecordId: UUID
    let durationS: UInt16
    let maxSpeed: Float
    let maxExtensionAngleDeg: Float
    let maxFlexionAngleDeg: Float
}

enum Control: UInt8 {
    case start = 0x01
    case stop = 0x02
}

enum DeviceState: UInt8 {
    case idle = 0
    case running = 1
    case done = 2
    case fault = 3
}

struct DeviceStatus: Equatable {
    let state: DeviceState
    let batteryPct: UInt8
    let faultCode: UInt8
}

struct SensorBatch: Equatable {
    let setRecordId: UUID
    let samples: [SensorSample]
}

enum KnevoCodec {
    // MARK: - Little-endian append helpers

    private static func appendLE(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
    }

    private static func appendLE(_ value: Float, to data: inout Data) {
        var bits = value.bitPattern.littleEndian
        withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
    }

    private static func appendLE(_ value: UInt32, to data: inout Data) {
        for index in 0 ..< 4 {
            data.append(UInt8((value >> (8 * index)) & 0xFF))
        }
    }

    private static func appendLE(_ value: UInt64, to data: inout Data) {
        for index in 0 ..< 8 {
            data.append(UInt8((value >> (8 * UInt64(index))) & 0xFF))
        }
    }

    private static func uuidBytes(_ uuid: UUID) -> [UInt8] {
        let raw = uuid.uuid
        return [raw.0, raw.1, raw.2, raw.3, raw.4, raw.5, raw.6, raw.7,
                raw.8, raw.9, raw.10, raw.11, raw.12, raw.13, raw.14, raw.15]
    }

    // MARK: - WiFiConfig (encode, central → device) §3.2

    static func encodeWiFiConfig(_ config: WiFiConfig) -> Data {
        var data = Data()
        appendLE(config.appPort, to: &data)
        data.append(contentsOf: config.appIP)
        let ssidBytes = Array(config.ssid.utf8)
        data.append(UInt8(ssidBytes.count))
        data.append(contentsOf: ssidBytes)
        let passBytes = Array(config.password.utf8)
        data.append(UInt8(passBytes.count))
        data.append(contentsOf: passBytes)
        return data
    }

    // MARK: - WiFiStatus (decode, device → central) §3.3

    static func decodeWiFiStatus(_ data: Data) throws -> WiFiStatus {
        guard data.count >= 2 else { throw KnevoCodecError.bufferTooShort }
        let bytes = [UInt8](data)
        return WiFiStatus(ok: bytes[0] == 0, errorCode: bytes[1])
    }

    // MARK: - SetConfig (encode) §3.4

    static func encodeSetConfig(_ config: SetConfig) -> Data {
        var data = Data()
        data.append(contentsOf: uuidBytes(config.setRecordId))
        appendLE(config.durationS, to: &data)
        appendLE(config.maxSpeed, to: &data)
        appendLE(config.maxExtensionAngleDeg, to: &data)
        appendLE(config.maxFlexionAngleDeg, to: &data)
        return data
    }

    // MARK: - Control (encode) §3.4

    static func encodeControl(_ control: Control) -> Data {
        Data([control.rawValue])
    }

    // MARK: - DeviceStatus (decode) §3.5

    static func decodeDeviceStatus(_ data: Data) throws -> DeviceStatus {
        guard data.count >= 3 else { throw KnevoCodecError.bufferTooShort }
        let bytes = [UInt8](data)
        let state = DeviceState(rawValue: bytes[0]) ?? .fault
        return DeviceStatus(state: state, batteryPct: bytes[1], faultCode: bytes[2])
    }

    // MARK: - TCP sensor frame (encode) §4

    private static let headerSize = 28
    private static let sampleSize = 88

    static func encodeSensorBatch(setRecordId: UUID, samples: [SensorSample]) -> Data {
        var header = Data()
        header.append(contentsOf: Array("KNVO".utf8))
        header.append(1) // version
        header.append(0) // flags
        header.append(contentsOf: uuidBytes(setRecordId))
        appendLE(UInt32(samples.count), to: &header)
        appendLE(UInt16(sampleSize), to: &header)

        var records = Data()
        records.reserveCapacity(samples.count * sampleSize)
        for sample in samples {
            appendLE(UInt64(bitPattern: sample.timestampUs), to: &records)
            appendLE(UInt32(bitPattern: Int32(sample.sampleId)), to: &records)

            appendLE(Float(sample.footAxG), to: &records)
            appendLE(Float(sample.footAyG), to: &records)
            appendLE(Float(sample.footAzG), to: &records)
            appendLE(Float(sample.footGxRadS), to: &records)
            appendLE(Float(sample.footGyRadS), to: &records)
            appendLE(Float(sample.footGzRadS), to: &records)

            appendLE(Float(sample.shankAxG), to: &records)
            appendLE(Float(sample.shankAyG), to: &records)
            appendLE(Float(sample.shankAzG), to: &records)
            appendLE(Float(sample.shankGxRadS), to: &records)
            appendLE(Float(sample.shankGyRadS), to: &records)
            appendLE(Float(sample.shankGzRadS), to: &records)

            appendLE(Float(sample.thighAxG), to: &records)
            appendLE(Float(sample.thighAyG), to: &records)
            appendLE(Float(sample.thighAzG), to: &records)
            appendLE(Float(sample.thighGxRadS), to: &records)
            appendLE(Float(sample.thighGyRadS), to: &records)
            appendLE(Float(sample.thighGzRadS), to: &records)

            appendLE(UInt16(sample.heelFsrRaw), to: &records)
            appendLE(UInt16(sample.midfootFsrRaw), to: &records)
        }

        var data = Data()
        appendLE(UInt32(header.count + records.count), to: &data)
        data.append(header)
        data.append(records)
        return data
    }

    // MARK: - TCP sensor frame (decode) §4

    static func decodeSensorBatch(_ data: Data) throws -> SensorBatch {
        let bytes = [UInt8](data)
        guard bytes.count >= 4 else { throw KnevoCodecError.bufferTooShort }

        var offset = 0
        let frameLen = readUInt32LE(bytes, &offset)

        guard bytes.count >= 4 + headerSize else { throw KnevoCodecError.bufferTooShort }

        let magic = Array(bytes[offset ..< offset + 4])
        offset += 4
        guard magic == Array("KNVO".utf8) else { throw KnevoCodecError.badMagic }

        let version = bytes[offset]; offset += 1
        guard version == 1 else { throw KnevoCodecError.unsupportedVersion(version) }

        offset += 1 // flags

        let idBytes = Array(bytes[offset ..< offset + 16])
        offset += 16
        let setRecordId = uuidFromBytes(idBytes)

        let sampleCount = readUInt32LE(bytes, &offset)
        let declaredSampleSize = readUInt16LE(bytes, &offset)
        guard declaredSampleSize == UInt16(sampleSize) else {
            throw KnevoCodecError.badSampleSize(declaredSampleSize)
        }

        let expectedFrameLen = headerSize + Int(sampleCount) * sampleSize
        guard Int(frameLen) == expectedFrameLen else {
            throw KnevoCodecError.frameLengthMismatch
        }
        guard bytes.count >= 4 + expectedFrameLen else {
            throw KnevoCodecError.bufferTooShort
        }

        var samples: [SensorSample] = []
        samples.reserveCapacity(Int(sampleCount))
        for _ in 0 ..< Int(sampleCount) {
            samples.append(readSample(bytes, &offset))
        }

        return SensorBatch(setRecordId: setRecordId, samples: samples)
    }

    // MARK: - Primitive readers (little-endian, unaligned-safe)

    private static func readUInt16LE(_ bytes: [UInt8], _ offset: inout Int) -> UInt16 {
        let value = UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
        offset += 2
        return value
    }

    private static func readUInt32LE(_ bytes: [UInt8], _ offset: inout Int) -> UInt32 {
        let value = UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
        offset += 4
        return value
    }

    private static func readUInt64LE(_ bytes: [UInt8], _ offset: inout Int) -> UInt64 {
        var value: UInt64 = 0
        for index in 0 ..< 8 {
            value |= UInt64(bytes[offset + index]) << (8 * index)
        }
        offset += 8
        return value
    }

    private static func readFloatLE(_ bytes: [UInt8], _ offset: inout Int) -> Float {
        let bits = readUInt32LE(bytes, &offset)
        return Float(bitPattern: bits)
    }

    private static func readSample(_ bytes: [UInt8], _ offset: inout Int) -> SensorSample {
        let timestampUs = Int64(bitPattern: readUInt64LE(bytes, &offset))
        let sampleId = Int(readUInt32LE(bytes, &offset))

        let footAxG = Double(readFloatLE(bytes, &offset))
        let footAyG = Double(readFloatLE(bytes, &offset))
        let footAzG = Double(readFloatLE(bytes, &offset))
        let footGxRadS = Double(readFloatLE(bytes, &offset))
        let footGyRadS = Double(readFloatLE(bytes, &offset))
        let footGzRadS = Double(readFloatLE(bytes, &offset))

        let shankAxG = Double(readFloatLE(bytes, &offset))
        let shankAyG = Double(readFloatLE(bytes, &offset))
        let shankAzG = Double(readFloatLE(bytes, &offset))
        let shankGxRadS = Double(readFloatLE(bytes, &offset))
        let shankGyRadS = Double(readFloatLE(bytes, &offset))
        let shankGzRadS = Double(readFloatLE(bytes, &offset))

        let thighAxG = Double(readFloatLE(bytes, &offset))
        let thighAyG = Double(readFloatLE(bytes, &offset))
        let thighAzG = Double(readFloatLE(bytes, &offset))
        let thighGxRadS = Double(readFloatLE(bytes, &offset))
        let thighGyRadS = Double(readFloatLE(bytes, &offset))
        let thighGzRadS = Double(readFloatLE(bytes, &offset))

        let heelFsrRaw = Int(readUInt16LE(bytes, &offset))
        let midfootFsrRaw = Int(readUInt16LE(bytes, &offset))

        return SensorSample(
            timestampUs: timestampUs,
            sampleId: sampleId,
            footAxG: footAxG, footAyG: footAyG, footAzG: footAzG,
            footGxRadS: footGxRadS, footGyRadS: footGyRadS, footGzRadS: footGzRadS,
            shankAxG: shankAxG, shankAyG: shankAyG, shankAzG: shankAzG,
            shankGxRadS: shankGxRadS, shankGyRadS: shankGyRadS, shankGzRadS: shankGzRadS,
            thighAxG: thighAxG, thighAyG: thighAyG, thighAzG: thighAzG,
            thighGxRadS: thighGxRadS, thighGyRadS: thighGyRadS, thighGzRadS: thighGzRadS,
            heelFsrRaw: heelFsrRaw, midfootFsrRaw: midfootFsrRaw
        )
    }

    private static func uuidFromBytes(_ bytes: [UInt8]) -> UUID {
        let tuple = (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                     bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return UUID(uuid: tuple)
    }
}
