import Combine
import CoreBluetooth
import XCTest
@testable import MotionTennisController

final class BLEDiscoveryDeviceTests: XCTestCase {
    @MainActor
    func testPhysicalDiscoveryReportsNearbyAdvertisements() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("BLE advertisement evidence requires a physical iPhone.")
#else
        let manager = BLEManager(configuration: .discovery)
        let scanFinished = expectation(description: "Scan nearby BLE advertisements")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            manager.startScanning()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
            manager.stopScanning()
            scanFinished.fulfill()
        }

        wait(for: [scanFinished], timeout: 13.0)

        let observations = manager.discoveredPeripherals.map {
            "name=\($0.name.debugDescription) rssi=\($0.rssi)"
        }
        print("FPGA_TENNIS_BLE_DISCOVERY_BEGIN")
        observations.forEach { print($0) }
        print("FPGA_TENNIS_BLE_DISCOVERY_END")

        XCTAssertFalse(
            observations.isEmpty,
            "No BLE advertisements were observed. Confirm Bluetooth permission and keep the programmed board powered."
        )
#endif
    }

    @MainActor
    func testObservedBooleanBoardGATTProfile() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("BLE GATT evidence requires a physical iPhone and powered Boolean Board.")
#else
        let profileReceived = expectation(description: "Discover the observed Boolean Board GATT profile")
        var result: Result<BLEGATTProfile, Error>?
        let harness = BLEGATTHarness(targetName: "RD_BOOL_88723523033D") { discovered in
            result = discovered
            profileReceived.fulfill()
        }

        harness.start()
        wait(for: [profileReceived], timeout: 20.0)

        let profile = try XCTUnwrap(result).get()
        print("FPGA_TENNIS_BLE_GATT_BEGIN")
        print("advertisedName=\(profile.advertisedName.debugDescription)")
        print("maximumWriteWithoutResponse=\(profile.maximumWriteWithoutResponse)")
        print("maximumWriteWithResponse=\(profile.maximumWriteWithResponse)")
        profile.characteristics.forEach {
            print("service=\($0.serviceUUID) characteristic=\($0.characteristicUUID) properties=\($0.properties.joined(separator: ","))")
        }
        print("FPGA_TENNIS_BLE_GATT_END")

        XCTAssertFalse(profile.characteristics.isEmpty)
        XCTAssertTrue(profile.characteristics.contains { observation in
            observation.properties.contains("write") || observation.properties.contains("writeWithoutResponse")
        })
#endif
    }

    @MainActor
    func testObservedBooleanBoardAcceptsUARTProbe() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("BLE UART probe requires a physical iPhone and powered Boolean Board.")
#else
        let writeAcknowledged = expectation(description: "Write 0x41 0x0A to the observed Boolean Board")
        var result: Result<BLEGATTProfile, Error>?
        let harness = BLEGATTHarness(
            targetName: "RD_BOOL_88723523033D",
            writeProbe: Data([0x41, 0x0A])
        ) { discovered in
            result = discovered
            writeAcknowledged.fulfill()
        }

        harness.start()
        wait(for: [writeAcknowledged], timeout: 20.0)
        _ = try XCTUnwrap(result).get()
        print("FPGA_TENNIS_BLE_UART_PROBE_ACK bytes=41 0A")
#endif
    }

    @MainActor
    func testTwoMinuteMotionStreamToObservedBooleanBoard() throws {
#if targetEnvironment(simulator)
        throw XCTSkip("The C1 stream requires a physical iPhone and powered Boolean Board.")
#else
        let manager = BLEManager()
        let viewModel = ControllerViewModel(ble: manager, sampler: MotionSampler())
        let boardReady = expectation(description: "Connect to the verified Boolean Board write characteristic")
        var cancellables: Set<AnyCancellable> = []
        var connectionStarted = false

        manager.$discoveredPeripherals
            .sink { peripherals in
                guard !connectionStarted,
                      let board = peripherals.first(where: { $0.name == "RD_BOOL_88723523033D" }) else { return }
                connectionStarted = true
                manager.connect(to: board.id)
            }
            .store(in: &cancellables)

        manager.$selectedCharacteristicID
            .compactMap { $0 }
            .first()
            .sink { _ in boardReady.fulfill() }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewModel.startScanning()
        }
        wait(for: [boardReady], timeout: 15.0)
        XCTAssertTrue(manager.isReady)

        let motionWarmup = expectation(description: "Receive initial Core Motion sample")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { motionWarmup.fulfill() }
        wait(for: [motionWarmup], timeout: 2.0)
        viewModel.calibrate()
        XCTAssertTrue(viewModel.isCalibrated, viewModel.lastError ?? "Calibration did not complete.")

        let streamDuration: TimeInterval = 120.0
        let streamFinished = expectation(description: "Stream motion frames for two continuous minutes")
        let streamStart = Date()
        viewModel.startStreaming()
        XCTAssertTrue(viewModel.isStreaming, viewModel.lastError ?? "Streaming did not start.")
        DispatchQueue.main.asyncAfter(deadline: .now() + streamDuration) { streamFinished.fulfill() }
        wait(for: [streamFinished], timeout: streamDuration + 5.0)
        let elapsed = Date().timeIntervalSince(streamStart)
        viewModel.stopStreaming()

        let generated = viewModel.generatedSampleCount
        let handedToBLE = manager.completedFrameCount
        let deliveryRatio = generated == 0 ? 0 : Double(handedToBLE) / Double(generated)
        let averageRate = Double(generated) / elapsed
        print("FPGA_TENNIS_C1_IOS_BEGIN")
        print("elapsedSeconds=\(String(format: "%.3f", elapsed))")
        print("generated=\(generated)")
        print("handedToBLE=\(handedToBLE)")
        print("droppedOrBackpressured=\(manager.droppedFrameCount)")
        print("averageGeneratedRateHz=\(String(format: "%.3f", averageRate))")
        print("iosDeliveryRatio=\(String(format: "%.6f", deliveryRatio))")
        print("lastSequence=\(viewModel.lastSequence.map(String.init) ?? "none")")
        print("FPGA_TENNIS_C1_IOS_END")

        XCTAssertGreaterThanOrEqual(generated, 5_850)
        XCTAssertGreaterThanOrEqual(averageRate, 48.75)
        XCTAssertLessThanOrEqual(averageRate, 51.25)
        XCTAssertGreaterThanOrEqual(deliveryRatio, 0.995)
        XCTAssertEqual(manager.droppedFrameCount, 0)
        manager.disconnect()
#endif
    }
}

#if !targetEnvironment(simulator)
private struct BLECharacteristicObservation {
    let serviceUUID: String
    let characteristicUUID: String
    let properties: [String]
}

private struct BLEGATTProfile {
    let advertisedName: String
    let maximumWriteWithoutResponse: Int
    let maximumWriteWithResponse: Int
    let characteristics: [BLECharacteristicObservation]
}

private enum BLEGATTHarnessError: LocalizedError {
    case bluetoothUnavailable(CBManagerState)
    case targetNotFound(String)
    case connectionFailed(String)
    case discoveryFailed(String)

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable(let state): return "Bluetooth unavailable in state \(state.rawValue)."
        case .targetNotFound(let name): return "Did not observe BLE peripheral \(name)."
        case .connectionFailed(let message): return "BLE connection failed: \(message)"
        case .discoveryFailed(let message): return "GATT discovery failed: \(message)"
        }
    }
}

@MainActor
private final class BLEGATTHarness: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let targetName: String
    private let completion: (Result<BLEGATTProfile, Error>) -> Void
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var advertisedName: String?
    private var pendingServiceCount = 0
    private var observations: [BLECharacteristicObservation] = []
    private var writeCharacteristic: CBCharacteristic?
    private var pendingProfile: BLEGATTProfile?
    private let writeProbe: Data?
    private var finished = false

    init(
        targetName: String,
        writeProbe: Data? = nil,
        completion: @escaping (Result<BLEGATTProfile, Error>) -> Void
    ) {
        self.targetName = targetName
        self.writeProbe = writeProbe
        self.completion = completion
        super.init()
    }

    func start() {
        central = CBCentralManager(delegate: self, queue: .main)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            guard let self, !self.finished else { return }
            self.finish(.failure(BLEGATTHarnessError.targetNotFound(self.targetName)))
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            if central.state != .unknown && central.state != .resetting {
                finish(.failure(BLEGATTHarnessError.bluetoothUnavailable(central.state)))
            }
            return
        }
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        guard name == targetName else { return }
        advertisedName = name
        self.peripheral = peripheral
        central.stopScan()
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        finish(.failure(BLEGATTHarnessError.connectionFailed(error?.localizedDescription ?? "unknown error")))
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            finish(.failure(BLEGATTHarnessError.discoveryFailed(error.localizedDescription)))
            return
        }
        let services = peripheral.services ?? []
        guard !services.isEmpty else {
            finish(.failure(BLEGATTHarnessError.discoveryFailed("no services returned")))
            return
        }
        pendingServiceCount = services.count
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            finish(.failure(BLEGATTHarnessError.discoveryFailed(error.localizedDescription)))
            return
        }
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid.uuidString == "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" {
                writeCharacteristic = characteristic
            }
            observations.append(BLECharacteristicObservation(
                serviceUUID: service.uuid.uuidString,
                characteristicUUID: characteristic.uuid.uuidString,
                properties: characteristic.properties.names
            ))
        }
        pendingServiceCount -= 1
        guard pendingServiceCount == 0 else { return }

        let profile = BLEGATTProfile(
            advertisedName: advertisedName ?? targetName,
            maximumWriteWithoutResponse: peripheral.maximumWriteValueLength(for: .withoutResponse),
            maximumWriteWithResponse: peripheral.maximumWriteValueLength(for: .withResponse),
            characteristics: observations.sorted {
                ($0.serviceUUID, $0.characteristicUUID) < ($1.serviceUUID, $1.characteristicUUID)
            }
        )
        guard let writeProbe else {
            finish(.success(profile))
            return
        }
        guard let writeCharacteristic, writeCharacteristic.properties.contains(.write) else {
            finish(.failure(BLEGATTHarnessError.discoveryFailed("verified characteristic does not support acknowledged writes")))
            return
        }
        pendingProfile = profile
        peripheral.writeValue(writeProbe, for: writeCharacteristic, type: .withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let pendingProfile else { return }
        if let error {
            finish(.failure(BLEGATTHarnessError.connectionFailed(error.localizedDescription)))
        } else {
            finish(.success(pendingProfile))
        }
    }

    private func finish(_ result: Result<BLEGATTProfile, Error>) {
        guard !finished else { return }
        finished = true
        central?.stopScan()
        if let peripheral { central?.cancelPeripheralConnection(peripheral) }
        completion(result)
    }
}

private extension CBCharacteristicProperties {
    var names: [String] {
        var result: [String] = []
        if contains(.broadcast) { result.append("broadcast") }
        if contains(.read) { result.append("read") }
        if contains(.writeWithoutResponse) { result.append("writeWithoutResponse") }
        if contains(.write) { result.append("write") }
        if contains(.notify) { result.append("notify") }
        if contains(.indicate) { result.append("indicate") }
        if contains(.authenticatedSignedWrites) { result.append("authenticatedSignedWrites") }
        if contains(.extendedProperties) { result.append("extendedProperties") }
        if contains(.notifyEncryptionRequired) { result.append("notifyEncryptionRequired") }
        if contains(.indicateEncryptionRequired) { result.append("indicateEncryptionRequired") }
        return result
    }
}
#endif
