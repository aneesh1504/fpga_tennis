import XCTest
@testable import MotionTennisController

final class MotionPacketTests: XCTestCase {
    private struct GoldenFile: Decodable {
        let vectors: [GoldenVector]
    }

    private struct GoldenVector: Decodable {
        let name: String
        let sequence: UInt16
        let accepted: Bool
        let rawHex: String
        let framedHex: String

        enum CodingKeys: String, CodingKey {
            case name, sequence, accepted
            case rawHex = "raw_hex"
            case framedHex = "framed_hex"
        }
    }

    func testFrozenGoldenVectorsMatchCRCAndFraming() throws {
        for vector in try goldenVectors() {
            let raw = try Data(hex: vector.rawHex)
            XCTAssertEqual(MotionPacketEncoder.hasValidCRC(raw), vector.accepted, vector.name)
            XCTAssertEqual(MotionPacketEncoder.frame(rawPayload: raw), try Data(hex: vector.framedHex), vector.name)
            XCTAssertEqual(raw.uint16LittleEndian(at: 4), vector.sequence, vector.name)
        }
    }

    func testEncoderReproducesProducerRepresentableGoldenVectors() throws {
        let representable = Set([
            "normal_values",
            "escaped_terminator_and_escape",
            "sequence_wrap_before",
            "sequence_wrap_after"
        ])

        for vector in try goldenVectors() where representable.contains(vector.name) {
            let raw = try Data(hex: vector.rawHex)
            let encoded = try MotionPacketEncoder.encode(
                measurement: measurement(from: raw),
                role: ControllerRole(rawValue: raw[2])!,
                sequence: raw.uint16LittleEndian(at: 4),
                calibrated: raw[3] & 0x01 != 0
            )
            XCTAssertEqual(encoded, try Data(hex: vector.framedHex), vector.name)
        }
    }

    func testQuantizationRoundsAwayFromZeroAndSaturates() throws {
        let measurement = MotionMeasurement(
            timestampMilliseconds: 1,
            accelerationG: MotionVector(x: 0.5 / 4096, y: -0.5 / 4096, z: 100),
            rotationRateRadiansPerSecond: MotionVector(x: -100, y: 0, z: 0),
            attitude: MotionQuaternion(w: 2, x: -2, y: 0, z: 0)
        )
        let raw = try MotionPacketEncoder.rawPayload(
            measurement: measurement,
            role: .player1,
            sequence: 0,
            calibrated: true
        )

        XCTAssertEqual(raw.int16LittleEndian(at: 10), 1)
        XCTAssertEqual(raw.int16LittleEndian(at: 12), -1)
        XCTAssertEqual(raw.int16LittleEndian(at: 14), 32767)
        XCTAssertEqual(raw.int16LittleEndian(at: 16), -32768)
        XCTAssertEqual(raw.int16LittleEndian(at: 22), 32767)
        XCTAssertEqual(raw.int16LittleEndian(at: 24), -32767)
    }

    func testNonFiniteSensorValueIsRejected() {
        let measurement = MotionMeasurement(
            timestampMilliseconds: 0,
            accelerationG: MotionVector(x: .nan, y: 0, z: 0),
            rotationRateRadiansPerSecond: MotionVector(x: 0, y: 0, z: 0),
            attitude: MotionQuaternion(w: 1, x: 0, y: 0, z: 0)
        )
        XCTAssertThrowsError(try MotionPacketEncoder.encode(
            measurement: measurement,
            role: .player1,
            sequence: 0,
            calibrated: false
        )) { error in
            XCTAssertEqual(error as? MotionPacketError, .nonFiniteValue)
        }
    }

    private func goldenVectors() throws -> [GoldenVector] {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "motion_protocol_v1", withExtension: "json"))
        return try JSONDecoder().decode(GoldenFile.self, from: Data(contentsOf: url)).vectors
    }

    private func measurement(from raw: Data) -> MotionMeasurement {
        MotionMeasurement(
            timestampMilliseconds: raw.uint32LittleEndian(at: 6),
            accelerationG: MotionVector(
                x: Double(raw.int16LittleEndian(at: 10)) / 4096,
                y: Double(raw.int16LittleEndian(at: 12)) / 4096,
                z: Double(raw.int16LittleEndian(at: 14)) / 4096
            ),
            rotationRateRadiansPerSecond: MotionVector(
                x: Double(raw.int16LittleEndian(at: 16)) / 512,
                y: Double(raw.int16LittleEndian(at: 18)) / 512,
                z: Double(raw.int16LittleEndian(at: 20)) / 512
            ),
            attitude: MotionQuaternion(
                w: Double(raw.int16LittleEndian(at: 22)) / 32767,
                x: Double(raw.int16LittleEndian(at: 24)) / 32767,
                y: Double(raw.int16LittleEndian(at: 26)) / 32767,
                z: Double(raw.int16LittleEndian(at: 28)) / 32767
            )
        )
    }
}

private extension Data {
    init(hex: String) throws {
        self.init()
        guard hex.count.isMultiple(of: 2) else { throw HexError.invalid }
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { throw HexError.invalid }
            append(byte)
            index = next
        }
    }

    func uint16LittleEndian(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func uint32LittleEndian(at offset: Int) -> UInt32 {
        UInt32(self[offset])
            | (UInt32(self[offset + 1]) << 8)
            | (UInt32(self[offset + 2]) << 16)
            | (UInt32(self[offset + 3]) << 24)
    }

    func int16LittleEndian(at offset: Int) -> Int16 {
        Int16(bitPattern: uint16LittleEndian(at: offset))
    }
}

private enum HexError: Error { case invalid }
