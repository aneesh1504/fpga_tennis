import Combine
import CoreBluetooth
import Foundation

struct BLEConfiguration {
    var advertisedNamePrefix: String?
    var verifiedServiceUUID: CBUUID?
    var verifiedWriteCharacteristicUUID: CBUUID?

    static let discovery = BLEConfiguration(
        advertisedNamePrefix: nil,
        verifiedServiceUUID: nil,
        verifiedWriteCharacteristicUUID: nil
    )

    static let booleanBoard = BLEConfiguration(
        advertisedNamePrefix: "RD_BOOL_",
        verifiedServiceUUID: CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"),
        verifiedWriteCharacteristicUUID: CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    )
}

struct DiscoveredPeripheral: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rssi: Int
}

struct BLECharacteristicID: Hashable, Identifiable {
    let serviceUUID: String
    let characteristicUUID: String

    var id: String { "\(serviceUUID)/\(characteristicUUID)" }
}

struct DiscoveredWriteCharacteristic: Identifiable, Equatable {
    let id: BLECharacteristicID
    let supportsWriteWithoutResponse: Bool
    let supportsWriteWithResponse: Bool

    var label: String {
        let mode = supportsWriteWithoutResponse ? "without response" : "with response"
        return "\(id.serviceUUID) / \(id.characteristicUUID) (\(mode))"
    }
}

enum BLEConnectionState: Equatable {
    case unavailable(String)
    case idle
    case scanning
    case connecting
    case reconnecting
    case discovering
    case ready
    case disconnected(String?)
}

final class BLEManager: NSObject, ObservableObject {
    @Published private(set) var state: BLEConnectionState = .idle
    @Published private(set) var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published private(set) var writableCharacteristics: [DiscoveredWriteCharacteristic] = []
    @Published private(set) var selectedCharacteristicID: BLECharacteristicID?
    @Published private(set) var droppedFrameCount: UInt64 = 0
    @Published private(set) var completedFrameCount: UInt64 = 0
    @Published private(set) var isBackpressured = false

    var isReady: Bool { selectedCharacteristic != nil && connectedPeripheral != nil }

    private let configuration: BLEConfiguration
    private lazy var central = CBCentralManager(delegate: self, queue: .main)
    private var connectedPeripheral: CBPeripheral?
    private var characteristics: [BLECharacteristicID: CBCharacteristic] = [:]
    private var selectedCharacteristic: CBCharacteristic?
    private var selectedWriteType: CBCharacteristicWriteType = .withoutResponse
    private var waitingForWriteResponse = false
    private var frameQueue = LatestFrameQueue()
    private var lastPeripheralID: UUID?
    private var userInitiatedDisconnect = false

    init(configuration: BLEConfiguration = .booleanBoard) {
        self.configuration = configuration
        super.init()
        _ = central
    }

    func startScanning() {
        guard central.state == .poweredOn else {
            state = .unavailable("Bluetooth is not powered on.")
            return
        }
        discoveredPeripherals.removeAll()
        central.scanForPeripherals(
            withServices: configuration.verifiedServiceUUID.map { [$0] },
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        state = .scanning
    }

    func stopScanning() {
        central.stopScan()
        if state == .scanning { state = .idle }
    }

    func connect(to id: UUID) {
        guard let peripheral = central.retrievePeripherals(withIdentifiers: [id]).first else {
            state = .disconnected("Peripheral is no longer available.")
            return
        }
        central.stopScan()
        lastPeripheralID = id
        userInitiatedDisconnect = false
        connectedPeripheral = peripheral
        state = .connecting
        central.connect(peripheral)
    }

    func disconnect() {
        guard let connectedPeripheral else { return }
        userInitiatedDisconnect = true
        central.cancelPeripheralConnection(connectedPeripheral)
    }

    func selectWriteCharacteristic(_ id: BLECharacteristicID) {
        guard let characteristic = characteristics[id] else { return }
        selectedCharacteristic = characteristic
        selectedCharacteristicID = id
        selectedWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        state = .ready
        drainQueue()
    }

    func enqueue(frame: Data) {
        guard isReady else { return }
        frameQueue.enqueue(frame)
        updateQueueMetrics()
        drainQueue()
    }

    private func drainQueue() {
        guard let peripheral = connectedPeripheral, let characteristic = selectedCharacteristic else {
            updateQueueMetrics()
            return
        }

        let maximumLength = peripheral.maximumWriteValueLength(for: selectedWriteType)
        guard maximumLength > 0 else { return }

        switch selectedWriteType {
        case .withoutResponse:
            while peripheral.canSendWriteWithoutResponse,
                  let chunk = frameQueue.nextChunk(maximumLength: maximumLength) {
                peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            }
        case .withResponse:
            guard !waitingForWriteResponse,
                  let chunk = frameQueue.nextChunk(maximumLength: maximumLength) else { break }
            waitingForWriteResponse = true
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
        @unknown default:
            break
        }
        updateQueueMetrics()
    }

    private func updateQueueMetrics() {
        droppedFrameCount = frameQueue.droppedFrameCount
        completedFrameCount = frameQueue.completedFrameCount
        isBackpressured = frameQueue.isBackpressured
    }

    private func resetConnection(message: String?, allowReconnect: Bool) {
        connectedPeripheral = nil
        characteristics.removeAll()
        writableCharacteristics.removeAll()
        selectedCharacteristic = nil
        selectedCharacteristicID = nil
        waitingForWriteResponse = false
        frameQueue.removeAll()
        updateQueueMetrics()
        state = .disconnected(message)
        if allowReconnect { scheduleReconnect() }
    }

    private func scheduleReconnect() {
        guard central.state == .poweredOn,
              !userInitiatedDisconnect,
              let lastPeripheralID else { return }
        state = .reconnecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, self.state == .reconnecting else { return }
            guard let peripheral = self.central.retrievePeripherals(withIdentifiers: [lastPeripheralID]).first else {
                self.state = .disconnected("Previously connected peripheral is unavailable.")
                return
            }
            self.central.connect(peripheral)
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if case .unavailable = state { state = .idle }
        case .poweredOff: state = .unavailable("Bluetooth is powered off.")
        case .unauthorized: state = .unavailable("Bluetooth permission is not authorized.")
        case .unsupported: state = .unavailable("Bluetooth LE is unsupported on this device.")
        case .resetting: state = .unavailable("Bluetooth is resetting.")
        case .unknown: state = .unavailable("Bluetooth state is unknown.")
        @unknown default: state = .unavailable("Bluetooth entered an unknown state.")
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "Unnamed peripheral"
        if let prefix = configuration.advertisedNamePrefix, !name.hasPrefix(prefix) { return }
        let item = DiscoveredPeripheral(id: peripheral.identifier, name: name, rssi: RSSI.intValue)
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == item.id }) {
            discoveredPeripherals[index] = item
        } else {
            discoveredPeripherals.append(item)
        }
        discoveredPeripherals.sort { $0.rssi > $1.rssi }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        state = .discovering
        peripheral.discoverServices(configuration.verifiedServiceUUID.map { [$0] })
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        resetConnection(message: error?.localizedDescription ?? "Connection failed.", allowReconnect: true)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        resetConnection(message: error?.localizedDescription, allowReconnect: !userInitiatedDisconnect)
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            resetConnection(message: error.localizedDescription, allowReconnect: true)
            return
        }
        for service in peripheral.services ?? [] {
            let requested: [CBUUID]?
            if service.uuid == configuration.verifiedServiceUUID,
               let characteristic = configuration.verifiedWriteCharacteristicUUID {
                requested = [characteristic]
            } else {
                requested = nil
            }
            peripheral.discoverCharacteristics(requested, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            resetConnection(message: error.localizedDescription, allowReconnect: true)
            return
        }

        for characteristic in service.characteristics ?? [] {
            let supportsWithoutResponse = characteristic.properties.contains(.writeWithoutResponse)
            let supportsWithResponse = characteristic.properties.contains(.write)
            guard supportsWithoutResponse || supportsWithResponse else { continue }
            let id = BLECharacteristicID(
                serviceUUID: service.uuid.uuidString,
                characteristicUUID: characteristic.uuid.uuidString
            )
            characteristics[id] = characteristic
            let discovered = DiscoveredWriteCharacteristic(
                id: id,
                supportsWriteWithoutResponse: supportsWithoutResponse,
                supportsWriteWithResponse: supportsWithResponse
            )
            if !writableCharacteristics.contains(discovered) {
                writableCharacteristics.append(discovered)
            }
        }

        if let serviceUUID = configuration.verifiedServiceUUID,
           let characteristicUUID = configuration.verifiedWriteCharacteristicUUID {
            let verifiedID = BLECharacteristicID(
                serviceUUID: serviceUUID.uuidString,
                characteristicUUID: characteristicUUID.uuidString
            )
            if characteristics[verifiedID] != nil { selectWriteCharacteristic(verifiedID) }
        }

        if selectedCharacteristic == nil { state = .discovering }
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        drainQueue()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        waitingForWriteResponse = false
        if let error {
            state = .disconnected(error.localizedDescription)
            return
        }
        drainQueue()
    }
}
