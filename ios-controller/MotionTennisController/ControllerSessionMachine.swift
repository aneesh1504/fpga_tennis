import Foundation

enum ControllerSessionPhase: Equatable {
    case disconnected
    case scanning
    case connected
    case ready
    case calibrating
    case streaming
    case backpressured
    case failed(String)

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning"
        case .connected: return "Connected — select write channel"
        case .ready: return "Ready"
        case .calibrating: return "Calibrating"
        case .streaming: return "Streaming"
        case .backpressured: return "BLE backpressure"
        case .failed(let message): return "Error: \(message)"
        }
    }
}

enum ControllerSessionEvent: Equatable {
    case scanStarted
    case connected
    case writeChannelSelected
    case disconnected
    case calibrationStarted
    case calibrated
    case streamingStarted
    case streamingStopped
    case backpressureChanged(Bool)
    case failed(String)
}

struct ControllerSessionMachine {
    private(set) var phase: ControllerSessionPhase = .disconnected
    private(set) var calibrated = false
    private(set) var writeChannelSelected = false
    private(set) var streaming = false

    mutating func apply(_ event: ControllerSessionEvent) {
        switch event {
        case .scanStarted:
            guard !streaming else { return }
            phase = .scanning
        case .connected:
            streaming = false
            writeChannelSelected = false
            phase = .connected
        case .writeChannelSelected:
            writeChannelSelected = true
            phase = calibrated ? .ready : .connected
        case .disconnected:
            streaming = false
            writeChannelSelected = false
            phase = .disconnected
        case .calibrationStarted:
            guard !streaming else { return }
            phase = .calibrating
        case .calibrated:
            calibrated = true
            phase = writeChannelSelected ? .ready : .connected
        case .streamingStarted:
            guard calibrated, writeChannelSelected else { return }
            streaming = true
            phase = .streaming
        case .streamingStopped:
            streaming = false
            phase = writeChannelSelected && calibrated ? .ready : .connected
        case .backpressureChanged(let active):
            guard streaming else { return }
            phase = active ? .backpressured : .streaming
        case .failed(let message):
            streaming = false
            phase = .failed(message)
        }
    }
}
