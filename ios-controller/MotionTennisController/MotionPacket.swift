import Foundation

enum ControllerRole: UInt8, CaseIterable, Identifiable {
    case player1 = 0x01
    case player2 = 0x02

    var id: UInt8 { rawValue }
    var title: String { self == .player1 ? "Player 1" : "Player 2" }
}

struct MotionVector: Equatable {
    var x: Double
    var y: Double
    var z: Double
}

struct MotionQuaternion: Equatable {
    var w: Double
    var x: Double
    var y: Double
    var z: Double
}

struct MotionMeasurement: Equatable {
    var timestampMilliseconds: UInt32
    var accelerationG: MotionVector
    var rotationRateRadiansPerSecond: MotionVector
    var attitude: MotionQuaternion
}

enum MotionPacketError: Error, Equatable {
    case nonFiniteValue
    case invalidPayloadLength(Int)
}

enum MotionProtocolV1 {
    static let version: UInt8 = 0x01
    static let messageTypeMotion: UInt8 = 0x01
    static let calibratedFlag: UInt8 = 0x01
    static let payloadByteCount = 32
    static let crcInputByteCount = 30
    static let terminator: UInt8 = 0x0a
    static let escape: UInt8 = 0x7d
    static let escapeXOR: UInt8 = 0x20
}

struct MotionPacketEncoder {
    static func encode(
        measurement: MotionMeasurement,
        role: ControllerRole,
        sequence: UInt16,
        calibrated: Bool
    ) throws -> Data {
        let raw = try rawPayload(
            measurement: measurement,
            role: role,
            sequence: sequence,
            calibrated: calibrated
        )
        return frame(rawPayload: raw)
    }

    static func rawPayload(
        measurement: MotionMeasurement,
        role: ControllerRole,
        sequence: UInt16,
        calibrated: Bool
    ) throws -> Data {
        var payload = Data()
        payload.reserveCapacity(MotionProtocolV1.payloadByteCount)
        payload.append(MotionProtocolV1.version)
        payload.append(MotionProtocolV1.messageTypeMotion)
        payload.append(role.rawValue)
        payload.append(calibrated ? MotionProtocolV1.calibratedFlag : 0)
        payload.appendLittleEndian(sequence)
        payload.appendLittleEndian(measurement.timestampMilliseconds)

        for value in [
            measurement.accelerationG.x,
            measurement.accelerationG.y,
            measurement.accelerationG.z
        ] {
            payload.appendLittleEndian(try quantize(value, scale: 4096, minimum: -32768, maximum: 32767))
        }

        for value in [
            measurement.rotationRateRadiansPerSecond.x,
            measurement.rotationRateRadiansPerSecond.y,
            measurement.rotationRateRadiansPerSecond.z
        ] {
            payload.appendLittleEndian(try quantize(value, scale: 512, minimum: -32768, maximum: 32767))
        }

        for value in [
            measurement.attitude.w,
            measurement.attitude.x,
            measurement.attitude.y,
            measurement.attitude.z
        ] {
            let clamped = min(1, max(-1, value))
            payload.appendLittleEndian(try quantize(clamped, scale: 32767, minimum: -32767, maximum: 32767))
        }

        precondition(payload.count == MotionProtocolV1.crcInputByteCount)
        payload.appendLittleEndian(crc16CCITTFalse(payload))
        precondition(payload.count == MotionProtocolV1.payloadByteCount)
        return payload
    }

    static func frame(rawPayload: Data) -> Data {
        var framed = Data()
        framed.reserveCapacity(rawPayload.count + 1)
        for byte in rawPayload {
            if byte == MotionProtocolV1.terminator || byte == MotionProtocolV1.escape {
                framed.append(MotionProtocolV1.escape)
                framed.append(byte ^ MotionProtocolV1.escapeXOR)
            } else {
                framed.append(byte)
            }
        }
        framed.append(MotionProtocolV1.terminator)
        return framed
    }

    static func crc16CCITTFalse<S: Sequence>(_ bytes: S) -> UInt16 where S.Element == UInt8 {
        var crc: UInt16 = 0xffff
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1
            }
        }
        return crc
    }

    static func hasValidCRC(_ rawPayload: Data) -> Bool {
        guard rawPayload.count == MotionProtocolV1.payloadByteCount else { return false }
        let stored = UInt16(rawPayload[30]) | (UInt16(rawPayload[31]) << 8)
        return crc16CCITTFalse(rawPayload.prefix(MotionProtocolV1.crcInputByteCount)) == stored
    }

    private static func quantize(
        _ value: Double,
        scale: Double,
        minimum: Int,
        maximum: Int
    ) throws -> Int16 {
        guard value.isFinite else { throw MotionPacketError.nonFiniteValue }
        let rounded = (value * scale).rounded(.toNearestOrAwayFromZero)
        let bounded = min(Double(maximum), max(Double(minimum), rounded))
        return Int16(bounded)
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
