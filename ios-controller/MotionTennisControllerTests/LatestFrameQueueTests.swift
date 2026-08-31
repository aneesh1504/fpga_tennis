import XCTest
@testable import MotionTennisController

final class LatestFrameQueueTests: XCTestCase {
    func testBlockedUnstartedFrameIsReplacedByNewestSample() {
        var queue = LatestFrameQueue()
        queue.enqueue(Data([1, 2]))
        queue.enqueue(Data([3, 4]))

        XCTAssertEqual(queue.droppedFrameCount, 1)
        XCTAssertEqual(queue.nextChunk(maximumLength: 20), Data([3, 4]))
        XCTAssertTrue(queue.isEmpty)
    }

    func testPartiallyWrittenFrameFinishesBeforeNewestPendingFrame() {
        var queue = LatestFrameQueue()
        queue.enqueue(Data([1, 2, 3, 4]))
        XCTAssertEqual(queue.nextChunk(maximumLength: 2), Data([1, 2]))

        queue.enqueue(Data([5, 6]))
        queue.enqueue(Data([7, 8]))

        XCTAssertEqual(queue.droppedFrameCount, 1)
        XCTAssertEqual(queue.nextChunk(maximumLength: 2), Data([3, 4]))
        XCTAssertEqual(queue.nextChunk(maximumLength: 2), Data([7, 8]))
        XCTAssertEqual(queue.completedFrameCount, 2)
        XCTAssertTrue(queue.isEmpty)
    }

    func testChunkingPreservesByteOrder() {
        var queue = LatestFrameQueue()
        queue.enqueue(Data(0..<10))

        var reconstructed = Data()
        while let chunk = queue.nextChunk(maximumLength: 3) {
            reconstructed.append(chunk)
        }

        XCTAssertEqual(reconstructed, Data(0..<10))
        XCTAssertEqual(queue.completedFrameCount, 1)
    }

    func testDisconnectDropsQueuedFrames() {
        var queue = LatestFrameQueue()
        queue.enqueue(Data([1, 2, 3]))
        _ = queue.nextChunk(maximumLength: 1)
        queue.enqueue(Data([4, 5]))
        queue.removeAll()

        XCTAssertEqual(queue.droppedFrameCount, 2)
        XCTAssertTrue(queue.isEmpty)
    }
}
