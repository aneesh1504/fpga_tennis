import Combine
import Foundation

final class ControllerViewModel: ObservableObject {
    @Published var selectedRole: ControllerRole = .player1
    @Published private(set) var phase: ControllerSessionPhase = .disconnected
    @Published private(set) var lastSequence: UInt16?
    @Published private(set) var generatedSampleCount: UInt64 = 0
    @Published private(set) var observedSampleRate: Double = 0
    @Published private(set) var lastError: String?

    let ble: BLEManager

    var isStreaming: Bool { machine.streaming }
    var isCalibrated: Bool { machine.calibrated }
    var canStartStreaming: Bool { machine.calibrated && ble.isReady && !machine.streaming }

    private let sampler: MotionSampler
    private var machine = ControllerSessionMachine()
    private var nextSequence: UInt16 = 0
    private var rateWindowStart = Date()
    private var rateWindowSamples = 0
    private var cancellables: Set<AnyCancellable> = []

    init(ble: BLEManager = BLEManager(), sampler: MotionSampler = MotionSampler()) {
        self.ble = ble
        self.sampler = sampler

        ble.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        ble.$state
            .sink { [weak self] state in self?.handleBLEState(state) }
            .store(in: &cancellables)

        ble.$selectedCharacteristicID
            .compactMap { $0 }
            .sink { [weak self] _ in self?.apply(.writeChannelSelected) }
            .store(in: &cancellables)

        ble.$isBackpressured
            .removeDuplicates()
            .sink { [weak self] active in self?.apply(.backpressureChanged(active)) }
            .store(in: &cancellables)

        do {
            try sampler.start { [weak self] result in self?.handleMotion(result) }
        } catch {
            fail(error.localizedDescription)
        }
    }

    func startScanning() {
        ble.startScanning()
    }

    func calibrate() {
        apply(.calibrationStarted)
        do {
            try sampler.calibrate()
            apply(.calibrated)
        } catch {
            fail(error.localizedDescription)
        }
    }

    func startStreaming() {
        guard canStartStreaming else {
            fail("Select a BLE write channel and calibrate before streaming.")
            return
        }
        rateWindowStart = Date()
        rateWindowSamples = 0
        apply(.streamingStarted)
    }

    func stopStreaming() {
        apply(.streamingStopped)
    }

    private func handleMotion(_ result: Result<MotionMeasurement, Error>) {
        switch result {
        case .failure(let error):
            fail(error.localizedDescription)
        case .success(let measurement):
            guard machine.streaming else { return }
            let sequence = nextSequence
            nextSequence &+= 1
            generatedSampleCount &+= 1
            rateWindowSamples += 1
            lastSequence = sequence

            do {
                let frame = try MotionPacketEncoder.encode(
                    measurement: measurement,
                    role: selectedRole,
                    sequence: sequence,
                    calibrated: machine.calibrated
                )
                ble.enqueue(frame: frame)
                updateObservedRate()
            } catch {
                fail(error.localizedDescription)
            }
        }
    }

    private func updateObservedRate() {
        let elapsed = Date().timeIntervalSince(rateWindowStart)
        guard elapsed >= 1 else { return }
        observedSampleRate = Double(rateWindowSamples) / elapsed
        rateWindowStart = Date()
        rateWindowSamples = 0
    }

    private func handleBLEState(_ state: BLEConnectionState) {
        switch state {
        case .scanning: apply(.scanStarted)
        case .connecting, .discovering: apply(.connected)
        case .reconnecting: apply(.reconnecting)
        case .ready: apply(.writeChannelSelected)
        case .disconnected(let message):
            apply(.disconnected)
            if let message { lastError = message }
        case .unavailable(let message): fail(message)
        case .idle: break
        }
    }

    private func apply(_ event: ControllerSessionEvent) {
        machine.apply(event)
        phase = machine.phase
        if case .failed(let message) = phase { lastError = message }
    }

    private func fail(_ message: String) {
        apply(.failed(message))
    }
}
