import CoreMotion
import Foundation

final class MotionSampler {
    typealias Handler = (Result<MotionMeasurement, Error>) -> Void

    enum SamplerError: LocalizedError {
        case unavailable
        case noSampleForCalibration

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Processed device motion is unavailable on this device."
            case .noSampleForCalibration: return "Wait for a motion sample before calibrating."
            }
        }
    }

    private let manager: CMMotionManager
    private var latestQuaternion: MotionQuaternion?
    private var neutralInverse: MotionQuaternion?
    private var handler: Handler?

    private(set) var isCalibrated = false

    init(manager: CMMotionManager = CMMotionManager()) {
        self.manager = manager
    }

    func start(handler: @escaping Handler) throws {
        guard manager.isDeviceMotionAvailable else { throw SamplerError.unavailable }
        guard !manager.isDeviceMotionActive else {
            self.handler = handler
            return
        }

        self.handler = handler
        manager.deviceMotionUpdateInterval = 1.0 / 50.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, error in
            guard let self else { return }
            if let error {
                self.handler?(.failure(error))
                return
            }
            guard let motion else { return }
            self.publish(motion)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        handler = nil
    }

    func calibrate() throws {
        guard let latestQuaternion else { throw SamplerError.noSampleForCalibration }
        neutralInverse = latestQuaternion.conjugated.normalized
        isCalibrated = true
    }

    private func publish(_ motion: CMDeviceMotion) {
        let absolute = MotionQuaternion(
            w: motion.attitude.quaternion.w,
            x: motion.attitude.quaternion.x,
            y: motion.attitude.quaternion.y,
            z: motion.attitude.quaternion.z
        ).normalized
        latestQuaternion = absolute
        let relative = neutralInverse.map { ($0 * absolute).normalized } ?? absolute
        let monotonicMilliseconds = UInt64((motion.timestamp * 1000).rounded())
        let timestampMilliseconds = UInt32(truncatingIfNeeded: monotonicMilliseconds)

        handler?(.success(MotionMeasurement(
            timestampMilliseconds: timestampMilliseconds,
            accelerationG: MotionVector(
                x: motion.userAcceleration.x,
                y: motion.userAcceleration.y,
                z: motion.userAcceleration.z
            ),
            rotationRateRadiansPerSecond: MotionVector(
                x: motion.rotationRate.x,
                y: motion.rotationRate.y,
                z: motion.rotationRate.z
            ),
            attitude: relative
        )))
    }
}

private extension MotionQuaternion {
    var conjugated: MotionQuaternion {
        MotionQuaternion(w: w, x: -x, y: -y, z: -z)
    }

    var normalized: MotionQuaternion {
        let magnitude = sqrt(w * w + x * x + y * y + z * z)
        guard magnitude > 0 else { return MotionQuaternion(w: 1, x: 0, y: 0, z: 0) }
        return MotionQuaternion(w: w / magnitude, x: x / magnitude, y: y / magnitude, z: z / magnitude)
    }

    static func * (lhs: MotionQuaternion, rhs: MotionQuaternion) -> MotionQuaternion {
        MotionQuaternion(
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w
        )
    }
}
