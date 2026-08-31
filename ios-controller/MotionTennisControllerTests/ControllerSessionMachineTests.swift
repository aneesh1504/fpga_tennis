import XCTest
@testable import MotionTennisController

final class ControllerSessionMachineTests: XCTestCase {
    func testHappyPathRequiresWriteChannelAndCalibration() {
        var machine = ControllerSessionMachine()
        machine.apply(.scanStarted)
        XCTAssertEqual(machine.phase, .scanning)

        machine.apply(.connected)
        machine.apply(.streamingStarted)
        XCTAssertFalse(machine.streaming)

        machine.apply(.writeChannelSelected)
        machine.apply(.calibrationStarted)
        machine.apply(.calibrated)
        XCTAssertEqual(machine.phase, .ready)

        machine.apply(.streamingStarted)
        XCTAssertEqual(machine.phase, .streaming)
        XCTAssertTrue(machine.streaming)
    }

    func testBackpressureAndRecoveryRemainStreaming() {
        var machine = readyMachine()
        machine.apply(.streamingStarted)
        machine.apply(.backpressureChanged(true))
        XCTAssertEqual(machine.phase, .backpressured)
        XCTAssertTrue(machine.streaming)

        machine.apply(.backpressureChanged(false))
        XCTAssertEqual(machine.phase, .streaming)
        XCTAssertTrue(machine.streaming)
    }

    func testDisconnectClearsWriteChannelAndStreamingButKeepsCalibration() {
        var machine = readyMachine()
        machine.apply(.streamingStarted)
        machine.apply(.disconnected)

        XCTAssertEqual(machine.phase, .disconnected)
        XCTAssertFalse(machine.streaming)
        XCTAssertFalse(machine.writeChannelSelected)
        XCTAssertTrue(machine.calibrated)
    }

    func testFailureStopsStreaming() {
        var machine = readyMachine()
        machine.apply(.streamingStarted)
        machine.apply(.failed("test"))

        XCTAssertEqual(machine.phase, .failed("test"))
        XCTAssertFalse(machine.streaming)
    }

    func testReconnectRequiresRediscoveryThenCanResume() {
        var machine = readyMachine()
        machine.apply(.streamingStarted)
        machine.apply(.reconnecting)
        XCTAssertEqual(machine.phase, .reconnecting)
        XCTAssertFalse(machine.streaming)
        XCTAssertFalse(machine.writeChannelSelected)

        machine.apply(.connected)
        machine.apply(.writeChannelSelected)
        XCTAssertEqual(machine.phase, .ready)
        machine.apply(.streamingStarted)
        XCTAssertTrue(machine.streaming)
    }

    private func readyMachine() -> ControllerSessionMachine {
        var machine = ControllerSessionMachine()
        machine.apply(.connected)
        machine.apply(.writeChannelSelected)
        machine.apply(.calibrated)
        return machine
    }
}
