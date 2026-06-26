import Foundation
@testable import KnevoPatient
import Testing

@Suite("KnevoCodec")
struct KnevoCodecTests {
    // MARK: - Little-endian helpers for building expected/test buffers

    private func appendUInt16LE(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
    }

    private func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        for index in 0 ..< 4 {
            data.append(UInt8((value >> (8 * index)) & 0xFF))
        }
    }

    private func appendUInt64LE(_ value: UInt64, to data: inout Data) {
        for index in 0 ..< 8 {
            data.append(UInt8((value >> (8 * UInt64(index))) & 0xFF))
        }
    }

    private func appendFloatLE(_ value: Float, to data: inout Data) {
        appendUInt32LE(value.bitPattern, to: &data)
    }

    private func uuidBytes(_ uuid: UUID) -> [UInt8] {
        let raw = uuid.uuid
        return [raw.0, raw.1, raw.2, raw.3, raw.4, raw.5, raw.6, raw.7,
                raw.8, raw.9, raw.10, raw.11, raw.12, raw.13, raw.14, raw.15]
    }

    // MARK: - WiFiConfig encode

    @Test("WiFiConfig encodes port, ip, lengths and UTF-8 payload")
    func encodeWiFiConfig() {
        let config = WiFiConfig(appPort: 0x1F90, appIP: [192, 168, 1, 42], ssid: "Net", password: "pw")
        let data = KnevoCodec.encodeWiFiConfig(config)
        let bytes = [UInt8](data)

        // port 0x1F90 little-endian
        #expect(bytes[0] == 0x90)
        #expect(bytes[1] == 0x1F)
        // ip
        #expect(Array(bytes[2 ..< 6]) == [192, 168, 1, 42])
        // ssid_len + ssid
        #expect(bytes[6] == 3)
        #expect(Array(bytes[7 ..< 10]) == Array("Net".utf8))
        // pass_len + pass
        #expect(bytes[10] == 2)
        #expect(Array(bytes[11 ..< 13]) == Array("pw".utf8))
        #expect(bytes.count == 13)
    }

    // MARK: - SetConfig encode

    @Test("SetConfig encodes UUID bytes then little-endian numerics")
    func encodeSetConfig() {
        let uuid = UUID()
        let config = SetConfig(
            setRecordId: uuid,
            durationS: 0x0102,
            maxSpeed: 1.5,
            maxExtensionAngleDeg: 90.0,
            maxFlexionAngleDeg: 10.25
        )
        let data = KnevoCodec.encodeSetConfig(config)
        let bytes = [UInt8](data)

        #expect(Array(bytes[0 ..< 16]) == uuidBytes(uuid))
        // duration 0x0102 little-endian
        #expect(bytes[16] == 0x02)
        #expect(bytes[17] == 0x01)
        // floats little-endian
        #expect(Array(bytes[18 ..< 22]) == leFloatBytes(1.5))
        #expect(Array(bytes[22 ..< 26]) == leFloatBytes(90.0))
        #expect(Array(bytes[26 ..< 30]) == leFloatBytes(10.25))
        #expect(bytes.count == 30)
    }

    private func leFloatBytes(_ value: Float) -> [UInt8] {
        var out: [UInt8] = []
        let bits = value.bitPattern
        for index in 0 ..< 4 {
            out.append(UInt8((bits >> (8 * index)) & 0xFF))
        }
        return out
    }

    // MARK: - Control

    @Test("Control encodes single command byte")
    func encodeControl() {
        #expect([UInt8](KnevoCodec.encodeControl(.start)) == [0x01])
        #expect([UInt8](KnevoCodec.encodeControl(.stop)) == [0x02])
        #expect([UInt8](KnevoCodec.encodeControl(.calibrateUnloaded)) == [0x10])
        #expect([UInt8](KnevoCodec.encodeControl(.calibrateStatic)) == [0x11])
    }

    @Test("Control raw values map to the documented opcodes")
    func controlRawValues() {
        #expect(Control(rawValue: 0x10) == .calibrateUnloaded)
        #expect(Control(rawValue: 0x11) == .calibrateStatic)
    }

    // MARK: - WiFiStatus decode

    @Test("WiFiStatus decodes ok and error code")
    func decodeWiFiStatus() throws {
        let okStatus = try KnevoCodec.decodeWiFiStatus(Data([0, 0]))
        #expect(okStatus == WiFiStatus(ok: true, errorCode: 0))

        let failStatus = try KnevoCodec.decodeWiFiStatus(Data([1, 3]))
        #expect(failStatus == WiFiStatus(ok: false, errorCode: 3))
    }

    @Test("WiFiStatus throws on short buffer")
    func decodeWiFiStatusShort() {
        #expect(throws: KnevoCodecError.bufferTooShort) {
            try KnevoCodec.decodeWiFiStatus(Data([0]))
        }
    }

    // MARK: - DeviceStatus decode

    @Test("DeviceStatus decodes state, battery, fault")
    func decodeDeviceStatus() throws {
        let status = try KnevoCodec.decodeDeviceStatus(Data([1, 77, 0]))
        #expect(status == DeviceStatus(state: .running, batteryPct: 77, faultCode: 0))

        let done = try KnevoCodec.decodeDeviceStatus(Data([2, 100, 0]))
        #expect(done.state == .done)
    }

    // MARK: - TCP sensor frame decode

    private func sampleFloats(base: Float) -> [Float] {
        (0 ..< 18).map { base + Float($0) }
    }

    private func buildFrame(
        setRecordId: UUID,
        sampleCount: Int,
        sampleSize: UInt16 = 88,
        magic: String = "KNVO",
        version: UInt8 = 1,
        overrideFrameLen: UInt32? = nil
    ) -> (Data, [SensorSample]) {
        var header = Data()
        header.append(contentsOf: Array(magic.utf8))
        header.append(version)
        header.append(0) // flags
        header.append(contentsOf: uuidBytes(setRecordId))
        appendUInt32LE(UInt32(sampleCount), to: &header)
        appendUInt16LE(sampleSize, to: &header)

        var records = Data()
        var expected: [SensorSample] = []
        for index in 0 ..< sampleCount {
            let timestamp = Int64(1_719_300_000_000_000 + index)
            let sid = Int32(index)
            let floats = sampleFloats(base: Float(index) * 0.5)
            let heel = UInt16(1000 + index)
            let mid = UInt16(200 + index)

            appendUInt64LE(UInt64(bitPattern: timestamp), to: &records)
            appendUInt32LE(UInt32(bitPattern: sid), to: &records)
            for value in floats {
                appendFloatLE(value, to: &records)
            }
            appendUInt16LE(heel, to: &records)
            appendUInt16LE(mid, to: &records)

            expected.append(SensorSample(
                timestampUs: timestamp, sampleId: Int(sid),
                footAxG: Double(floats[0]), footAyG: Double(floats[1]), footAzG: Double(floats[2]),
                footGxRadS: Double(floats[3]), footGyRadS: Double(floats[4]), footGzRadS: Double(floats[5]),
                shankAxG: Double(floats[6]), shankAyG: Double(floats[7]), shankAzG: Double(floats[8]),
                shankGxRadS: Double(floats[9]), shankGyRadS: Double(floats[10]), shankGzRadS: Double(floats[11]),
                thighAxG: Double(floats[12]), thighAyG: Double(floats[13]), thighAzG: Double(floats[14]),
                thighGxRadS: Double(floats[15]), thighGyRadS: Double(floats[16]), thighGzRadS: Double(floats[17]),
                heelFsrRaw: Int(heel), midfootFsrRaw: Int(mid)
            ))
        }

        let frameLen = overrideFrameLen ?? UInt32(header.count + records.count)
        var data = Data()
        appendUInt32LE(frameLen, to: &data)
        data.append(header)
        data.append(records)
        return (data, expected)
    }

    @Test("Sensor frame decodes samples and setRecordId")
    func decodeSensorFrame() throws {
        let uuid = UUID()
        let (data, expected) = buildFrame(setRecordId: uuid, sampleCount: 3)
        let batch = try KnevoCodec.decodeSensorBatch(data)
        #expect(batch.setRecordId == uuid)
        #expect(batch.samples.count == 3)
        #expect(batch.samples == expected)
    }

    @Test("Sensor frame throws on truncated buffer")
    func decodeSensorFrameTruncated() {
        let (data, _) = buildFrame(setRecordId: UUID(), sampleCount: 2)
        let truncated = data.prefix(data.count - 10)
        #expect(throws: KnevoCodecError.self) {
            try KnevoCodec.decodeSensorBatch(Data(truncated))
        }
    }

    @Test("Sensor frame throws on bad magic")
    func decodeSensorFrameBadMagic() {
        let (data, _) = buildFrame(setRecordId: UUID(), sampleCount: 1, magic: "XXXX")
        #expect(throws: KnevoCodecError.badMagic) {
            try KnevoCodec.decodeSensorBatch(data)
        }
    }

    @Test("Sensor frame throws on bad version")
    func decodeSensorFrameBadVersion() {
        let (data, _) = buildFrame(setRecordId: UUID(), sampleCount: 1, version: 2)
        #expect(throws: KnevoCodecError.unsupportedVersion(2)) {
            try KnevoCodec.decodeSensorBatch(data)
        }
    }

    @Test("Sensor frame throws on wrong sample size")
    func decodeSensorFrameBadSampleSize() {
        // sample_size field says 80 but records are still built at 88 bytes;
        // override frame_len so it fails on sample_size, not length, first.
        let (data, _) = buildFrame(setRecordId: UUID(), sampleCount: 1, sampleSize: 80)
        #expect(throws: KnevoCodecError.badSampleSize(80)) {
            try KnevoCodec.decodeSensorBatch(data)
        }
    }

    // MARK: - SensorSample JSON keys (§5.1)

    @Test("SensorSample JSON uses backend camelCase keys")
    func sensorSampleJSONKeys() throws {
        let sample = SensorSample(
            timestampUs: 1_719_300_000_000_123, sampleId: 0,
            footAxG: 0.0123, footAyG: -0.98, footAzG: 0.10,
            footGxRadS: 0.01, footGyRadS: 0.0, footGzRadS: -0.02,
            shankAxG: 0, shankAyG: 0, shankAzG: 0,
            shankGxRadS: 0, shankGyRadS: 0, shankGzRadS: 0,
            thighAxG: 0, thighAyG: 0, thighAzG: 0,
            thighGxRadS: 0, thighGyRadS: 0, thighGzRadS: 0,
            heelFsrRaw: 1024, midfootFsrRaw: 256
        )
        let json = try #require(String(data: JSONEncoder().encode(sample), encoding: .utf8))
        let keys = ["timestampUs", "sampleId", "footAxG", "footGxRadS", "shankAxG", "thighGzRadS", "heelFsrRaw", "midfootFsrRaw"]
        for key in keys {
            #expect(json.contains("\"\(key)\""), "missing key \(key)")
        }
    }

    // MARK: - Sensor frame encode round-trip (§4)

    private func makeSample(index: Int) -> SensorSample {
        // Use Float-representable values so encode (Double→Float) then
        // decode (Float→Double) round-trips exactly.
        let floats = sampleFloats(base: Float(index) * 0.5)
        return SensorSample(
            timestampUs: Int64(1_719_300_000_000_000 + index), sampleId: index,
            footAxG: Double(floats[0]), footAyG: Double(floats[1]), footAzG: Double(floats[2]),
            footGxRadS: Double(floats[3]), footGyRadS: Double(floats[4]), footGzRadS: Double(floats[5]),
            shankAxG: Double(floats[6]), shankAyG: Double(floats[7]), shankAzG: Double(floats[8]),
            shankGxRadS: Double(floats[9]), shankGyRadS: Double(floats[10]), shankGzRadS: Double(floats[11]),
            thighAxG: Double(floats[12]), thighAyG: Double(floats[13]), thighAzG: Double(floats[14]),
            thighGxRadS: Double(floats[15]), thighGyRadS: Double(floats[16]), thighGzRadS: Double(floats[17]),
            heelFsrRaw: 1000 + index, midfootFsrRaw: 200 + index
        )
    }

    @Test("encodeSensorBatch then decodeSensorBatch round-trips")
    func encodeDecodeRoundTrip() throws {
        let uuid = UUID()
        let samples = (0 ..< 5).map { makeSample(index: $0) }
        let data = KnevoCodec.encodeSensorBatch(setRecordId: uuid, samples: samples)
        let batch = try KnevoCodec.decodeSensorBatch(data)
        #expect(batch.setRecordId == uuid)
        #expect(batch.samples == samples)
    }

    @Test("encodeSensorBatch produces a valid §4 frame layout")
    func encodeSensorBatchLayout() {
        let uuid = UUID()
        let data = KnevoCodec.encodeSensorBatch(setRecordId: uuid, samples: [makeSample(index: 0)])
        let bytes = [UInt8](data)
        // frame_len = header(28) + 1 record(88) = 116
        #expect(bytes[0] == 116)
        #expect(Array(bytes[4 ..< 8]) == Array("KNVO".utf8))
        #expect(bytes[8] == 1) // version
        #expect(bytes[9] == 0) // flags
        #expect(Array(bytes[10 ..< 26]) == uuidBytes(uuid))
        #expect(bytes.count == 4 + 116)
    }

    // MARK: - Round-trip: encode SetConfig then decode the UUID portion

    @Test("SensorBatch decode preserves first sample values")
    func decodeFirstSampleValues() throws {
        let (data, expected) = buildFrame(setRecordId: UUID(), sampleCount: 1)
        let batch = try KnevoCodec.decodeSensorBatch(data)
        let sample = try #require(batch.samples.first)
        #expect(sample.timestampUs == expected[0].timestampUs)
        #expect(sample.footAxG == expected[0].footAxG)
        #expect(sample.heelFsrRaw == expected[0].heelFsrRaw)
        #expect(sample.midfootFsrRaw == expected[0].midfootFsrRaw)
    }
}
