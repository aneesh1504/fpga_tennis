import Foundation

struct LatestFrameQueue {
    private var currentFrame: Data?
    private var currentOffset = 0
    private var latestPendingFrame: Data?

    private(set) var droppedFrameCount: UInt64 = 0
    private(set) var completedFrameCount: UInt64 = 0

    var isEmpty: Bool { currentFrame == nil }
    var isBackpressured: Bool { currentFrame != nil }

    mutating func enqueue(_ frame: Data) {
        guard !frame.isEmpty else { return }

        guard currentFrame != nil else {
            currentFrame = frame
            currentOffset = 0
            return
        }

        if currentOffset == 0 {
            currentFrame = frame
            droppedFrameCount &+= 1
            return
        }

        if latestPendingFrame != nil {
            droppedFrameCount &+= 1
        }
        latestPendingFrame = frame
    }

    mutating func nextChunk(maximumLength: Int) -> Data? {
        precondition(maximumLength > 0)
        guard let frame = currentFrame else { return nil }

        let end = min(frame.count, currentOffset + maximumLength)
        let chunk = frame.subdata(in: currentOffset..<end)
        currentOffset = end

        if currentOffset == frame.count {
            completedFrameCount &+= 1
            currentFrame = latestPendingFrame
            latestPendingFrame = nil
            currentOffset = 0
        }

        return chunk
    }

    mutating func removeAll() {
        if currentFrame != nil { droppedFrameCount &+= 1 }
        if latestPendingFrame != nil { droppedFrameCount &+= 1 }
        currentFrame = nil
        latestPendingFrame = nil
        currentOffset = 0
    }
}
