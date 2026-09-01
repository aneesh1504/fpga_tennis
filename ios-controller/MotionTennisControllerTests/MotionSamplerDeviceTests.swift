import XCTest
@testable import MotionTennisController

final class MotionSamplerDeviceTests: XCTestCase {
    func testPhysicalDeviceProducesMotionAndCalibrates() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("Core Motion device evidence requires a physical iPhone.")
#else
        let sampler = MotionSampler()
        let sampleReceived = expectation(description: "Receive a processed Core Motion sample")
        var firstError: Error?

        try sampler.start { result in
            switch result {
            case .success:
                sampleReceived.fulfill()
            case .failure(let error):
                firstError = error
                sampleReceived.fulfill()
            }
        }
        defer { sampler.stop() }

        wait(for: [sampleReceived], timeout: 3.0)
        XCTAssertNil(firstError)
        XCTAssertNoThrow(try sampler.calibrate())
#endif
    }
}
